import sequtils


proc replace*[T](s: var seq[T], old: T, updated: T) =
  var elementIx = -1
  for ix, element in s:
    if element == old:
      elementIx = ix
  if elementIx == -1:
    raise newException(KeyError, "could not find post in feed post list")

  s.keepIf(proc (element: T): bool = element != old)
  s.insert(@[updated], elementIx)
