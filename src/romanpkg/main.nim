import os
import strformat

import errors
import feeds


proc main*(url: string) {.raises: [].} =
  try:
    let feed = getFeed(url)
    displayFeed(feed)
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)
  # ValueError is raised by strformat if a bad format string is given to fmt,
  # so if this patch is reached, it's because of a typo in the source.
  except ValueError:
    echo "undescribable error during execution, please file a bug"
    quit(1)
