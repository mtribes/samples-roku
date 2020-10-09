function createMtribesNode(subtype as String, arguments = invalid as Object) as Object
  result = createObject("roSGNode", subtype)
  if arguments <> invalid then
    result.callFunc("constructor", arguments)
  else
    result.callFunc("constructor")
  end if
  return result
end function