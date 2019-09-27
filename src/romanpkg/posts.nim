import browsers
import htmlparser
import options
import strtabs
import terminal
import xmltree

import FeedNim / rss
import pager

import errors
import htmlextractor
import paths
import termask

from config import conf
from types import Post


proc formatTitle*(p: Post): string {.raises: [RomanError].} =
  var width: int
  try:
    width = terminalWidth()
  except ValueError:
    raise newException(RomanError, "could not get terminal width")
  if p.read:
    result = p.title
  else:
    result = "[*] " & p.title

  if result.len > width:
    # 3 for the ellipsis, 4 for the '> ' before and after the printing,
    # 2 for padding
    result = result[0..<width-9] & "..."


proc collectReadPosts(): seq[string] {.raises: [RomanError].} =
  try:
    for line in lines(getPostReadFile()):
      result.add(line)
  except IOError:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError,
      "could not read from the read-posts file: " & msg)


proc isPostRead(itemGUID: string): bool {.raises: [RomanError].} =
  return itemGUID in collectReadPosts()


proc displayLinks(content: string) {.raises: [RomanError].} =
  var html: XmlNode
  try:
    html = parseHTML(content)
  except IOError, ValueError, Exception:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, "could not parse post HTML: " & msg)
  var links: seq[string]
  for a in html.findAll("a"):
    if a.attrs.hasKey("href"):
      links.add(a.attrs.getOrDefault("href"))

  if links.len > 0:
    try:
      let link = promptList("Select link to open in system browser", links).get
      openDefaultBrowser(link)
    except ValueError:
      discard
    except UnpackError:
      discard
    except IOError as e:
      raise newException(RomanError, "could not display links: " & e.msg)
    except Exception as e:
      raise newException(RomanError, "could not open link: " & e.msg)


proc displayPost*(p: Post) {.raises: [RomanError].} =
  try:
    var content: string
    if p.author.isSome:
      content = p.title & "\n" & p.author.unsafeGet & "\n\n" & p.rendered
    else:
      content = p.title & "\n\n" & p.rendered
    page(content, goToBottom = conf.goToBottom, goToTop = conf.goToTop,
      upOne = conf.up, downOne = conf.down, quitChar = conf.quit,
      extractLinks = conf.extractLinks, extractLinksProc = proc() {.closure,
          noSideEffect, gcsafe.} = {.noSideEffect.}: displayLinks(p.raw))
  except IOError, ValueError:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, "could not write to the terminal: " & msg)


proc postFromRSSItem*(item: RSSItem): Post {.raises: [RomanError].} =
  result.title = item.title
  result.rendered = extractBody(item.description)
  result.raw = item.description
  result.guid = item.guid
  result.read = isPostRead(item.guid)
  if item.author.len > 0:
    result.author = some(item.author)


proc markAsRead*(p: Post) {.raises: [RomanError].} =
  var f: File
  if not f.open(getPostReadFile(), mode = fmAppend):
    raise newException(RomanError, "could not open " & getPostReadFile())
  defer: f.close()

  try:
    f.writeLine(p.guid)
  except IOError:
    raise newException(RomanError,
      "could not save " & p.guid & " in the read-posts file")
