import sequtils
import terminal

import fab
import FeedNim
import FeedNim / rss

import errors
import posts


type
  Feed* = object
    posts*: seq[Post]
    title*: string


proc displayFeed*(feed: Feed) {.raises: [RomanError].} =
  try:
    under(feed.title & "\n", sty = {styleBright})
    echo feed.title & "\n"
    for post in feed.posts:
      bold(post.title)
      echo post.content, "\n\n"
  except IOError as e:
    raise newException(RomanError, "could not write to the terminal: " & e.msg)
  except ValueError as e:
    raise newException(RomanError, "could not set terminal style: " & e.msg)


proc getFeed*(url: string): Feed {.raises: [RomanError].} =
  try:
    let rssFeed = FeedNim.getRSS(url)
    result.title = rssFeed.title
    result.posts = map(rssFeed.items,
      proc (i: RSSITem): Post = postFromRSSItem(i))
  except ValueError:
    raise newException(RomanError, url & " is not a valid URL")
  except:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError,
      "error while accessing " & url & ": " & msg)
