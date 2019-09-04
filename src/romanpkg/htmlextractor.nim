import dynlib
import terminal

import errors


const MAX_WIDTH = 80


type
  fromCStringFunction = proc(body: cstring, width: int): cstring {.
    gcsafe, stdcall.}


proc extractBody*(body: string): string {.raises: [RomanError].} =
  let lib = loadLib("libhtml2text.so")
  if lib == nil:
    raise newException(RomanError, "could not load html2text library")

  let extractor = cast[fromCStringFunction](lib.symAddr("from_cstring"))
  if extractor == nil:
    unloadLib(lib)
    raise newException(RomanError, "could not load html2text.from_cstring")

  try:
    result = $extractor(body, min(terminalWidth(), MAX_WIDTH))
  except:
    unloadLib(lib)
    let msg = getCurrentExceptionMsg()
    raise newException(RomanError,
      "exception in html2text.from_cstring: " & msg)

  unloadLib(lib)
