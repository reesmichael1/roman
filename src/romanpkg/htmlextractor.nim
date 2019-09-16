import dynlib
import terminal

import nimpy

import errors

from config import conf


proc extractBody*(body: string): string {.raises: [RomanError], gcsafe.} =
  try:
    # let width = min(conf.postWidth, terminalWidth())
    # let html2text = pyImport("html2text").HTML2Text(bodywidth = width)
    # result = html2text.handle(body).to(string)
    result = body
  except:
    raise newException(RomanError, "could not use Python module html2text")
