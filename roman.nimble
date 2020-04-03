# Package

version       = "0.1.0"
author        = "Michael Rees"
description   = "A CLI RSS reader"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["roman"]
binDir        = "bin"


# Dependencies

requires "argparse >= 0.9"
requires "csvtools >= 0.2"
requires "fab >= 0.4"
requires "nim >= 0.20.0"
requires "nimpy >= 0.1"
requires "noise >= 0.1"

# We can't depend on the -d:internalRenderer flag here, 
# see https://github.com/nim-lang/nimble/issues/605
requires "https://git.sr.ht/~reesmichael1/nim-html2text >= 0.1.0"

# Use patched version of FeedNim
requires "https://git.sr.ht/~reesmichael1/feednim >= 0.2"

when defined(nimdistros):
  import distros
  foreignDep "python-html2text"
