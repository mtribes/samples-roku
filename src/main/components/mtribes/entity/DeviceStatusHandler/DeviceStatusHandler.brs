function constructor()
  m.top.functionName = "mtTaskThread"
  m.top.control = "RUN"
end function

function mtTaskThread()

  messagePort  = CreateObject("roMessagePort")
  deviceInfo = CreateObject("roDeviceInfo")

  deviceInfo.setMessagePort(messagePort)
  deviceInfo.EnableLinkStatusEvent(true)
  deviceInfo.EnableScreensaverExitedEvent(true)

  m.isOnline = false

  while true
    msg = wait(0, messagePort)
    if type(msg) = "roDeviceInfoEvent" then
      processDeviceMessage(msg)
    end if
  end while
end function

function processDeviceMessage(msg)
  if msg.isStatusMessage() then
    data = msg.getInfo()
    if isValid(data.linkStatus) AND m.isOnline <> data.linkStatus then
      m.top.isOnline = data.linkStatus
      m.isOnline = data.linkStatus
    end if
    if isValid(data.exitedScreensaver) then m.top.isScreenSaverDisabled = data.exitedScreensaver
  end if
end function
