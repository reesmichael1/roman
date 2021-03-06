import parsecfg
import sequtils
import strutils

import errors
import paths

from types import RomanConfig

# Imported from generic function in termask, so the use isn't recognized
when defined(nimHasUsed):
  {.used.}


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


proc strToInt(config: Config, section: string, key: string): int {.
    raises: [RomanError].} =
  try:
    let s = config.getSectionValue(section, key)
    result = parseInt(s)
  except KeyError:
    raise newException(RomanError,
      "missing config value for " & section & "." & key)
  except ValueError:
    raise newException(RomanError,
      "invalid value for " & section & "." & key & ", expected int")


proc mustLoadConfig*(): RomanConfig {.raises: [].} =
  try:
    let path = getConfigFilePath()
    let dict = loadConfig(path)
    result.down = strToChar(dict, "Keyboard", "down")
    result.up = strToChar(dict, "Keyboard", "up")
    result.next = strToChar(dict, "Keyboard", "next")
    result.previous = strToChar(dict, "Keyboard", "previous")
    result.quit = strToChar(dict, "Keyboard", "quit")
    result.goToTop = strToChar(dict, "Keyboard", "top")
    result.goToBottom = strToChar(dict, "Keyboard", "bottom")
    result.toggleRead = strToChar(dict, "Keyboard", "toggle-read")
    result.allRead = strToChar(dict, "Keyboard", "mark-all-read")
    result.postWidth = strToInt(dict, "Posts", "max-width")
    result.extractLinks = strToChar(dict, "Posts", "extract-links")
  except:
    echo "error loading config file: " & getCurrentExceptionMsg()
    quit(1)


var conf* = mustLoadConfig()
