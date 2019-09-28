import argparse

import romanpkg / main


proc showVersion() =
  echo "roman 0.1.0"


when isMainModule:
  var p = newParser("roman"):
    command("subscribe"):
      help("add a feed URL to the subscription list")
      option("-t", "--type",
        help = "explicitly state type of feed (accepted: \"rss\" or \"atom\")")
      arg("url", help = "the URL of the feed to subscribe to")
      run:
        echo "running subscribe"
        subscribe(opts.url, opts.type)
        quit(0)
    # I would strongly prefer to make this the main run path,
    # but argparse runs the main run path before any subcommands
    # (see https://github.com/iffy/nim-argparse/issues/27),
    # so doing so makes it impossible to subscribe to feeds.
    command("browse"):
      help("browse through subscribed feeds")
      run:
        main()
    help("a command line RSS feed reader")
    flag("-v", "--version", help = "print version information")
    run:
      if opts.version:
        showVersion()

  try:
    p.run()

  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
