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
    postWidth*: int
    extractLinks*: char

  # Use our own Post type instead of RSSItem
  # to show metadata we collect (e.g., read/unread)
  Post* = object
    title*: string
    link*: string
    rendered*: string
    raw*: string
    guid*: string
    read*: bool
    author*: Option[string]

  FeedKind* = enum
    RSS, Atom, Unknown

  Feed* = object
    kind*: FeedKind
    posts*: seq[Post]
    title*: string
    unreadPosts*: int

  Subscription* = object
    url*: string
    name*: string
    feedKind*: FeedKind

  PostLink* = object
    text*: string
    url*: string

  ManageAction* = enum
    NoOp, Unsubscribe
