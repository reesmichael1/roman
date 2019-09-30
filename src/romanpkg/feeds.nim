import httpclient
import options
import sequtils
import streams
import strutils
import tables
import terminal
import uri
import xmlparser
import xmltree

import fab
import FeedNim / [atom, rss]

import errors
import posts
import seqreplace
import termask

from types import Feed, FeedKind, Post, Subscription


let atomNames = ["index.atom", "feed.atom", "atom.xml"]
let rssNames = ["index.rss", "feed.rss", "rss.xml"]


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

  return FeedKind.Unknown


proc guessFeedKind(url: string): FeedKind {.raises: [].} =
  # If we can't uniquely identify one or the other, try some dirty tricks here.
  # If all else fails, return FeedKind.Unknown again, which will
  # ask the user to tell us which type of feed it is.
  let parsed = parseURI(url)

  if atomNames.anyIt(parsed.path.contains(it)):
    return FeedKind.Atom
  elif rssNames.anyIt(parsed.path.contains(it)):
    return FeedKind.RSS

  if parsed.path.len > 3 and parsed.path[
      parsed.path.len-3..parsed.path.high] == "rss":
    return FeedKind.RSS

  if parsed.path.len > 4 and parsed.path[
      parsed.path.len-4..parsed.path.high] == "atom":
    return FeedKind.Atom

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
    if feedKind == Unknown:
      feedKind = guessFeedKind(sub.url)
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
