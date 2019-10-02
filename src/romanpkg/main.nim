import options
import sequtils
import strutils
import tables

import errors
import feeds
import subscriptions
import termask

import seqreplace
from types import Feed, FeedKind, Subscription


proc chooseFeed(feeds: seq[Feed]): Feed {.raises: [RomanError,
    InterruptError].} =
  var displayNames = initTable[string, string]()
  var titles: seq[string]
  for feed in feeds:
    titles.add(feed.title)
    displayNames[feed.title] = feed.formatTitle()
  try:
    let selectedName = promptList("Select Feed", titles,
        displayNames = displayNames, show = 10)
    if selectedName.isNone:
      raise newException(InterruptError, "no feed selected")
    let name = selectedName.unsafeGet()
    result = feeds.filterIt(it.title == name)[0]
  except ValueError, IOError:
    raise newException(RomanError, getCurrentExceptionMsg())


proc runMainPath() {.raises: [RomanError, InterruptError].} =
  let subs = getSubscriptions()
  var feeds: seq[Feed]
  var feed: Feed
  if subs.len == 0:
    echo "You aren't subscribed to any feeds yet! ",
      "Use roman subscribe [url] to add some."
    return
  feeds = getFeeds(subs)

  while true:
    if feeds.len == 1:
      feed = feeds[0]
      displayFeed(feed)
    else:
      feed = chooseFeed(feeds)
      # Keep track of the originally selected feed
      # so that we can replace it with the updated unread counts later
      var oldFeed = feed
      try:
        displayFeed(feed)
      except InterruptError:
        # These errors are coming from declining to select a post
        # Instead of exiting, return to the feed selection
        try:
          feeds.replace(oldFeed, feed)
        except KeyError as e:
          raise newException(RomanError,
            "could not find feed in list of feeds: " & e.msg)
        continue


proc subscribe*(url, feedKindRaw: string) {.raises: [].} =
  try:
    var feedKind = Unknown
    if cmpIgnoreCase(feedKindRaw, "rss") == 0:
      feedKind = RSS
    elif cmpIgnoreCase(feedKindRaw, "atom") == 0:
      feedKind = Atom
    elif feedKindRaw != "":
      raise newException(RomanError, "unrecognized feed type: " & feedKindRaw)
    addSubscriptionToSubsFile(url, feedKind)
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)


proc main*() {.raises: [].} =
  try:
    runMainPath()
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)

  except InterruptError:
    quit(0)
