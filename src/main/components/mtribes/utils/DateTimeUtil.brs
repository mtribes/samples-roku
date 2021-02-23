' @return time String in milliseconds from 00:00:00 1/1/1970
function generateTimeStamp() as String
    dt = createObject("roDateTime")
    milliseconds = dt.GetMilliseconds()
    if milliseconds < 10
        milliseconds = "00" + StrI(milliseconds, 10)
    else if milliseconds < 100
        milliseconds = "0" + StrI(milliseconds, 10)
    else
        milliseconds = StrI(milliseconds, 10)
    end if
    return dt.asSeconds().toStr() + milliseconds
end function

' @return time Double in milliseconds from 00:00:00 1/1/1970
function getTime() as double
    dt = createObject("roDateTime")
    milliseconds = (dt.AsSeconds() * 1000) + dt.GetMilliseconds()
    return milliseconds
end function