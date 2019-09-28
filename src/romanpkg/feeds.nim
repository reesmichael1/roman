import httpclient
import options
import sequtils
import streams
import tables
import terminal
import xmlparser
import xmltree

import fab
import FeedNim / [atom, rss]

import errors
import posts
import seqreplace
import termask

from types import Feed, FeedKind, Post, Subscription


proc updateUnread*(feed: var Feed) {.raises: [].} =
  feed.unreadPosts = filter(feed.posts, proc(p: Post): bool = not p.read).len


proc detectFeedKind(content: string): FeedKind {.raises: [RomanError].} =
  var xml: XmlNode
  try:
    xml = parseXml(newStringStream(content))
  except:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, "could not parse feed: " & msg)

  # A well-formed RSS feed has an <rss> tag,
  # while a well-formed Atom feed has a <feed> tag
  let feed = xml.findAll("feed")
  let rss = xml.findAll("rss")
  if feed.len > 0 and rss.len == 0:
    return FeedKind.Atom
  if feed.len == 0 and rss.len > 0:
    return FeedKind.RSS

  # If we can't uniquely identify one or the other,
  # we'll eventually try some dirty tricks here. But for now...
  # If all else fails, ask the user to tell us which type of feed it is
  return FeedKind.Unknown


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
    var client = newHttpClient()
    let content = client.getContent(sub.url)
    var feedKind = sub.feedKind
    if feedKind == Unknown:
      feedKind = detectFeedKind(content)
    case feedKind:
    of FeedKind.RSS:
      let rawFeed = parseRSS(content)
      if sub.name.len > 0:
        result.title = sub.name
      else:
        result.title = rawFeed.title
      result.posts = map(rawFeed.items,
        proc (i: RSSItem): Post = postFromRSSItem(i))
    of FeedKind.Atom:
      let rawFeed = parseAtom(content)
      if sub.name.len > 0:
        result.title = sub.name
      else:
        result.title = rawFeed.title.text
      result.posts = map(rawFeed.entries,
        proc (e: AtomEntry): Post = postFromAtomEntry(e))
    of Unknown:
      raise newException(RomanError,
        "could not identify feed as RSS or Atom, please use --type option")
    result.kind = feedKind
    result.updateUnread()
  except ValueError:
    raise newException(RomanError, sub.url & " is not a valid URL")
  except:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError,
      "while accessing " & sub.url & ": " & msg)
