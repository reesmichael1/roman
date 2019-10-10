import browsers
import htmlparser
import options
import strtabs
import strutils
import tables
import terminal
import unicode
import xmltree

import FeedNim / [atom, rss]
import pager

import errors
import htmlextractor
import paths
import termask
import types

from config import conf


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


proc extractLink(tag: XmlNode): PostLink {.raises: [].} =
  let text = tag.innerText.splitLines().join(" ")
  return PostLink(text: text, url: tag.attrs.getOrDefault("href"))


proc displayLinks(p: Post) {.raises: [RomanError].} =
  var html: XmlNode
  try:
    html = parseHTML(p.raw)
  except IOError, ValueError, Exception:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, "could not parse post HTML: " & msg)
  var links = @[PostLink(text: "Original Post", url: p.link)]

  # Some sources use a single link as the post content
  if html.tag == "a":
    links.add(extractLink(html))

  for a in html.findAll("a"):
    links.add(extractLink(a))

  proc shortenURL(url: string, text: string): string =
    # 3 for ' ()', 4 for '>   <'
    let availableWidth = terminalWidth() - text.runeLen() - 7
    if url.runeLen() > availableWidth:
      # Remove three more characters for the ellipsis
      return url[0..<(availableWidth - 3)] & "..."
    return url

  try:
    var displayNames = initTable[PostLink, string]()
    for link in links:
      if link.text.len > 0:
        displayNames[link] = link.text & " (" & shortenURL(link.url,
            link.text) & ")"
      else:
        displayNames[link] = shortenURL(link.url, "")
    # Move down one line in case we're at the END line already
    echo ""
    let link = promptList("Select link to open in system browser",
        links, displayNames = displayNames).get
    openDefaultBrowser(link.url)
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
          noSideEffect, gcsafe.} = {.noSideEffect.}: displayLinks(p))
  except IOError, ValueError:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, "could not write to the terminal: " & msg)


proc postFromAtomEntry*(entry: AtomEntry): Post {.raises: [RomanError].} =
  result.title = entry.title
  result.rendered = extractBody(entry.content)
  result.raw = entry.content
  result.guid = entry.id
  result.read = isPostRead(entry.id)
  result.link = entry.link.href
  if entry.author.name.len > 0:
    result.author = some(entry.author.name)


proc postFromRSSItem*(item: RSSItem): Post {.raises: [RomanError].} =
  result.title = item.title
  result.rendered = extractBody(item.description)
  result.raw = item.description
  result.guid = item.guid
  result.read = isPostRead(item.guid)
  result.link = item.link
  if item.author.len > 0:
    result.author = some(item.author)


proc markAsRead*(p: var Post) {.raises: [RomanError].} =
  var f: File
  if not f.open(getPostReadFile(), mode = fmAppend):
    raise newException(RomanError, "could not open " & getPostReadFile())
  defer: f.close()

  try:
    f.writeLine(p.guid)
    p.read = true
  except IOError:
    raise newException(RomanError,
      "could not save " & p.guid & " in the read-posts file")
