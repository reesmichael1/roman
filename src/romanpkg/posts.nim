import os
import strutils
import terminal

import fab
import FeedNim / rss
import pager

import errors
import htmlextractor
import paths

from types import Post


proc formatTitle*(p: Post): string {.raises: [].} =
  if p.read:
    result = p.title
  else:
    result = "[*] " & p.title


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
    # Height of the content plus a line and blank line for the title
    if p.content.countLines() + 2 > terminalHeight():
      page(p.title & "\n\n" & p.content)
    else:
      bold(p.title)
      echo p.content
  except IOError, ValueError:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, "could not write to the terminal: " & msg)


proc postFromRSSItem*(item: RSSItem): Post {.raises: [RomanError].} =
  result.title = item.title
  result.content = extractBody(item.description)
  result.guid = item.guid
  result.read = isPostRead(item.guid)


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
