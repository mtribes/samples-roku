function constructor(arguments as Object)
    m.apiKey = arguments.apiKey
    m.fallbacks = arguments.fallbacks
    m.broker = arguments.broker
    analyticsOnly = true
    if isObject(m.fallbacks) AND isNotEmptyString(m.fallbacks.json) then analyticsOnly = false
    m.config = createMtribesNode("MTConfig", {
      apiKey: m.apiKey
      analyticsOnly: analyticsOnly
    })
    m.localStore = createMtribesNode("MTSafeStorage", {storageType: "local", ns: "mtribes:"})
    m.top.setFields({
      id : "MTClient"
      sessionLock : m.config.sessionLock
      waitForMsec : m.config.waitForMsec
      serviceUrl : m.config.serviceUrl
      userTracking : m.config.userTracking
      logLevel : m.config.logLevel
    })

    m.config.observeFieldScoped("autoUpdate", "onAutoUpdate")
    m.top.observeFieldScoped("sessionLock", "onSessionLock")
    m.top.observeFieldScoped("waitForMsec", "onWaitForMsec")
    m.top.observeFieldScoped("serviceUrl", "onServiceUrl")
    m.top.observeFieldScoped("userTracking", "onUserTracking")
    m.top.observeFieldScoped("logLevel", "onLogLevel")

    cid = m.localStore.callFunc("getItem", "cid")
    if (not isString(cid) or isEmptyString(cid)) then
      cid = CreateObject("roDeviceInfo").GetRandomUUID()
      m.localStore.callFunc("setItem", "cid", cid)
    end if

    subConfig = {
      apiKey: m.config.apiKey
      serviceUrl: m.config.serviceUrl
      loglevel: m.config.loglevel
    }
    m.gateway = createMtribesNode("MTGateway",{
      id: "MTGateway"
      config: subConfig
    })
    'Such definition required for removing rendezvous inside MTGateway task
    m.stream = createMtribesNode("MTStream", {
      id: "MTStream"
      config: subConfig
    })
    m.analytics = createMtribesNode("MTAnalytics", {clientId: cid, gateway: m.gateway, config: m.config})
    m.primer = createMtribesNode("MTSessionPrimer", {clientId: cid, gateway: m.gateway, config: m.config, broker: m.broker})
    m.top.session = createMtribesNode("MTSession", {
      primer: m.primer,
      analytics: m.analytics,
      stream: m.stream,
      fallbacks: m.fallbacks,
      broker: m.broker
      config: m.config
      gateway: m.gateway
      localStore: m.localStore
    })

    m.broker.defaultSession = m.top.session

    m.URL_FORMAT = CreateObject("roRegex", "((https|http):\/\/client.mtribes.)+[a-zA-Z\d]{2,3}", "i")
end function

'callbacks
'all functions below - is replacement of setters logic from other languages. They responsible
'for validating updates of Client fields and proxying them to Config
function onSessionLock(message as object) as void
    sessionLock = message.getData()
    if (sessionLock <> m.config.sessionLock) then
        m.config.sessionLock = sessionLock
    end if
end function

function onWaitForMsec(message as object) as void
    waitForMsec = message.getData()
    if(waitForMsec < 0) then
        m.config.log.callFunc("warn", "Negative waitForMsec value is tried to be apply. Previous value will be used")
        m.top.waitForMsec = m.config.waitForMsec
        return
    end if

    if (waitForMsec <> m.config.waitForMsec) then
        m.config.waitForMsec = waitForMsec
    end if
end function

function onServiceUrl(message as object) as void
    serviceUrl = message.getData()
    if(NOT m.URL_FORMAT.IsMatch(serviceUrl)) then
        m.config.log.callFunc("warn","Wrong URL is tried to be apply. Previous serviceUrl will be used")
        m.top.serviceUrl = m.config.serviceUrl
        return
    end if
    if (serviceUrl <> m.config.serviceUrl) then
        m.config.serviceUrl = serviceUrl
        m.gateway.config = {
          apiKey: m.config.apiKey
          serviceUrl: serviceUrl
          loglevel: m.config.logLevel
        }
        m.stream.config = {
          apiKey: m.config.apiKey
          serviceUrl: serviceUrl
          loglevel: m.config.logLevel
        }
    end if
end function

function onUserTracking(message as object) as void
    userTracking = message.getData()
    if (userTracking <> m.config.userTracking) then
        m.config.userTracking = userTracking
    end if
end function

function onLogLevel(message as object) as void
    logLevel = message.getData()
    if (logLevel > 2) then
        m.config.log.callFunc("warn","Wrong logLevel is tried to be apply. Previous logLevel will be used")
        m.config.logLevel = logLevel
    end if
    if (logLevel <> m.config.logLevel) then
        m.config.logLevel = logLevel
        m.gateway.logLevel = logLevel
        m.stream.logLevel = logLevel
    end if
end function

function onAutoUpdate(message as object) as void
  if m.stream.autoUpdate <> message.getData()
    m.stream.autoUpdate = message.getData()
  end if
end function
