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

  Subscription* = object
    url*: string
    name*: string

  # Use our own Post type instead of RSSItem
  # to show metadata we collect (e.g., read/unread)
  Post* = object
    title*: string
    rendered*: string
    raw*: string
    guid*: string
    read*: bool
    author*: Option[string]

  Feed* = object
    posts*: seq[Post]
    title*: string
    unreadPosts*: int

  PostLink* = object
    text*: string
    url*: string