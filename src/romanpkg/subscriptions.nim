import algorithm
import os
import sequtils
import strutils

import csvtools

import errors
import feeds
import paths
import termask

from types import FeedKind, Subscription


proc newSubscription*(name, url: string, kind: FeedKind): Subscription {.
    raises: [].} =
  Subscription(name: name, url: url, feedKind: kind)


proc isComment(line: string): bool =
  line.strip().startsWith("#")


proc getSubscriptions*(): seq[Subscription] {.raises: [RomanError].} =
  let subsFilePath = getSubsFilePath()
  if not existsFile(subsFilePath):
    initConfigDir()
    return
  try:
    for row in csvRows(subsFilePath):
      if row[0].isComment(): continue
      if row.len != 3:
        raise newException(RomanError,
          "bad line in subscriptions file: " & $row)

      let kind = parseEnum[FeedKind](row[2])
      result.add(newSubscription(row[0], row[1], kind))

    result.sort(proc(a, b: Subscription): int = cmpIgnoreCase(a.name, b.name))
  except:
    raise newException(RomanError, getCurrentExceptionMsg())


proc getFeedKindString(kind: FeedKind): string {.raises: [RomanError].} =
  case kind
  of Unknown:
    raise newException(RomanError, "unknown feed type")
  else:
    return toLowerAscii(repr(kind))


proc subscriptionToLine(sub: Subscription): string {.raises: [RomanError].} =
  result = connect(@[sub.name, sub.url, getFeedKindString(sub.feedKind)],
    quoteAlways = true)


proc addFullSubscriptionToSubsFile(subscription: Subscription) {.raises: [RomanError].} =
  try:
    let subs = getSubscriptions()
    let sameURLSubs = subs.filterIt(it.url == subscription.url)
    if sameURLSubs.len > 0:
      raise newException(RomanError,
        "you are already subscribed to " & subscription.url & "!")
    var f: File
    let filename = getSubsFilePath()
    if f.open(filename, fmAppend):
      defer: f.close()
      f.write(subscriptionToLine(subscription))
  except IOError as e:
    raise newException(RomanError, e.msg)


proc addSubscriptionToSubsFile*(url: string, feedKind: FeedKind) {.
    raises: [RomanError].} =
  let feed = getFeed(newSubscription("", url, feedKind))
  let subscription = newSubscription(feed.title, url, feed.kind)
  addFullSubscriptionToSubsFile(subscription)


proc subscriptionFromLine(line: string): Subscription {.raises: [RomanError].} =
  result = new(Subscription)
  let fields = try:
    line.split(",").mapIt(unescape(it))
  except ValueError:
    raise newException(RomanError,
      "unescaped line in subscriptions file" & line)
  if fields.len != 3:
    raise newException(RomanError,
      "invalid line in subscriptions file: " & line)
  case fields[2]
  of "rss": result.feedKind = FeedKind.RSS
  of "atom": result.feedKind = FeedKind.Atom
  else: raise newException(RomanError, "invalid feed type: " & fields[2])
  result.name = fields[0]
  result.url = fields[1]


proc removeSubscriptionFromSubsFile*(sub: Subscription) {.
    raises: [RomanError].} =
  try:
    let filename = getSubsFilePath()
    let content = filename.readFile()
    let subsLines = content.splitLines()

    # TODO: make a backup of the contents to write in the event of an exception
    var f: File
    if f.open(filename, fmWrite):
      defer: f.close()
      for line in subsLines:
        if not line.isComment() and line.len > 0:
          let s = subscriptionFromLine(line)
          if s[] != sub[]:
            f.writeLine(line)
  except IOError as e:
    raise newException(RomanError,
      "could not open subscriptions file: " & e.msg)


proc editSubscriptionTitle*(sub: Subscription) {.raises: [RomanError].} =
  let newName = askUserForInput("Enter new name (empty to go back): ", sub.name)
  if newName == "":
    return
  let newSub = newSubscription(newName, sub.url, sub.feedKind)
  removeSubscriptionFromSubsFile(sub)
  addFullSubscriptionToSubsFile(newSub)
