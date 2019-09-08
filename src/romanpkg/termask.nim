import options
import sequtils
import strutils
import terminal
import tables

import fab

import errors


# This function was originally based on the promptListInteractive function
# in Nimble, and is therefore under the same license.

# Copyright (c) 2015, Dominik Picheta
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Nimble nor the
#    names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY DOMINIK PICHETA ''AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL DOMINIK PICHETA BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The original version may be found at
# https://github.com/nim-lang/nimble/blob/
#   2243e3fbc2dd277ad81df5d795307bf8389b9240/src/nimblepkg/cli.nim#L177


proc goDown(selectedIx: var int, currentArgs: seq[string]) {.raises: [].} =
  selectedIx = (selectedIx + 1) mod currentArgs.len


proc goUp(selectedIx: var int, currentArgs: seq[string]) {.raises: [].} =
  if selectedIx == 0:
    selectedIx = currentArgs.len - 1
  else:
    selectedIx -= 1


proc advancePage(currentArgs: var seq[string], selectedIx: var int,
    sliceIx: var int, argSlices: seq[seq[string]]) {.raises: [].} =
  if argSlices.len == 1:
    return
  # Advance to the next set of results and reset
  sliceIx += 1
  if sliceIx >= argSlices.len:
    sliceIx = 0
  selectedIx = 0
  currentArgs = argSlices[sliceIx]


proc goBackPage(currentArgs: var seq[string], selectedIx: var int,
    sliceIx: var int, argSlices: seq[seq[string]]) {.raises: [].} =
  if argSlices.len == 1:
    return
  # Go back to the last set of results and reset
  sliceIx -= 1
  if sliceIx < 0:
    sliceIx = argSlices.len - 1
  selectedIx = 0
  currentArgs = argSlices[sliceIx]


proc promptList*(question: string, args: openarray[string],
    displayNames: Table[string, string] = initTable[string, string](),
        show: int = -1): Option[string] {.raises: [ValueError, IOError].} =
  var
    selectedIx = 0
    selectionMade = false
    sliceIx = 0
    argSlices: seq[seq[string]]

  if show == -1:
    argSlices = @[toSeq(args)]
  else:
    if args.len <= show:
      argSlices = @[toSeq(args)]
    else:
      # Split the arguments into chunks of length show
      # Store those chunks in argSlices
      var counter = 0
      while counter < args.len:
        # Subtract 2 because both counter and show are 1 indexed
        let top = min(counter + show - 1, args.len - 1)
        let nextArgs = args[counter..top]
        argSlices.add(nextArgs)
        counter += show

  que(question, fg = fgDefault)

  var currentArgs = argSlices[sliceIx]
  for arg in currentArgs:
    stdout.write "\n"

  cursorUp(stdout, currentArgs.len)
  hideCursor(stdout)

  while not selectionMade:
    setForegroundColor(fgDefault)
    if argSlices.len > 1:
      cursorUp(stdout)
      echo "[", sliceIx + 1, "/", argSlices.len,
        "] N/Right to advance, P/Left to go back"

    let width = terminalWidth()
    for ix, arg in currentArgs:
      var shown: string
      if arg in displayNames:
        shown = displayNames[arg]
      else:
        shown = arg
      if ix == selectedIx:
        writeStyled("> " & shown & " <", {styleBright})
      else:
        writeStyled("  " & shown & "  ", {styleDim})
      let displayLen = shown.len + 4
      let paddingLen = width - displayLen
      if paddingLen > 0:
        stdout.write(repeat(' ', paddingLen))
        for s in 0..<(width):
          cursorBackward(stdout)
      cursorDown(stdout)
    for i in 0..<(currentArgs.len()):
      cursorUp(stdout)

    resetAttributes(stdout)

    while true:
      let c = getch()
      case c:
      of 'j': # go down
        goDown(selectedIx, currentArgs)
        break
      of 'k': # go up
        goUp(selectedIx, currentArgs)
        break
      # Handle arrow keys
      of chr(27):
        # Skip the useless [
        discard getch()
        case getch():
        of 'A': # up arrow
          goUp(selectedIx, currentArgs)
          break
        of 'B': # down arrow
          goDown(selectedIx, currentArgs)
          break
        of 'C': # right arrow
          advancePage(currentArgs, selectedIx, sliceIx, argSlices)
          break
        of 'D': # left arrow
          goBackPage(currentArgs, selectedIx, sliceIx, argSlices)
          break
        else: break
      of '\r':
        selectionMade = true
        break
      of 'N':
        advancePage(currentArgs, selectedIx, sliceIx, argSlices)
        break
      of 'P':
        goBackPage(currentArgs, selectedIx, sliceIx, argSlices)
        break
      of 'q':
        return none(string)
      of '\3':
        showCursor(stdout)
        # Move the cursor down to the end of the arguments list
        # so that after the interrupt, the error message is displayed
        # on its own line
        for _ in (selectedIx mod currentArgs.len)..currentArgs.len:
          cursorDown(stdout)
        raise newException(ValueError, "no value selected")
      else: break

  for i in 0..<currentArgs.len:
    eraseLine(stdout)
    cursorDown(stdout)
  for i in 0..<currentArgs.len():
    cursorUp(stdout)
  showCursor(stdout)
  return some(currentArgs[selectedIx])
