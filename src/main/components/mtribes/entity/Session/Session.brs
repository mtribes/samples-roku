function constructor(arguments as Object)
    m.top.id = "MTSession"

    m.SERVED_PERIOD_THROTTLE_MSEC = 1000
    m.STREAM_POLL_RATE_MSEC = 20 * 60 * 1000
    m.KEEP_ALIVE_RATE_SEC  = 40
    m.KEEP_ALIVE_MAX_TIME_SEC = 120
    m.KEEP_ALIVE_EVENT_TYPE  = "sdk/ka"

    m.primer = arguments.primer
    m.analytics = arguments.analytics
    m.stream = arguments.stream
    m.config = arguments.config
    m.broker = arguments.broker
    m.gateway = arguments.gateway
    m.isOnline = true
    m.connected = false
    m.hibernating = false
    m.isPollTimerRunning = false
    m.sessionStartInProcess = false
    m.sessionStatus = MTSessionStatus()
    m.lastServed = {}

    m.locked = createMtribesNode("MTSafeStorage", {storageType: _lockCacheType(m.config), ns: "mtribes:x:"})
    m.deviceStatusHandler = createMtribesNode("MTDeviceStatusHandler")

    m.nextRefreshTimer = createObject("roSGNode", "Timer")
    m.nextRefreshTimer.setFields({
        repeat : false
    })
    m.pollTimer = createObject("roSGNode", "Timer")
    m.pollTimer.observeFieldScoped("fire", "_onPollTimer")
    m.pollTimer.setFields({
        repeat : false
    })

    m.keepAliveTimer = createObject("roSGNode", "Timer")
    m.keepAliveTimer.observeFieldScoped("fire", "_onKeepAliveTimer")
    m.keepAliveTimer.setFields({
      duration : m.KEEP_ALIVE_RATE_SEC
      repeat : false
    })
    m.keepAliveExpiredTimer = createObject("roTimeSpan")
		m.keepAliveExpiredTimer.mark()

    m.state = createMtribesNode("MTSessionState", {
        locked: m.locked,
        config: m.config,
        fallbacks: arguments.fallbacks,
        localStore: arguments.localStore
        broker: m.broker
    })
    m.top.anonymous = m.state.anonymous

    _envStateChange(CreateObject("roDeviceInfo").GetLinkStatus())

    m.state.observeFieldScoped("changed", "_onStateChange")
    m.state.observeFieldScoped("anonymous", "_onStateAnonymous")
    m.state.observeFieldScoped("ready", "_onStateReady")
    m.state.observeFieldScoped("status", "_onStateStatus")
    m.stream.observeFieldScoped("onMessage", "_onStreamMsg")
    m.stream.observeFieldScoped("onStatus", "_onStreamStatus")
	  m.config.observeFieldScoped("changed", "_onConfigChange")
	  m.analytics.observeFieldScoped("eventTracked", "_onEventTracked")

    m.deviceStatusHandler.observeFieldScoped("isOnline", "_onOnlineChange")
    m.deviceStatusHandler.observeFieldScoped("isScreenSaverDisabled", "_onScreenSaverDisabled")
    m.nextRefreshTimer.observeFieldScoped("fire", "_onNextRefreshTimer")
end function

function start(data={} as Object) as Object
    if (isNotEmptyObject(data) and isString(data.userId))
        return _identify(data.userId, data.fields, data.options)
    else
        return _anonymize(data.fields)
    end if
end function

function update(fields as Object) as Object
  if (m.top.anonymous) then
    return _anonymize(fields)
	else
    return _identify(m.state.userId, fields, { signed: m.state.sig })
  end if
end function

function track(expId as string, eventType as string, details={} as object) as void
  if (isInvalid(eventType) or isEmptyString(eventType)) return
  if (LCase(eventType).Instr("sdk/") = 0) then
    m.config.log.callFunc("warn","ignoring event with reserved category 'sdk' " + eventType)
    return
  end if
  expState = m.state.callFunc("expState", expId)
  m.analytics.callFunc("track", eventType, {
    eid: expId
    sid: expState.sid
    on: expState.on
    label: details.label
    value: details.value
  }, m.state )
end function

function experienceState(expId as string, isSection = false as Dynamic) as object
  ' auto anonymize if accessing Experience while session in 'created' state
  if isInvalid(isSection) then isSection = false
  if (m.state.status = m.sessionStatus.Created and NOT m.sessionStartInProcess) then
    _anonymize()
  end if

  expState = m.state.callFunc("expState", expId)
  sid = expState.sid
  on = expState.on

  ' throttle served analytic events for same experience

  if NOT isSection and NOT _servedRecently(expId, sid) then
    m.lastServed[expId] = { ts: generateTimeStamp(), sid: sid }
    m.analytics.callFunc("track", "sdk/served", { eid: expId, sid: sid, on: on }, m.state)
  end if
  return expState
end function

function defaultExperienceState(expId as string) as object
    return m.state.callFunc("expDefaultState", expId)
end function

'callbacks
function _onOnlineChange(event)
  isOnline = event.getData()
  if (isOnline <> m.isOnline) then
    _envStateChange(isOnline)
  end if
end function

function _onScreenSaverDisabled(event)
  if event.getData() then
    m.analytics.callFunc("removeEvents", m.KEEP_ALIVE_EVENT_TYPE)
    _envStateChange(m.isOnline)
    if m.config.autoUpdate AND m.isOnline then
      _prime({ op: "rf" })
    end if
  end if
end function

function _onKeepAliveTimer()
  _keepAlive()
end function

function _onStateChange(message) as Void
    eventData = message.getData()
    event = eventData.event
    h = eventData.header
    if (isInvalid(event)) then
        ' if we have a header but no event to broadcast then
        ' priming has completed but no changes were detected
        ' from the previous session state
        if (isValid(h)) then
            'need to update all nodes because of we can work with stored session data
            _resolvePending(m.sessionStatus.Primed)
            _startNextPoll()
            if(isValid(h) and isValid(h.rp)) then
                _checkNextRefresh(h.rp)
            end if
        end if
        return
    end if

    if (toBoolean(event.userChange)) then
        _resetKeepAlive()
        m.lastServed = {}
    end if

    if(event.status = m.sessionStatus.Initializing) then
        _emit(event)
    else if (event.status = m.sessionStatus.Elapsed) then
        _resolvePending(event.status)
        _emit(event)
    else if(event.status = m.sessionStatus.Errored) then
        _resolvePending(event.status)
        _emit(event)
        _startNextPoll()
    else if(event.status = m.sessionStatus.Primed) then
        _resolvePending(event.status)
        _emit(event)
        _startNextPoll()
        if(isValid(h) and isValid(h.rp)) then
            _checkNextRefresh(h.rp)
        end if
    end if
end function

function _onStateAnonymous(event)
    eventData = event.getData()
    m.top.anonymous = eventData
end function

function _onStateReady(event)
    eventData = event.getData()
    m.top.ready = eventData
end function

function _onStateStatus(event)
    eventData = event.getData()
    m.top.status = eventData
end function

function _onPollTimer()
    m.primer.callFunc("prime", m.state, { op: "rf" })
end function

function _onNextRefreshTimer()
    _prime({ op: "rf" })
end function

function _onPending()
    if isValid(m.pending) then
        m.pending = invalid
    end if
end function

function _onStreamStatus()
	if m.isPollTimerRunning then _startNextPoll()
end function

function _onStreamMsg(event)
  eventData = event.getData()
  if (eventData.op = "sync") then _prime({ op: "rf", mv: eventData.body.mv })
end function

function _onConfigChange()
    ' when config changes and we have an active poll
	' restart it with any updated poll rates
	if m.isPollTimerRunning then _startNextPoll()
	if m.config.autoUpdate then
    _envStateChange(m.isOnline)
  else
    _stopPolling()
    _disconnect()
  end if
	m.locked.storageType = _lockCacheType(m.config)
end function

function _onEventTracked(message)
  eventType = message.getData()
  if eventType = m.KEEP_ALIVE_EVENT_TYPE then
    _startKeepAlive()
  else
    _resetKeepAlive()
  end if
end function

'private
function _identify(userId as dynamic, fields=invalid as object, options=invalid as object) as object
    if NOT isString(userId) or Len(userId) > 200 then
        m.config.log.callFunc("error","mt:session.start: userId must be a string lt 200 chars")
        m.pending = CreateObject("roSGNode", "MTPromise")
        m.pending.observeFieldScoped("result", "_onPending")
        _resolvePending("errored")
        return m.pending
    end if

    m.top.anonymous = false
    m.sha256Generator = createObject("roEVPDigest")
    m.sha256Generator.Setup("sha256")
    byteArray = CreateObject("roByteArray")
    byteArray.FromAsciiString(userId)
    uidHash = m.sha256Generator.process(byteArray)
    m.state.callFunc("identify", userId, uidHash, fields, options)
    return _prime({ op: "id" })
end function

function _anonymize(fields=invalid as object) as object
    m.top.anonymous = true
    m.state.callFunc("anonymize", fields)
    return _prime({ op: "an" })
end function

function _prime(headers as object) as object
    _stopPolling()
    _resolvePending("errored")
    m.pending = CreateObject("roSGNode", "MTPromise")
    m.pending.observeFieldScoped("result", "_onPending")
    m.sessionStartInProcess = true
    if NOT m.hibernating then
        m.primer.callFunc("prime", m.state, headers)
        if NOT m.config.sessionLock then _connect()
    end if
    return m.pending
end function

function _resolvePending(status as object) as void
    if (isValid(m.pending)) then
        m.sessionStartInProcess = false
        m.pending.callFunc("resolve", {status: status})
    end if
end function

function _emit(event as object) as void
    if (isArray(event.children) AND event.children.Count() > 0) then
        for each child in event.children
            m.broker.callFunc("updateNodeStateById", child)
            if (child.eventType = "Remove") then
                _removeSubscribers(child.source)
            end if
        end for
    end if
    onChange({event: event, scope: event.source})
end function

function _removeSubscribers(expId as string)
    m.lastServed.delete(expId)
    m.broker.callFunc("removeFromSaved", expId)
end function

function _startNextPoll()
  _stopPolling()
  if m.config.pollRateSec > 0 AND m.config.autoUpdate then
    if(m.stream.active) then
      delay = m.STREAM_POLL_RATE_MSEC
    else
      delay = m.config.pollRateSec * 1000
    end if
    if NOT m.config.sessionLock then
      m.pollTimer.duration = delay/1000
      m.pollTimer.control = "start"
      m.isPollTimerRunning = true
    end if
  end if
end function

function _stopPolling()
    m.pollTimer.control = "stop"
    m.isPollTimerRunning = false
end function


function _checkNextRefresh(nextRefreshSec as integer)
    m.nextRefreshTimer.control = "stop"
    if (nextRefreshSec > 0) then
        stagger = Fix(Rnd(0) * 3) + 1
        delay = (nextRefreshSec + stagger) * 1000 - getTime()
        if (delay > 0) then
            m.nextRefreshTimer.duration = delay/1000
            m.nextRefreshTimer.control = "start"
        end if
    end if
end function

function _envStateChange(isOnline as boolean) as void
  m.isOnline = isOnline

  if NOT isOnline then
    m.hibernating = true
    m.analytics.callFunc("enabled", false)
    _disconnect()
    _stopKeepAlive()
    _stopPolling()
  else
    m.hibernating = false
    m.analytics.callFunc("enabled", true)
    if m.state.status <> m.sessionStatus.Created then
      if NOT m.connected then
        _resetKeepAlive()
        if m.config.autoUpdate then
          ' refresh in case we missed anything while offline
          ' this will begin polling once its complete
          ' and connect the stream
          _prime({ op: "rf" })
        else
          ' if auto update is off then we'll
          ' manually update the connected state
          _connect()
          _keepAlive()
        end if
      else
        ' ensure the stream is connected if it's meant to be,
        ' checks inside '_connect' will prevent it from connecting
        ' if it's not meant to be
        _connect()
        if NOT m.isPollTimerRunning then _startNextPoll()
        ' as we've just come out of a quick hibernation
        ' restart the keep-alive timeouts
        _startKeepAlive()
      end if
    end if
  end if
end function

function _connect()
  if NOT m.connected then
    m.connected = true
    m.hibernating = false
    m.stream.callFunc("connect")
  end if
end function

function _disconnect()
  if m.connected then
    m.connected = false
    m.hibernating = true
    m.stream.callFunc("disconnect")
  end if
end function

function _lockCacheType(config as object) as string
    sessionLock = config.sessionLock
    if (isBoolean(sessionLock) and sessionLock = false) return "none"
    return "memory"
end function

function _servedRecently(expId as string, sid as string) as boolean
    entry = m.lastServed[expId]
    currentTime = generateTimeStamp().toInt()
    dif = 0
    if(isValid(entry)) then dif = currentTime - entry.ts.toInt()
    return isValid(entry) and entry.sid = sid and dif <= m.SERVED_PERIOD_THROTTLE_MSEC
end function

function _startKeepAlive()
  ' if keep alive is already pending, or we're hibernating,
  ' or we've not had an initial keep alive reset, abort
  if (NOT (m.keepAliveTimerActive OR m.hibernating)) then
    _stopKeepAlive()
    if m.keepAliveExpiredTimer.totalSeconds() < m.KEEP_ALIVE_MAX_TIME_SEC then
      m.keepAliveTimer.control = "start"
      m.keepAliveTimerActive = true
    end if
  end if
end function

function _resetKeepAlive()
  if NOT m.status = m.sessionStatus.Created then
		_stopKeepAlive()
		m.keepAliveExpiredTimer.mark()
		_startKeepAlive()
  end if
end function

function _stopKeepAlive()
  m.keepAliveTimer.control = "stop"
  m.keepAliveTimerActive = false
end function

function _keepAlive()
  _stopKeepAlive()
  if m.keepAliveExpiredTimer.totalSeconds() < m.KEEP_ALIVE_MAX_TIME_SEC then
    m.analytics.callFunc("track", m.KEEP_ALIVE_EVENT_TYPE, {}, m.state )
  end if
end function
