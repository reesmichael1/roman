import os

import errors

type
  Subscription* = object
    url*: string


proc initConfigDir() {.raises: [RomanError].} =
  let configDir = joinPath(getConfigDir(), "roman")
  try:
    discard existsOrCreateDir(configDir)
    let subsFile = joinPath(configDir, "subscriptions")
    writeFile(subsFile, "")
  except OSError as e:
    raise newException(RomanError, e.msg)
  except IOError as e:
    raise newException(RomanError, e.msg)


proc readConfigFile(): seq[string] {.raises: [RomanError].} =
  let configFile = joinPath(getConfigDir(), "roman", "subscriptions")
  if not existsFile(configFile):
    initConfigDir()
    return
  try:
    for line in lines(configFile):
      result.add(line)
  except IOError as e:
    raise newException(RomanError, e.msg)


proc getSubscriptions*(): seq[Subscription] {.raises: [RomanError].} =
  for url in readConfigFile():
    result.add(Subscription(url: url))
