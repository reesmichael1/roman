import htmlparser
import os
import streams
import xmltree

import argparse
import feednim
import feednim / Rss


proc extractBody(body: string): string = 
  let strm = newStringStream(body)
  let tree = htmlparser.parseHtml(strm)
  # Very simple method to just extract all of the text nodes.
  # This will be refined.
  for node in tree:
    case node.kind
    of xnText:
      result &= $node
    else:
      continue


proc displayFeed(feed: Rss) = 
  for item in feed.items:
    echo item.title
    let body = extractBody(item.description)
    echo body, "\n\n"


proc main(url: string) = 
  let feed = feednim.getRSS(url)
  displayFeed(feed)


proc collectArgs(): seq[string] =
  for ix in 1..paramCount():
    result.add(paramStr(ix))


when isMainModule:
  var p = newParser("roman"):
    arg("url")
    run:
      main(opts.url)

  p.run(collectArgs())
