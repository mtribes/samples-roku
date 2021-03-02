function constructor(arguments as Object)
  m.DEFAULT = {
    BUFFER_LIMIT: 50,
    BUFFER_FLUSH_LIMIT: 20,
    BATCH_TIMEOUT_MSEC: 5000
  }
  m.SPEC_VERSION = "1.0"
	m.TYPE_FORMAT = CreateObject("roRegex", "[A-Za-z0-9_-]{1,20}(\/[A-Za-z0-9_-]{1,20})?$", "i")
  m.DEFAULT_CAT = "user"

  m.clientId = arguments.clientId
  m.gateway = arguments.gateway
  m.config = arguments.config
  m.opt = applyDefaults(arguments.options)


	m.buffer = CreateObject("roArray", 0, true)
	m.timer = invalid
	m.on = true
end function

function track(eventType as dynamic, data as dynamic, state as dynamic) as void
	' make sure not to track when there's no context to track against
	if (isInvalid(eventType) or isInvalid(data) or isInvalid(state) or m.config.userTracking = false or m.TYPE_FORMAT.IsMatch(eventType) = false) then return

	' if no category present then assume only action and
	' apply the default category
	if (eventType.Instr("/") = -1) then eventType = m.DEFAULT_CAT + "/" + eventType

	' associate current user to event
	data.uid = ifElse(state.anonymous, state.anonId, state.userId)

	event = envelope(eventType, data)
  m.top.eventTracked = event.type
	add(event)
	checkFlush()
end function

function enabled(on as boolean)
	m.on = on
	if (on) then
		checkFlush()
	else
		clearTimer()
	end if
end function

function clearTimer()
	if isValid(m.timer) then
    m.timer.control = "stop"
    m.timer.unobserveField("fire")
    m.timer = invalid
  end if
end function

function add(e as object)
	m.buffer.push(e)
	' if for some reason we haven't been able to flush and
	' we hit a max cap, start discarding older events from the buffer
	if (m.buffer.Count() > m.DEFAULT.BUFFER_LIMIT) then
		m.buffer.Shift()
	end if
end function

function removeEvents(eventType)
  buffer = CreateObject("roArray", 0, true)
	for each e in m.buffer
	  if e.type <> eventType then buffer.push(e)
	end for
	m.buffer = buffer
end function

function checkFlush() as void
	if (m.buffer.Count() = 0) then return
	if (m.buffer.Count() >= m.opt.flushLimit) then
		flush()
	else if (isInvalid(m.timer)) then
		m.timer = createObject("roSGNode", "Timer")
    m.timer.observeFieldScoped("fire", "MTAnalytics_onTimer")
    m.timer.setFields({
        duration : m.opt.batchTimeoutMsec/1000
        repeat : false
    })
    m.timer.control = "start"
	end if
end function

function MTAnalytics_onTimer()
	flush()
end function

function flush() as integer
	clearTimer()

	' if `on` is false, we don't empty the buffer as we may
	' just be offline temporarily so can try again when online
	if (m.on = false or m.buffer.Count() = 0) then
		return 0
	end if

	events = m.buffer
	m.buffer = CreateObject("roArray", 0, true)

	if (toBoolean(m.config.userTracking) = false) then
		return 0
	end if

	bundle = {
		v: m.SPEC_VERSION,
		src: SDKConstants().SOURCE,
		cid: m.clientId,
		wsv: 0, ' TODO: Provide workspace version once we have a consistent value
		ev: events,
		sa: createObject("roDateTime").toISOString()
	}
	m.gateway.sendEvents = bundle

	return events.Count()
end function

function applyDefaults(options as object) as object
	opt = {}
  if (isValid(options)) then opt.append(options)

	if (NOT isInteger(opt.batchTimeoutMsec) or opt.batchTimeoutMsec < 1000) then
		opt.batchTimeoutMsec = m.DEFAULT.BATCH_TIMEOUT_MSEC
	end if
	if (NOT isInteger(opt.flushLimit) or opt.flushLimit < 3 or opt.flushLimit > m.DEFAULT.BUFFER_LIMIT) then
		opt.flushLimit = m.DEFAULT.BUFFER_FLUSH_LIMIT
	end if
	return opt
end function

function envelope(eventType as string, data as object) as object
	if (type(eventType) = "<uninitialized>" or eventType = invalid or GetInterface(eventType, "ifString") = invalid) then
		eventType = ""
	end if
	result = {}
	result["id"] = CreateObject("roDeviceInfo").GetRandomUUID()
	result["type"] = LCase(eventType)
	result["time"] = createObject("roDateTime").toISOString()
	result["data"] = data
	return result
end function
