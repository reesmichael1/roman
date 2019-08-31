import os

import errors

type
  Subscription* = object
    url*: string


proc readConfigFile(): seq[string] {.raises: [RomanError].} =
  let configFile = joinPath(getConfigDir(), "roman", "subscriptions")
  try:
    for line in lines(configFile):
      result.add(line)
  except IOError as e:
    raise newException(RomanError, e.msg)


proc getSubscriptions*(): seq[Subscription] {.raises: [RomanError].} =
  for url in readConfigFile():
    result.add(Subscription(url: url))
