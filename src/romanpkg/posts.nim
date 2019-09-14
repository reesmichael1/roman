import options
import os
import strutils
import terminal

import FeedNim / rss
import pager

import errors
import htmlextractor
import paths

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


proc displayPost*(p: Post) {.raises: [RomanError].} =
  try:
    var content: string
    if p.author.isSome:
      content = p.title & "\n" & p.author.unsafeGet & "\n\n" & p.content
    else:
      content = p.title & "\n\n" & p.content
    page(content, goToBottom = conf.goToBottom, goToTop = conf.goToTop,
      upOne = conf.up, downOne = conf.down, quitChar = conf.quit)
  except IOError, ValueError:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, "could not write to the terminal: " & msg)


proc postFromRSSItem*(item: RSSItem): Post {.raises: [RomanError].} =
  result.title = item.title
  result.content = extractBody(item.description)
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
