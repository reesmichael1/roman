import htmlparser
import streams
import strformat
import terminal
import xmltree

import fab
import FeedNim
import FeedNim / rss

import errors
import subscriptions


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


proc displayFeed*(feed: Rss) {.raises: [RomanError, ValueError].} =
  try:
    under(&"{feed.title}\n", sty = {styleBright})
    for item in feed.items:
      bold(item.title)
      let body = extractBody(item.description)
      echo body, "\n\n"
  except IOError as e:
    raise newException(RomanError, &"could not write to the terminal: {e.msg}")


proc getFeed*(sub: Subscription): Rss {.raises: [ValueError, RomanError].} =
  try:
    result = FeedNim.getRSS(sub.url)
  except ValueError:
    raise newException(RomanError, &"{sub.url} is not a valid URL")
  except:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, &"error while accessing {sub.url}: {msg}")
