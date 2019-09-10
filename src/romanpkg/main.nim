import os
import options
import sequtils
import tables

import errors
import feeds
import subscriptions
import termask

from types import Feed, Subscription


proc chooseFeed(feeds: seq[Feed]): Feed {.raises: [RomanError,
    InterruptError].} =
  var displayNames = initTable[string, string]()
  for feed in feeds:
    displayNames[feed.title] = feed.formatTitle()
  try:
    let selectedName = promptList("Select Feed", toSeq(displayNames.keys),
        displayNames = displayNames, show = 10)
    if selectedName.isNone:
      raise newException(InterruptError, "no feed selected")
    let name = selectedName.unsafeGet()
    result = filter(feeds, proc(f: Feed): bool = f.title == name)[0]
  except ValueError as e:
    raise newException(RomanError, e.msg)
  except IOError as e:
    raise newException(RomanError, e.msg)


proc runMainPath() {.raises: [RomanError, InterruptError].} =
  let subs = getSubscriptions()
  var feeds: seq[Feed]
  var feed: Feed
  if subs.len == 0:
    echo "You aren't subscribed to any feeds yet! ",
      "Use --subscribe [url] to add some."
    return
  elif subs.len == 1:
    feed = getFeed(subs[0])
    feeds = @[feed]
  else:
    feeds = map(subs, getFeed)

  while true:
    if feeds.len == 1:
      displayFeed(feed)
    else:
      feed = chooseFeed(feeds)
      try:
        displayFeed(feed)
      except InterruptError:
        # These errors are coming from declining to select a post
        # Instead of exiting, return to the feed selection
        continue


proc main*(subscribeURL: string = "") {.raises: [].} =
  try:
    if subscribeURL != "":
      addSubscriptionToSubsFile(subscribeURL)
    else:
      runMainPath()
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)

  except InterruptError:
    quit(0)
