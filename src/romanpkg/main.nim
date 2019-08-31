import os

import errors
import feeds
import subscriptions


proc main*() {.raises: [].} =
  try:
    let subs = getSubscriptions()
    for sub in subs:
      let feed = getFeed(sub)
      displayFeed(feed)
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)
