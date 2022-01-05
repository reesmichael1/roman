import options
import strutils
import tables

import errors
import feeds
import subscriptions
import termask

import types


proc chooseSubscription(subs: seq[Subscription]): Subscription {.raises: [
    RomanError, InterruptError].} =
  var displayNames = initTable[Subscription, string]()
  for sub in subs:
    # TODO: wrap width if necessary
    displayNames[sub] = sub.name & " (" & sub.url & ")"
  try:
    let selectedName = promptList("Select Subscription", subs,
        displayNames = displayNames, show = 10)
    if selectedName.isNone:
      raise newException(InterruptError, "no subscription selected")
    result = selectedName.unsafeGet()
  except ValueError, IOError:
    raise newException(RomanError, getCurrentExceptionMsg())


proc chooseFeed(feeds: seq[Feed]): Feed {.raises: [RomanError,
    InterruptError].} =
  var displayNames = initTable[Feed, string]()
  for feed in feeds:
    displayNames[feed] = feed.formatTitle()
  try:
    let selectedName = promptList("Select Feed", feeds,
        displayNames = displayNames, show = 10)
    if selectedName.isNone:
      raise newException(InterruptError, "no feed selected")
    result = selectedName.unsafeGet()
  except ValueError, IOError:
    raise newException(RomanError, getCurrentExceptionMsg())


proc chooseManageAction(): ManageAction {.raises: [RomanError].} =
  # TODO: implement more actions
  try:
    var displayNames = {
      EditTitle: "edit title",
      NoOp: "do nothing",
      Unsubscribe: "unsubscribe"
    }.toTable
    let action = promptList("Choose operation", [EditTitle, Unsubscribe, NoOp], displayNames)
    if action.isNone:
      return NoOp
    return action.unsafeGet()
  except InterruptError:
    return NoOp
  except ValueError, IOError:
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError, "error when choosing operation: " & msg)


const NOT_SUBSCRIBED_MSG = "You aren't subscribed to any feeds yet! " &
  "Use roman subscribe [url] to add some."



proc runMainPath() {.raises: [RomanError, InterruptError].} =
  let subs = getSubscriptions()
  var feeds: seq[Feed]
  if subs.len == 0:
    echo NOT_SUBSCRIBED_MSG
    return
  feeds = getFeeds(subs)

  while true:
    if feeds.len == 1:
      let feed = feeds[0]
      displayFeed(feed)
    else:
      let feed = chooseFeed(feeds)
      try:
        displayFeed(feed)
      except InterruptError:
        # This error comes from declining to select a post
        # Instead of exiting, return to the feed selection
        continue


proc subscribe*(url, feedKindRaw: string) {.raises: [].} =
  try:
    var feedKind = Unknown
    if cmpIgnoreCase(feedKindRaw, "rss") == 0:
      feedKind = RSS
    elif cmpIgnoreCase(feedKindRaw, "atom") == 0:
      feedKind = Atom
    elif feedKindRaw != "":
      raise newException(RomanError, "unrecognized feed type: " & feedKindRaw)
    addSubscriptionToSubsFile(url, feedKind)
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)


proc manage*() {.raises: [].} =
  while true:
    try:
      let subs = getSubscriptions()
      var sub: Subscription
      if subs.len == 0:
        echo NOT_SUBSCRIBED_MSG
        return
      elif subs.len == 1:
        sub = subs[0]
      else:
        sub = chooseSubscription(subs)
      let action = chooseManageAction()
      case action
      of NoOp:
        discard
      of EditTitle:
        editSubscriptionTitle(sub)
      of Unsubscribe:
        removeSubscriptionFromSubsFile(sub)
    except InterruptError:
      quit(0)
    except RomanError as e:
      echo "error: ", e.msg
      quit(1)


proc main*() {.raises: [].} =
  try:
    runMainPath()
  except RomanError as e:
    echo "error: ", e.msg
    quit(1)

  except InterruptError:
    quit(0)
