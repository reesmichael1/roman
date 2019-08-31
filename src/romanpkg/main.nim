import os

import errors
import feeds
import subscriptions


proc main*() {.raises: [].} =
  try:
    let subs = getSubscriptions()
    if subs.len == 0:
      echo "You aren't subscribed to any feeds yet!"
    for sub in subs:
      let feed = getFeed(sub)
      displayFeed(feed)
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)
