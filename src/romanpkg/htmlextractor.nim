import terminal

import errors
when defined(internalRenderer):
  import html2text
else:
  import nimpy


from config import conf


proc extractBody*(body: string): string {.raises: [RomanError].} =
  let width = try:
    min(conf.postWidth, terminalWidth())
  except:
    raise newException(RomanError, "could not get terminal width")
  try:
    when defined(internalRenderer):
      # Use nim-html2text if -d:internalRenderer is passed
      return handle(body, maxWidth = width)

    else:
      # Otherwise, use the Python version (which needs to be installed)
      let html2text = pyImport("html2text").HTML2Text(bodywidth = width)
      return html2text.handle(body).to(string)
  except:
    raise newException(RomanError, "error rendering HTML to text: " &
      getCurrentExceptionMsg())
