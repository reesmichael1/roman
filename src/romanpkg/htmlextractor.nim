import dynlib
import terminal

import nimpy

import errors


proc extractBody*(body: string): string {.raises: [RomanError].} =
  try:
    result = body
    # let html2text = pyImport("html2text").HTML2Text()
    # result = html2text.handle(body).to(string)
  except:
    raise newException(RomanError, "could not use Python module html2text")
