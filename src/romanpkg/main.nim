import htmlparser
import os
import streams
import strformat
import xmltree

import FeedNim
import FeedNim / rss


type RomanError* =
  object of Exception


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


proc displayFeed(feed: Rss) {.raises: [RomanError].} =
  for item in feed.items:
    echo item.title
    let body = extractBody(item.description)
    echo body, "\n\n"


proc getFeed(url: string): Rss {.raises: [ValueError, RomanError].} =
  try:
    result = FeedNim.getRSS(url)
  except ValueError:
    raise newException(RomanError, &"{url} is not a valid URL")
  except:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, &"error while accessing {url}: {msg}")


proc main*(url: string) {.raises: [].} =
  try:
    let feed = getFeed(url)
    displayFeed(feed)
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)
  # ValueError is raised by strformat if a bad format string is given to fmt,
  # so if this patch is reached, it's because of a typo in the source.
  except ValueError:
    echo "undescribable error during execution, please file a bug"
    quit(1)
