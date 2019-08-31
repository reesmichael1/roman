import os
import sequtils

import FeedNim / rss

import errors
import feeds
import subscriptions
import termask


proc runMainPath() {.raises: [RomanError].} =
  let subs = getSubscriptions()
  var feed: Rss
  if subs.len == 0:
    echo "You aren't subscribed to any feeds yet! ",
      "Use --subscribe [url] to add some."
    return
  elif subs.len == 1:
    feed = getFeed(subs[0])
  else:
    let urls = map(subs, proc(s: Subscription): string = s.url)
    try:
      let sub = promptList("Select Feed [Tab/Enter]", urls)
      feed = getFeed(Subscription(url: sub))
    except ValueError as e:
      raise newException(RomanError, e.msg)
    except IOError as e:
      raise newException(RomanError, e.msg)

  displayFeed(feed)


proc addSubscription(url: string) {.raises: [RomanError].} =
  try:
    addSubscriptionToSubsFile(url)
  except RomanError as e:
    echo "error: ", e.msg
    raise e


proc main*(subscribeURL: string = "") {.raises: [].} =
  try:
    if subscribeURL != "":
      addSubscription(subscribeURL)
    else:
      runMainPath()
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)
