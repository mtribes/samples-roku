function constructor(arguments as Object)
    m.locked = arguments.locked
    m.config = arguments.config
    m.broker = arguments.broker
    m.localStore = arguments.localStore
    m.templates = m.broker
    m.initialized = false
    m.loadKey = invalid
    m.active = { header: { v: "0" }, states: {} }
    m.sessionStatus = MTSessionStatus()
    m.promiseStatus = MTPromiseStatus()
    m.sessionStore = createMtribesNode("MTSafeStorage", {storageType: "session", ns: "mtribes:"})
    m.restoreId = m.sessionStore.callFunc("getItem", "rid")

    m.status = m.sessionStatus.Created
    m.ready = false
    m.anonId = m.localStore.callFunc("getItem", "aid")

    m.top.setFields({
        status : m.status
        anonId : m.anonId
        ready : m.ready
    })
    m.templatesMapCache = {}
    if isObject(arguments.fallbacks) AND isNotEmptyString(arguments.fallbacks.json) then m.fallbacks = parseJSON(arguments.fallbacks.json)
    if isInvalid(m.fallbacks) then m.fallbacks = {}

    if (isInvalid(m.anonId) or isEmptyString(m.anonId)) then _resetAnonId()
end function

'public block
function lastStatesVersion()
    return m.active.header.v
end function

function identify(userId as string, uidHash as string, fields as object, opts as object) as void
    userChange = false
    ' on first identify, check if previously persisted uidHash matches _restoreId,
    ' if it does we can restore still active session states for that user while we
    ' load in new ones. This gives the user better fallbacks if accessed before session primed
    if (m.status = m.sessionStatus.Created) then
        if (isString(uidHash) and uidHash = m.restoreId) then
            userChange = false
            data = m.sessionStore.callFunc("getItem", "state")
            if isValid(data) then m.active = data
        else
            userChange = true
        end if
    else
        wasKnown = m.top.anonymous = false
        userChange = ifElse(not wasKnown, true, userId <> m.top.userId)
    end if

    if userChange then _purgeCachedState()

    m.locked.secure = toBoolean(uidHash)

    fieldsUpdate = {
        anonymous : false
        userId : userId
        sig : ""
        fields: _sanitize(fields)
    }
    m.restoreId = uidHash
    if isNotEmptyObject(opts) then fieldsUpdate.sig = opts.signed
    m.top.setFields(fieldsUpdate)

    ' if user is changing, or session is starting up for first time then run init flow
    if (userChange or m.status = m.sessionStatus.Created) then
        readyChange = _updateReadiness(false)
        m.initialized = false
        _updateStatus(m.sessionStatus.Initializing, { readyChange: readyChange, userChange: userChange })
    end if
end function

function anonymize(fields as object)
    userChange = false
    ' on first anonymize, check if previously persisted anonId matches _restoreId,
    ' if it does we can restore still active session states for that anon user while we
    ' load in new ones. This gives the user better fallbacks if accessed before session primed
    if (isString(m.anonId) and m.status = m.sessionStatus.Created) then
        userChange = false
        if (m.anonId = m.restoreId) then
            data = m.sessionStore.callFunc("getItem", "state")
            if isValid(data) then m.active = data
        else
            'purge cache if there's a restore id mismatch
            'but don't reset the anon id as it's still valid
            _purgeCachedState()
        end if
    else
        wasAnon = (m.top.anonymous = true)
        userChange = (wasAnon <> true)
        if (userChange or m.anonId = invalid) then
            _purgeCachedState()
            _resetAnonId()
        end if
    end if
    m.restoreId = m.anonId
    m.top.setFields({
        sig : ""
        userId : ""
        anonymous : true
        fields : _sanitize(fields)
    })
    m.locked.secure = toBoolean(m.restoreId)


    if (userChange or m.status = m.sessionStatus.Created) then
        readyChange = _updateReadiness(false)
        m.initialized = false
        _updateStatus(m.sessionStatus.Initializing, { readyChange: readyChange, userChange: userChange })
    end if
end function

function expState(id as string) as object
    s = m.locked.callFunc("getItem", id)
    if (isInvalid(s)) then
        if (isValid(m.active.states[id])) then
            s = m.active.states[id]
        else
            s = expDefaultState(id)
        end if
        s = _applyDataObject(s, id)
        m.locked.callFunc("setItem", id, s)
    end if
    return s
end function

function expDefaultState(id as string) as object
    if(isValid(m.fallbacks[id])) then
        return _applyDataObject(m.fallbacks[id], id)
    else
        return { v: 0, on: false, sid: "fb", data: {} }
    end if
end function

function setActive(data as object, hasStates = true)
    if (hasStates) then
        m.active = data
        if (isNotEmptyString(m.restoreId)) then
            m.sessionStore.callFunc("setItem", "rid", m.restoreId)
            m.sessionStore.callFunc("setItem", "state", data)
        end if
    end if
end function

function loadStart(newPromise as object) as string
    if isValid(m.promise) then
        m.promise.unobserveFieldScoped("result")
    end if
    m.promise = newPromise
    m.promise.observeFieldScoped("result", "onRequestResult")
    m.loadKey = "k" + generateTimeStamp()
    return m.loadKey
end function

function waitElapsed(key as string) as void
    if (key <> m.loadKey) then return

    readyChange = _updateReadiness(true)
    _updateStatus(m.sessionStatus.Elapsed, { readyChange: readyChange })
end function

function loadFailed(key as string, error) as void
    if (key <> m.loadKey) then return
    readyChange = _updateReadiness(true)
    m.loadKey = invalid
    _updateStatus(m.sessionStatus.Errored, { error: error, readyChange: readyChange })
end function

function loadComplete(key as string, data as object) as void
    if (key <> m.loadKey) then return

    m.loadKey = invalid
    readyChange = _updateReadiness(true)

    if (isInvalid(data)) then data = {}
    if (isInvalid(data.header)) then data.header = { v: "" }
    if (isInvalid(data.states)) then data.states = {}

    header = data.header
    changes = invalid

    if (header.changes = 0) then
        changes = []
    else
        changes = diffStates(m.locked, m.active.states, data.states, m.fallbacks)
    end if
    setActive(data, header.changes <> 0)
    _updateStatus(m.sessionStatus.Primed, { readyChange: readyChange })
    m.initialized = true

    if (isNotEmptyArray(changes)) then
        _emit({ changes: changes, header: header, statusChange: false })
    else
        ' no state changes but possible change to future refresh point.
        ' we also need to let listener know the load is complete even
        ' if no direct changes.
        onChange({event: invalid, header: header})
    end if
end function

'callbacks
function onRequestResult(message)
    event = message.getData()
    if event.status = m.promiseStatus.success then
        loadComplete(event.reqId, event.data)
    else if event.status = m.promiseStatus.error then
        loadFailed(event.reqId, event.error)
    end if
    m.promise.unobserveFieldScoped("result")
    m.promise = invalid
end function

'private block
function _resetAnonId()
    m.anonId = CreateObject("roDeviceInfo").GetRandomUUID()
    m.top.anonId = m.anonId
    m.localStore.callFunc("setItem", "aid", m.anonId)
end function

function _purgeCachedState()
    m.sessionStore.callFunc("removeItem", "state")
    m.sessionStore.callFunc("removeItem", "rid")
    m.locked.callFunc("clear")
    m.active = { header: { v: "0" }, states: {} }
end function

function _sanitize(infields as object) as object
    if isInvalid(infields) then return infields
    fields = {}
    names = infields.keys()
    for each name in names
        v = infields[name]
        if isString(v) or isNumber(v) or isBoolean(v) then
            fields[name] = v
        else if isValid(v) then
            m.config.log.callFunc("info", Substitute("removing unsupported user property {0} of type {1}", name, type(v)))
        end if
    end for
    return fields
end function

function _aliasData(t as object, rawData as object) as object
    if isInvalid(t) then return {}
    tId = t.id
    if isValid(m.templatesMapCache[tId]) then dataAlias = m.templatesMapCache[tId]
    if isInvalid(dataAlias) then dataAlias = t.dataAlias
    if isInvalid(dataAlias) then return {}
    m.templatesMapCache[tId] = dataAlias
    data = {}
    for each id in dataAlias
        a = dataAlias[id]
        splitedA = a.split(",")
        key = splitedA[0]
        dataType = splitedA[1]
        value = rawData[id]
        if dataType = "co" then
            result = ""
            if isNotEmptyObject(value) and isNotEmptyString(value.value) then
              result = _colorCorrector(value)
            end if
        else if dataType = "da" or dataType = "st" or dataType = "ur" or dataType = "se" then
            result = ""
            if isNotEmptyString(value) then result = value
        else if dataType = "bo" then
            result = false
            if isBoolean(value) then result = value
        else if dataType = "ta" then
            result = []
            if isNotEmptyArray(value) then result = value
        else
            result = value
        end if
        data[key] = result
    end for
    return data
end function


function _updateStatus(status as string, updates = {} as object) as boolean
    ' after a session is initialized there's no further status changes,
    ' until the user changes where we run through the initialization
    ' process again
    if (m.initialized) then return false

    lastStatus = m.status
    m.top.status = status
    m.status = status
    if (toBoolean(updates.statusChange) = false) then updates.statusChange = (lastStatus <> m.status)
    if (isInvalid(updates.statusChange) and isInvalid(updates.userChange) and isInvalid(updates.readyChange)) then return false

    _emit(updates) 'status change event
    return true
end function

function _emit(updates = {})
    event = {
        source: "session",
        eventType: "update",
        status: m.status,
        userChange: updates.userChange = true,
        readyChange: updates.readyChange = true,
        statusChange: updates.statusChange = true
    }
    if (isValid(updates.error)) then event.error = updates.error
    if (isNotEmptyArray(updates.changes)) then event.children = updates.changes
    onChange({event: event})
end function

'brs only functions
function _applyDataObject(s as object, id as string) as object
    if (isNotEmptyString(s.data)) then
        ' lazy decode and alias stringified state
        s.data = parseJson(s.data)
        t = m.templates.callFunc("template", id)
        s.data = _aliasData(t, s.data)
    else if (isInvalid(s.data)) then
        ' avoid null pointer exceptions for users of sdk accessing data
        s.data = {}
    end if

    return s
end function

function _updateReadiness(newValue)
    readyChange = m.ready <> newValue
    m.ready = newValue
    m.top.ready = newValue
    return readyChange
end function

function _convertOpacityToHexAlphaChanel(opacity=1 as float) as string
    if (isInvalid(opacity)) then return "FF"
    if (opacity < 0) then opacity = 0
    if (opacity > 1) then opacity = 1

    alpha = Cint(opacity * 255)

    return _decToHex(alpha)
end function

function _decToHex(dec as integer) as string
  hexColor = StrI(dec, 16)
  if Len(hexColor) < 2 then hexColor = "0" + hexColor
  return hexColor
end function

function _colorCorrector(value) as string
  value.value = value.value.replace("#", "")
  colorArr = value.value.split("")
  if colorArr.count() >= 3 and colorArr.count() <= 6 then
    rgb = ""
    if colorArr.count() = 3 then
      for i = 0 to colorArr.count() - 1
        rgb += colorArr[i] + colorArr[i]
      end for
    else if colorArr.count() = 4 then
      rgb += colorArr[0] + colorArr[1]
      for i = 2 to colorArr.count() - 1
        rgb += colorArr[i] + colorArr[i]
      end for
    else if colorArr.count() = 5 then
      rgb = value.value + colorArr[4]
    else
      rgb = value.value
    end if
    return "0x" + rgb + _convertOpacityToHexAlphaChanel(value.opacity)
  end if
  return ""
end function
