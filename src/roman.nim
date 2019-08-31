import argparse

import romanpkg / [main, errors]


when isMainModule:
  var p = newParser("roman"):
    help("a command line RSS feed reader")
    option("-s", "--subscribe", help = "a URL to add to the subscription list")
    run:
      main(subscribeURL = opts.subscribe)

  try:
    p.run()

  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
