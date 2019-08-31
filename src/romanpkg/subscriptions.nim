import os

import errors

type
  Subscription* = object
    url*: string


proc getSubsFilePath(): string {.raises: [].} =
  joinPath(getConfigDir(), "roman", "subscriptions")



proc initConfigDir() {.raises: [RomanError].} =
  let configDir = joinPath(getConfigDir(), "roman")
  try:
    if not existsOrCreateDir(configDir):
      let subsFile = joinPath(configDir, "subscriptions")
      writeFile(subsFile, "")
  except OSError as e:
    raise newException(RomanError, e.msg)
  except IOError as e:
    raise newException(RomanError, e.msg)


proc readConfigFile(): seq[string] {.raises: [RomanError].} =
  let subsFilePath = getSubsFilePath()
  if not existsFile(subsFilePath):
    initConfigDir()
    return
  try:
    for line in lines(subsFilePath):
      result.add(line)
  except IOError as e:
    raise newException(RomanError, e.msg)


proc getSubscriptions*(): seq[Subscription] {.raises: [RomanError].} =
  for url in readConfigFile():
    result.add(Subscription(url: url))


proc addSubscriptionToSubsFile*(url: string) {.raises: [RomanError].} =
  var f: File
  let filename = getSubsFilePath()
  try:
    if f.open(filename, fmAppend):
      f.writeLine(url)
  except IOError as e:
    raise newException(RomanError, e.msg)
