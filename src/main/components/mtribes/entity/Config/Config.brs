function constructor(arguments={} as Object)
    m.top.id = "MTConfig"

    m.DEFAULT_SERVICE_URL = "https://client.mtribes.com"
    m.DEFAULT_TRACKING = true
    m.DEFAULT_WAIT_LIMIT = 1200
    m.DEFAULT_POLL_RATE = 300
    m.DEFAULT_LOG_LEVEL = -1
    m.DEFAULT_SESSION_LOCK = true
    m.DEFAULT_ANALYTICS_ONLY = true
    m.DEFAULT_LOGGER = createMtribesNode("MTLogger",{
        config: m.top
        logLevel: m.DEFAULT_LOG_LEVEL
    })

    m.configParams = _applyDefaults({apiKey: arguments.apiKey, analyticsOnly: arguments.analyticsOnly})

    if (isNotEmptyObject(m.configParams)) then
        m.top.setFields(m.configParams)
    end if
    m.top.version = getVersion()

    _enableObservers()
end function


'callbacks
'this is a replacement of _updateConfig function from ts
function onFieldChanged(message as object) as void
    field = LCase(message.getField())
    value = message.getData()

    configParams = {}
    configParams.append(m.configParams)
    configParams[field] = value

    configParams = _applyDefaults(configParams)

    change = {}
    for each key in configParams
        if  key <> field AND NOT isValuesEqual(m.configParams[key], configParams[key])  then
            change[key] = configParams[key]
        end if
        if key = field
            if NOT isValuesEqual(configParams[key], value) then
                change[key] = configParams[key]
            end if
        end if
    end for

    m.configParams = configParams
    if isNotEmptyObject(change) then
        _disableObservers()
        m.top.setFields(change)
        _enableObservers()
        onChange(m.configParams)
    end if
end function

'private
function _applyDefaults(configParams as object)
    if (isObject(configParams)) then
        if (isInvalid(configParams.serviceUrl) or isEmptyString(configParams.serviceUrl)) then
            configParams.serviceUrl = m.DEFAULT_SERVICE_URL
        end if
        if (isInvalid(configParams.waitForMsec) or configParams.waitForMsec < 0) then
            configParams.waitForMsec = m.DEFAULT_WAIT_LIMIT
        end if

        if NOT isNode(configParams.log) then configParams.log = m.DEFAULT_LOGGER
        if NOT isBoolean(configParams.sessionLock) then configParams.sessionLock = m.DEFAULT_SESSION_LOCK
        if NOT isBoolean(configParams.userTracking) then configParams.userTracking = m.DEFAULT_TRACKING


        configParams.autoUpdate = NOT configParams.analyticsOnly AND NOT configParams.sessionLock
        configParams.pollRateSec = m.DEFAULT_POLL_RATE

        return configParams
    end if
    return {}
end function

function _enableObservers()
    m.top.observeFieldScoped("serviceUrl", "onFieldChanged")
    m.top.observeFieldScoped("waitForMsec", "onFieldChanged")
    m.top.observeFieldScoped("sessionLock", "onFieldChanged")
    m.top.observeFieldScoped("userTracking", "onFieldChanged")
    m.top.observeFieldScoped("pollRateSec", "onFieldChanged")
    m.top.observeFieldScoped("analyticsOnly", "onFieldChanged")
    m.top.observeFieldScoped("log", "onFieldChanged")
end function

function _disableObservers()
    m.top.unObserveFieldScoped("serviceUrl")
    m.top.unObserveFieldScoped("waitForMsec")
    m.top.unObserveFieldScoped("sessionLock")
    m.top.unObserveFieldScoped("userTracking")
    m.top.unObserveFieldScoped("pollRateSec")
    m.top.unObserveFieldScoped("analyticsOnly")
    m.top.unObserveFieldScoped("log")
end function
