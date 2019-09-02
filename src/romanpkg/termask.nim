import strutils
import terminal

import fab

import errors


proc promptList*(question: string, args: openarray[string]): string {.raises: [
    RomanError].} =
  echo question
  for ix, arg in args:
    echo "[", ix + 1, "] ", arg
  var choice: string
  while true:
    try:
      stdout.write "Make selection (1-", args.len + 1, "): "
      choice = stdin.readLine()
      return args[parseInt(choice)-1]
    except IOError as e:
      raise newException(RomanError, e.msg)
    except IndexError:
      echo "choice out of range"
    except ValueError:
      echo "invalid integer given"
