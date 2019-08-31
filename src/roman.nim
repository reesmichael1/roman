import os

import argparse

import romanpkg / [main, errors]


proc collectArgs(): seq[string] {.raises: [RomanError].} =
  try:
    for ix in 1..paramCount():
      result.add(paramStr(ix))

    if result.len == 0:
      result = @["--help"]
  except IndexError:
    # This really should not happen
    raise newException(RomanError,
      "index error in arg parsing, please file a bug")


when isMainModule:
  var p = newParser("roman"):
    arg("url", help = "url of the feed to show posts from")
    run:
      main(opts.url)

  try:
    p.run(collectArgs())
  except UsageError:
    let msg = getCurrentExceptionMsg()
    echo msg
