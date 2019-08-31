# Package

version       = "0.1.0"
author        = "Michael Rees"
description   = "A CLI RSS reader"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["roman"]
binDir        = "bin"



# Dependencies

requires "argparse >= 0.8"
requires "fab >= 0.4"
requires "feednim >= 0.2"
requires "nim >= 0.20.0"



# Tasks

task run, "Compile and run (release mode)":
    exec "nimble c -r -d:release src/roman.nim"

task debug, "Compile and run (debug mode)":
    exec "nimble c -r -d:debug src/roman.nim"
