import htmlparser
import os
import streams
import strformat
import xmltree

import argparse
import feednim
import feednim / Rss


proc extractBody(body: string): string = 
  let strm = newStringStream(body)
  try: 
    let tree = htmlparser.parseHtml(strm)
    # Very simple method to just extract all of the text nodes.
    # This will be refined.
    for node in tree:
      case node.kind
      of xnText:
        result &= $node
      else:
        continue
  except:
    echo "could not parse html"
    quit(1)


proc displayFeed(feed: Rss) =  
  for item in feed.items:
    echo item.title
    let body = extractBody(item.description)
    echo body, "\n\n"


proc main(url: string) = 
  try:
    let feed = feednim.getRSS(url)
    displayFeed(feed)
  except ValueError:
    echo &"{url} is not a valid URL"
    quit(1)


proc collectArgs(): seq[string] =
  for ix in 1..paramCount():
    result.add(paramStr(ix))

  if result.len == 0:
    result = @["--help"]


when isMainModule:
  var p = newParser("roman"):
    arg("url")
    run:
      main(opts.url)

  p.run(collectArgs())
