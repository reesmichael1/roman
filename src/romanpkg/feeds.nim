import options
import sequtils
import tables
import terminal

import fab
import FeedNim
import FeedNim / rss

import errors
import posts
import seqreplace
import termask

from types import Feed, Post, Subscription


proc updateUnread*(feed: var Feed) {.raises: [].} =
  feed.unreadPosts = filter(feed.posts, proc(p: Post): bool = not p.read).len


# Show the number of unread posts in the feed display
proc formatTitle*(feed: Feed): string {.raises: [].} =
  feed.title & " [" & $feed.unreadPosts & "/" & $feed.posts.len & "]"


proc displayFeed*(feed: var Feed) {.raises: [RomanError, InterruptError].} =
  try:
    under(feed.title & "\n", sty = {styleBright})

    var display = initTable[string, string]()
    var titles: seq[string]

    while true:
      display = initTable[string, string]()
      titles = @[]
      for p in feed.posts:
        display[p.title] = p.formatTitle()
        titles.add(p.title)
      let selectedTitle = promptList("Select Post", titles, show = 10,
          displayNames = display)
      if selectedTitle.isNone():
        raise newException(InterruptError, "no post selected")
      let title = selectedTitle.unsafeGet()
      var post = filter(feed.posts, proc(p: Post): bool = p.title == title)[0]
      displayPost(post)

      # Replace the copy of the post in feed.posts
      # with one that is marked as read
      let oldPost = post
      post.markAsRead()
      feed.posts.replace(oldPost, post)
      feed.updateUnread()
  except IOError as e:
    raise newException(RomanError, "could not write to the terminal: " & e.msg)
  except ValueError as e:
    raise newException(RomanError, "could not set terminal style: " & e.msg)


proc getFeed*(sub: Subscription): Feed {.raises: [RomanError].} =
  try:
    let rssFeed = FeedNim.getRSS(sub.url)
    if sub.name.len > 0:
      result.title = sub.name
    else:
      result.title = rssFeed.title
    result.posts = map(rssFeed.items,
      proc (i: RSSItem): Post = postFromRSSItem(i))
    result.updateUnread()
  except ValueError:
    raise newException(RomanError, sub.url & " is not a valid URL")
  except:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError,
      "error while accessing " & sub.url & ": " & msg)
