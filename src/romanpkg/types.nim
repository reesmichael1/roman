import hashes
import options


type
  RomanConfig* = object
    up*: char
    down*: char
    next*: char
    previous*: char
    quit*: char
    goToTop*: char
    goToBottom*: char
    toggleRead*: char
    postWidth*: int
    extractLinks*: char

  # Use our own Post type instead of RSSItem
  # to show metadata we collect (e.g., read/unread)
  Post* = ref object
    title*: string
    link*: string
    rendered*: string
    raw*: string
    guid*: string
    read*: bool
    author*: Option[string]

  FeedKind* = enum
    RSS = "RSS", Atom = "Atom", Unknown

  Feed* = ref object
    kind*: FeedKind
    posts*: seq[Post]
    title*: string
    unreadPosts*: int

  Subscription* = ref object
    url*: string
    name*: string
    feedKind*: FeedKind

  PostLink* = ref object
    text*: string
    url*: string

  ManageAction* = enum
    EditTitle, NoOp, Unsubscribe



proc hash*(pl: PostLink): Hash =
  result = pl.text.hash !& pl.url.hash
  result = !$result


proc hash*(sub: Subscription): Hash =
  result = sub.name.hash !& sub.url.hash !& sub.feedKind.hash
  result = !$result


proc hash*(feed: Feed): Hash =
  result = feed.kind.hash !& feed.title.hash !& feed.unreadPosts.hash
  result = !$result


proc `$`*[T](input: ref T): string = $(input[])
proc hash*[T](input: ref T): Hash = hash(input[])
