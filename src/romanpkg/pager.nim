import std/wordwrap
import strutils
import terminal


proc displayLines(allLines: seq[string], ix: int) =
  eraseScreen(stdout)

  # Subtract 1 to account for the blank line at the bottom
  let height = terminalHeight() - 1

  # max with 0 to avoid negative index if content is longer than screen height
  let startIx = max(0, min(ix, allLines.len - height))
  let stopIx = min(startIx + height, allLines.len) - 1

  # If the content is shorter than the screen is tall, push it to the bottom
  var cursorY = 0
  if allLines.len < height:
    cursorY = height - allLines.len
  setCursorPos(0, cursorY)

  let linesToShow = allLines[startIx..stopIx]
  for line in linesToShow:
    stdout.write line
    cursorDown(stdout, 1)
    cursorBackward(stdout, line.len)

  # If we're at the bottom, let the user know
  if stopIx == allLines.len - 1:
    cursorDown(stdout, 1)
    setBackgroundColor(bgWhite)
    setForegroundColor(fgBlack)
    stdout.write "(END) "
    setBackgroundColor(bgDefault)
    setForegroundColor(fgDefault)


proc wrapLines(contents: string, width: int): seq[string] =
  # wrapWords doesn't handle newlines that are already in the text well,
  # so we split the contents into chunks, wrap the chunks, and then join them
  let width = terminalWidth()
  for line in contents.splitLines():
    if line.len > 0:
      result.add(splitLines(wrapWords(line, maxLineWidth = width)))
    else:
      result.add(line)

  # Get rid of any empty lines on the end of the string
  while result[result.len-1].len == 0:
    discard pop(result)



proc page*(contents: string, goToBottom = 'G', goToTop = 'g', upOne = 'k',
    quitChar = 'q', downOne = 'j', upHalf = chr(21), downHalf = chr(4)) =
  hideCursor(stdout)
  # lineIx is the index of the *top* line that should be shown
  var lineIx = 0

  # Store some variables on the status to avoid needless redraws
  var needsPaint = true
  var oldIx = lineIx
  var width = 0
  var wrappedLines: seq[string]

  # Show the appropriate chunk of lines until told to stop
  while true:
    # Calculate the height in each loop in case the terminal has been resized
    # Subtract 1 to account for the blank line at the bottom
    # Re-wrap the words each time for the same reason
    let height = terminalHeight() - 1
    let stepSize = int(height / 2)
    if width != terminalWidth():
      wrappedLines = wrapLines(contents, width)
      needsPaint = true

    if oldIx != lineIx:
      needsPaint = true

    if needsPaint:
      displayLines(wrappedLines, lineIx)
      needsPaint = false
    # Use ifs instead of case because case requires known values at comptime
    let c = getch()
    if c == downOne: # scroll down
      lineIx = min(lineIx + 1, wrappedLines.len - height)
    elif c == upOne: # scroll up
      if lineIx >= 1: # but only if not already at the top
        lineIx -= 1
    elif c == goToBottom: # go to the last line
      lineIx = max(0, wrappedLines.len - height)
    elif c == goToTop: # go back to the start
      lineIx = 0
    elif c == upHalf: # Ctrl-U: go up one half-screen's worth
      lineIx = max(0, lineIx - stepSize)
    elif c == downHalf: # Ctrl-D: go down one half-screen's worth
      lineIx = min(lineIx + stepSize, wrappedLines.len - height)
    elif c == '\3' or c == quitChar: # keyboard interrupt or quit
      stdout.write "\n"
      showCursor(stdout)
      return
