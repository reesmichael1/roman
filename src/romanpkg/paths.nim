import os

import errors


proc getSubsFilePath*(): string {.raises: [].} =
  joinPath(getConfigDir(), "roman", "subscriptions")


proc initConfigDir*() {.raises: [RomanError].} =
  let configDir = joinPath(getConfigDir(), "roman")
  try:
    if not existsOrCreateDir(configDir):
      let subsFile = joinPath(configDir, "subscriptions")
      writeFile(subsFile, "")
  except OSError as e:
    raise newException(RomanError, e.msg)
  except IOError as e:
    raise newException(RomanError, e.msg)


proc getShareDir*(): string {.raises: [].} =
  # TODO: support non-Linux OSes
  let defaultShare = expandTilde("~/.local/share/")
  let shareRoot = getEnv("XDG_SHARE_HOME", defaultShare)
  let shareDir = joinPath(shareRoot, "roman")
  return shareDir


proc getPostReadFile*(): string {.raises: [RomanError].} =
  result = joinPath(getShareDir(), "read-posts")
  if not existsFile(result):
    var f: File
    if not f.open(result, mode = fmWrite):
      raise newException(RomanError, "could not create read-posts file")
    f.close()
