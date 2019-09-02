import htmlparser
import streams
import xmltree

import FeedNim / rss

import errors


type
  # Use our own Post type instead of RSSItem
  # to show metadata we collect (e.g., read/unread)
  Post* = object
    title*: string
    content*: string


proc extractBody(body: string): string {.raises: [RomanError].} =
  let strm = newStringStream(body)
  try:
    let tree = htmlparser.parseHtml(strm)
    # Very simple method to just extract all of the text nodes.
    # This will be refined.
    for node in tree:
      case node.kind
      of xnText:
        result &= $node
      else:
        continue
  except:
    raise newException(RomanError, "could not parse html")


proc postFromRSSItem*(item: RSSItem): Post {.raises: [RomanError].} =
  result.title = item.title
  result.content = extractBody(item.description)
