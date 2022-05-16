import os

import errors


proc getConfigFilePath*(): string {.raises: [].} =
  joinPath(getConfigDir(), "roman", "config")


proc getSubsFilePath*(): string {.raises: [].} =
  joinPath(getConfigDir(), "roman", "subscriptions")


proc initConfigDir*() {.raises: [RomanError].} =
  let configDir = joinPath(getConfigDir(), "roman")
  try:
    if not existsOrCreateDir(configDir):
      let config = getConfigFilePath()
      let subs = getSubsFilePath()
      writeFile(config, "")
      writeFile(subs, "")
  except IOError, OSError:
    raise newException(RomanError, getCurrentExceptionMsg())


proc getShareDir*(): string {.raises: [RomanError].} =
  # TODO: support non-Linux OSes
  let defaultShare = expandTilde("~/.local/share/")
  let shareRoot = getEnv("XDG_SHARE_HOME", defaultShare)
  let shareDir = joinPath(shareRoot, "roman")

  if not dirExists(shareDir):
    try:
      createDir(shareDir)
    except OSError, IOError:
      raise newException(
        RomanError, "could not create $HOME/.local/share/roman")

  return shareDir


proc getPostReadFile*(): string {.raises: [RomanError].} =
  result = joinPath(getShareDir(), "read-posts")
  if not fileExists(result):
    var f: File
    if not f.open(result, mode = fmWrite):
      raise newException(RomanError, "could not create read-posts file")
    f.close()
