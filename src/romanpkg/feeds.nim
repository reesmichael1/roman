import sequtils
import terminal

import fab
import FeedNim
import FeedNim / rss

import errors
import posts
import termask


type
  Feed* = object
    posts*: seq[Post]
    title*: string


proc displayFeed*(feed: Feed) {.raises: [RomanError].} =
  try:
    under(feed.title & "\n", sty = {styleBright})
    let titles = map(feed.posts, proc(p: Post): string = p.title)
    let title = promptList("Select Post", titles, show = 10)
    let post = filter(feed.posts, proc(p: Post): bool = p.title == title)[0]
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
      proc (i: RSSItem): Post = postFromRSSItem(i))
  except ValueError:
    raise newException(RomanError, url & " is not a valid URL")
  except:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError,
      "error while accessing " & url & ": " & msg)
