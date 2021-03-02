function isValid(obj As Dynamic) As Boolean
    return type(obj) <> "<uninitialized>" and obj <> invalid
end Function

function isInvalid(obj As Dynamic) As Boolean
    return NOT isValid(obj)
end Function

function isObject(obj As Dynamic) As Boolean
    return isValid(obj) and getInterface(obj, "ifAssociativeArray") <> invalid
end function

function isBoolean(obj As Dynamic) As Boolean
    return isValid(obj) and GetInterface(obj, "ifBoolean" ) <> invalid
end Function

function isInteger(obj As Dynamic) As Boolean
    return isValid(obj) and GetInterface(obj, "ifInt") <> invalid
end Function

function IsFloat(obj As Dynamic) As Boolean
    return IsValid(obj) and  GetInterface(obj, "ifFloat") <> invalid
end Function

function IsLong(obj As Dynamic) As Boolean
return IsValid(obj) and  GetInterface(obj, "ifLongInt") <> invalid
end Function

function IsDouble(obj As Dynamic) As Boolean
return IsValid(obj) and  GetInterface(obj, "ifDouble") <> invalid
end Function

function IsNumber(obj As Dynamic) As Boolean
return IsFloat(obj) or IsInteger(obj) or IsLong(obj) or IsDouble(obj)
end Function

function isString(obj As Dynamic) As Boolean
    return isValid(obj) and GetInterface(obj, "ifString") <> invalid
end function

function isArray(obj As Dynamic) As Boolean
    return isValid(obj) and GetInterface(obj, "ifArray") <> invalid
end Function

function isNotEmptyArray(obj As Dynamic) As Boolean
    return isArray(obj) and obj.Count() > 0
end Function

function isEmptyObject(obj As Dynamic) As Boolean
    return NOT isNotEmptyObject(obj)
end Function

function isNotEmptyObject(obj As Dynamic) As Boolean
    return isObject(obj) and obj.Count() > 0
end Function

function isNotEmptyString(obj As Dynamic) As Boolean
    return isString(obj) and Len(obj) > 0
end function

function isEmptyString(obj As Dynamic) As Boolean
    return isString(obj) and Len(obj) = 0
end function

Function IsNode(obj As Dynamic) As Boolean
    tf = type(obj)
    return tf="SGNode" or tf="roSGNode"
End Function

function toBoolean(parameter as dynamic) as boolean
    if isInvalid(parameter) then
        return false
    else if isString(parameter) then
        return safeLowerCase(parameter) = "true"
    else if isNumber(parameter)then
        return parameter <> 0
    else if isBoolean(parameter) then
        return parameter
    else
        return false
    end if
end function

function toString(value as dynamic)
  if isString(value) then
    return value
  else if isBoolean(value) then
    return value.toStr()
  else if isArray(value) or isObject(value) then
    return formatJSON(value)
  else if isInteger(value) then
    return StrI(value, 10)
  else if isFloat(value) then
    return value.toStr()
  end if
  return ""
end function

function safeLowerCase(parameter as dynamic) as string
    if isString(parameter) then return lcase(parameter)
    return ""
end function

function ifElse(matcher As Boolean, trueRes As Dynamic, falseRes As Dynamic) As Dynamic
    if matcher then return trueRes
    return falseRes
end function

function isValuesEqual(value1, value2)
    if isNode(value1) OR isNode(value2) then
        if isNode(value2) and isNode(value2) and value2.isSameNode(value1)
            return true
        else
            return false
        end if
    else
        return value1 = value2
    end if
end function
