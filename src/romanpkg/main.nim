import os

import errors
import feeds
import subscriptions


proc runMainPath() {.raises: [RomanError].} =
  let subs = getSubscriptions()
  if subs.len == 0:
    echo "You aren't subscribed to any feeds yet!"
  for sub in subs:
    let feed = getFeed(sub)
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
