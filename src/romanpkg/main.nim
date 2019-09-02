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
    feed = getFeed(subs[0].url)
  else:
    let feedNames = map(subs, proc(s: Subscription): string = s.name)
    try:
      let name = promptList("Select Feed [Tab/Enter]", feedNames)
      let url = filter(subs,
        proc(s: Subscription): bool = s.name == name)[0].url
      feed = getFeed(url)
    except ValueError as e:
      raise newException(RomanError, e.msg)
    except IOError as e:
      raise newException(RomanError, e.msg)

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
