import os

import FeedNim / rss

import errors
import htmlextractor
import paths


type
  # Use our own Post type instead of RSSItem
  # to show metadata we collect (e.g., read/unread)
  Post* = object
    title*: string
    content*: string
    guid*: string
    read*: bool


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


proc postFromRSSItem*(item: RSSItem): Post {.raises: [
    RomanError].} =
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
