import algorithm
import os
import parsecsv
import strutils

import errors
import feeds
import paths

from types import FeedKind, Subscription


proc getSubscriptions*(): seq[Subscription] {.raises: [RomanError].} =
  let subsFilePath = getSubsFilePath()
  if not existsFile(subsFilePath):
    initConfigDir()
    return
  try:
    var p: CsvParser
    p.open(subsFilePath)
    while p.readRow():
      if p.row.len > 0 and p.row[0].len > 0:
        if p.row[0][0] == '#':
          continue
      if p.row.len != 3:
        raise newException(RomanError,
          "bad line in subscriptions file: " & $p.row)
      var kind: FeedKind
      case p.row[2]:
        of "rss":
          kind = RSS
        of "atom":
          kind = Atom
        else:
          raise newException(RomanError,
            "unrecognized type field in subscriptions file: " & p.row[2])

      result.add(Subscription(name: p.row[0], url: p.row[1], feedKind: kind))

    result.sort(proc(a, b: Subscription): int = cmpIgnoreCase(a.name, b.name))
  except:
    raise newException(RomanError, getCurrentExceptionMsg())


proc addSubscriptionToSubsFile*(url: string, feedKind: FeedKind) {.
    raises: [RomanError].} =
  try:
    let feed = getFeed(Subscription(url: url, feedKind: feedKind))
    let subscription = Subscription(name: feed.title, url: url,
        feedKind: feed.kind)
    let subs = getSubscriptions()
    if subscription in subs:
      raise newException(RomanError,
        "you are already subscribed to " & url & "!")
    var kind: string
    case subscription.feedKind:
    of RSS:
      kind = "rss"
    of Atom:
      kind = "atom"
    of Unknown:
      raise newException(RomanError,
        "trying to save subscription without knowing feed type")
    var f: File
    let filename = getSubsFilePath()
    if f.open(filename, fmAppend):
      f.writeLine(feed.title & "," & url & "," & kind)
  except IOError as e:
    raise newException(RomanError, e.msg)
