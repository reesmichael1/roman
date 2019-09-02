import os
import parsecsv

import errors
import feeds

type
  Subscription* = object
    url*: string
    name*: string


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


proc getSubscriptions*(): seq[Subscription] {.raises: [RomanError].} =
  let subsFilePath = getSubsFilePath()
  if not existsFile(subsFilePath):
    initConfigDir()
    return
  try:
    var p: CsvParser
    p.open(subsFilePath)
    while p.readRow():
      if p.row.len != 2:
        raise newException(RomanError,
          "bad line in subscriptions file: " & $p.row)
      result.add(Subscription(name: p.row[0], url: p.row[1]))
  except:
    raise newException(RomanError, getCurrentExceptionMsg())


proc addSubscriptionToSubsFile*(url: string) {.raises: [RomanError].} =
  try:
    let feed = getFeed(url)
    let subscription = Subscription(name: feed.title, url: url)
    let subs = getSubscriptions()
    if subscription in subs:
      raise newException(RomanError,
        "you are already subscribed to " & url & "!")
    var f: File
    let filename = getSubsFilePath()
    if f.open(filename, fmAppend):
      f.writeLine(feed.title & "," & url)
  except IOError as e:
    raise newException(RomanError, e.msg)
