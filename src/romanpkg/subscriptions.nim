import os
import strformat

import errors

type
  Subscription* = object
    url*: string


proc readConfigFile(): seq[string] {.raises: [RomanError, ValueError].} =
  let configFile = joinPath(getConfigDir(), "roman", "subscriptions")
  try:
    for line in lines(configFile):
      result.add(line)
  except IOError as e:
    raise newException(RomanError,
      &"could not read config file at {configFile}: {e.msg}")


proc getSubscriptions*(): seq[Subscription] {.raises: [RomanError,
    ValueError].} =
  for url in readConfigFile():
    result.add(Subscription(url: url))
