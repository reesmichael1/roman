import terminal

import nimpy

import errors

from config import conf


proc extractBody*(body: string): string {.raises: [RomanError].} =
  try:
    let width = min(conf.postWidth, terminalWidth())
    let html2text = pyImport("html2text").HTML2Text(bodywidth = width)
    result = html2text.handle(body).to(string)
  except:
    raise newException(RomanError, "could not use Python module html2text")
