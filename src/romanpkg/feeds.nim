when defined(internalRenderer):
  {.experimental: "parallel".}
  import threadpool

import asyncdispatch
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
import termask
import types

from config import conf


const atomNames = ["index.atom", "feed.atom", "atom.xml"]
const rssNames = ["index.rss", "feed.rss", "rss.xml"]


proc updateUnread*(feed: Feed) {.raises: [].} =
  feed.unreadPosts = feed.posts.filterIt(not it.read).len


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


proc displayFeed*(feed: Feed) {.raises: [RomanError, InterruptError].} =
  try:
    under(feed.title & "\n", sty = {styleBright})

    var display = initTable[ref string, ref string]()
    var titles: seq[ref string]

    proc toggleRead(posts: seq[Post]): proc(index: int) {.closure, gcSafe.} =
      return proc(index: int) {.closure, gcSafe.} =
        var post = posts[index]
        post.toggleRead()
        titles[index][] = post.formatTitle()
        display[titles[index]] = titles[index]

    proc markAllRead(posts: seq[Post]): proc(index: int) {.closure, gcSafe.} =
      return proc(index: int) {.closure, gcSafe.} =
        stdout.write("Really mark all posts as read? [y/n] ")
        defer: stdout.eraseLine()
        while true:
          showCursor(stdout)
          let confirm = getch()
          hideCursor(stdout)
          if confirm == 'n':
            return
          elif confirm == 'y':
            break
          else:
            stdout.eraseLine()
            stdout.write("Invalid input, please enter 'y' or 'n': ")
            continue
        for ix in 0..posts.high:
          var post = posts[ix]
          post.markAsRead()
          titles[ix][] = post.formatTitle()
          display[titles[ix]] = titles[ix]

    var callbacks = newTable[char, proc(index: int) {.closure, gcSafe.}]()
    callbacks[conf.toggleRead] = toggleRead(feed.posts)
    callbacks[conf.allRead] = markAllRead(feed.posts)

    while true:
      display = initTable[ref string, ref string]()
      titles = @[]
      for p in feed.posts:
        var title = new string
        title[] = p.title
        var formatted = new string
        formatted[] = p.formatTitle()
        titles.add(title)
        display[title] = formatted
      let selectedTitle = promptList[ref string, ref string]("Select Post",
          titles, show = 10, displayNames = display, callbacks = callbacks)
      if selectedTitle.isNone():
        raise newException(InterruptError, "no post selected")
      let title = selectedTitle.unsafeGet()
      var post = feed.posts.filterIt(it.title == title[])[0]
      displayPost(post)
      post.markAsRead()

  except IOError as e:
    raise newException(RomanError, "could not write to the terminal: " & e.msg)
  except ValueError as e:
    raise newException(RomanError, "could not set terminal style: " & e.msg)
  except InterruptError as e:
    # Update the read/unread counts in the feed
    # before returning to feed selection
    feed.updateUnread()
    raise newException(InterruptError, e.msg)
  except Exception as e:
    raise newException(RomanError, "error loading callbacks table: " & e.msg)


proc buildFeedFromContentAndSub(content: string, sub: Subscription): Feed {.
    raises: [RomanError].} =
  result = new(Feed)
  try:
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
      result.posts = rawFeed.items.mapIt(postFromRSSItem(it))
    of FeedKind.Atom:
      let rawFeed = parseAtom(content)
      if sub.name.len > 0:
        result.title = sub.name
      else:
        result.title = rawFeed.title.text
      result.posts = rawFeed.entries.mapIt(postFromAtomEntry(it))
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


proc getFeed*(sub: Subscription): Feed {.raises: [RomanError].} =
  try:
    var client = newHttpClient()
    let content = client.getContent(sub.url)
    result = buildFeedFromContentAndSub(content, sub)
  except Exception as e:
    raise newException(RomanError, e.msg)


proc asyncFeedsLoader(subs: seq[Subscription]): Future[seq[string]] {.async.} =
  var futures = newSeq[Future[string]](subs.len)
  result = newSeq[string](subs.len)
  for ix, sub in subs:
    var client = newAsyncHttpClient()
    futures[ix] = client.getContent(sub.url)

  result = await all(futures)


proc getFeeds*(subs: seq[Subscription]): seq[Feed] {.raises: [RomanError].} =
  result = newSeq[Feed](subs.len)
  try:
    var contents = waitFor asyncFeedsLoader(subs)
    when defined(internalRenderer):
      var responses = newSeq[FlowVar[Feed]](subs.len)
      parallel:
        for ix, content in contents:
          responses[ix] = spawn buildFeedFromContentAndSub(content, subs[ix])

      sync()
      for ix, response in responses:
        result[ix] = ^response

    else:
      for ix, content in contents:
        result[ix] = buildFeedFromContentAndSub(content, subs[ix])

  except:
    raise newException(RomanError, "error in loading feeds: " &
        getCurrentExceptionMsg())
