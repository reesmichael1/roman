import parsecfg
import sequtils

import errors
import paths

from types import RomanConfig


proc strToChar(config: Config, section: string, key: string): char {.
    raises: [RomanError].} =
  try:
    let s = config.getSectionValue(section, key)
    if s.len != 1:
      raise newException(RomanError, "expected single char for " & section &
          "." & key & ", got '" & s & "'")
    return toSeq(s.items)[0]
  except KeyError:
    raise newException(RomanError,
      "missing config value for " & section & "." & key)


proc mustLoadConfig*(): RomanConfig {.raises: [].} =
  try:
    let path = getConfigFilePath()
    let dict = loadConfig(path)
    result.down = strToChar(dict, "Keyboard", "down")
    result.up = strToChar(dict, "Keyboard", "up")
    result.next = strToChar(dict, "Keyboard", "next")
    result.previous = strToChar(dict, "Keyboard", "previous")
    result.quit = strToChar(dict, "Keyboard", "quit")
  except:
    echo "error loading config file: " & getCurrentExceptionMsg()
    quit(1)


var conf* = mustLoadConfig()
