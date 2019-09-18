import argparse

import romanpkg / main


proc showVersion() =
  echo "roman 0.1.0"


when isMainModule:
  var p = newParser("roman"):
    help("a command line RSS feed reader")
    option("-s", "--subscribe", help = "a URL to add to the subscription list")
    flag("-v", "--version", help = "print version information")
    run:
      if opts.version:
        showVersion()
      else:
        main(subscribeURL = opts.subscribe)

  try:
    p.run()

  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
