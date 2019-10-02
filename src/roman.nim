import argparse

import romanpkg / main


proc showVersion() =
  echo "roman 0.1.0"


when isMainModule:
  var p = newParser("roman"):
    help("a command line RSS feed reader")
    flag("-v", "--version", help = "print version information")
    command("subscribe"):
      help("add a feed URL to the subscription list")
      option("-t", "--type",
        help = "explicitly state type of feed (accepted: \"rss\" or \"atom\")")
      arg("url", help = "the URL of the feed to subscribe to")
      run:
        subscribe(opts.url, opts.type)
    run:
      if opts.version:
        showVersion()
      if opts.argparseCommand == "":
        main()

  try:
    p.run()

  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
