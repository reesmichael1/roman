import os
import sequtils
import tables
import threadpool

import errors
import feeds
import subscriptions
import termask


proc chooseFeed(feeds: seq[Feed]): Feed {.raises: [RomanError].} =
  var displayNames = initTable[string, string]()
  for feed in feeds:
    displayNames[feed.title] = feed.formatTitle()
  try:
    let name = promptList("Select Feed", toSeq(displayNames.keys),
        displayNames = displayNames, show = 10)
    result = filter(feeds, proc(f: Feed): bool = f.title == name)[0]
  except ValueError as e:
    raise newException(RomanError, e.msg)
  except IOError as e:
    raise newException(RomanError, e.msg)


proc runMainPath() {.raises: [RomanError].} =
  let subs = getSubscriptions()
  var feed: Feed
  if subs.len == 0:
    echo "You aren't subscribed to any feeds yet! ",
      "Use --subscribe [url] to add some."
    return
  elif subs.len == 1:
    feed = getFeed(subs[0].url)
  else:
    let feedResults = map(subs, proc(s: Subscription): FlowVar[
        Feed] = spawn getFeed(s.url))
    let feeds = map(feedResults, proc(fv: FlowVar[Feed]): Feed = ^fv)
    feed = chooseFeed(feeds)

  displayFeed(feed)


proc main*(subscribeURL: string = "") {.raises: [].} =
  try:
    if subscribeURL != "":
      addSubscriptionToSubsFile(subscribeURL)
    else:
      runMainPath()
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)
