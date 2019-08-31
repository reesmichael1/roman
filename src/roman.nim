import argparse

import romanpkg / [main, errors]


when isMainModule:
  var p = newParser("roman"):
    run:
      main()

  try:
    p.run()
  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
