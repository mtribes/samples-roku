function constructor(arguments as Object)
    m.clientId = arguments.clientId
    m.gateway = arguments.gateway
    m.config = arguments.config
    m.broker = arguments.broker

    m.timer = createObject("roSGNode", "Timer")
    m.timer.observeFieldScoped("fire", "onTimer")
    m.timer.setFields({
        repeat : false
    })
    m.SDKConstants = SDKConstants()
end function

'public
function prime(state as object, headers as object) as void
    m.state = state
    m.promise = createObject("roSGNode", "MTPromise")
    m.loadStartId = state.callFunc("loadStart", m.promise)
    waitForMsec = ifElse(isInteger(m.config.waitForMsec), m.config.waitForMsec, 0)

    if (headers.op = "an" or headers.op = "id") then
        m.timer.control = "stop"
        m.timer.duration = waitForMsec/1000
        m.timer.control = "start"
    end if

    fields = m.state.fields
    req = {
        user: {
            id: ifElse(m.state.anonymous, m.state.anonId, m.state.userId),
            anonymous: m.state.anonymous,
            fields: ifElse(isNotEmptyObject(fields), fields, {})
        }
    }

    req.header = headers
    req.header.cid = m.clientId
    req.header.src = m.SDKConstants.SOURCE

    query = {
        src: m.SDKConstants.SOURCE.mid(m.SDKConstants.SOURCE.instr("/") + 1),
        an: ifElse(req.user.anonymous, 1, 0)
    }

    if (toBoolean(query.an) = false and isString(m.state.sig)) then
        query.uid = req.user.id
        query.sig = m.state.sig
    end if

    if (headers.op = "id" and isString(m.state.anonId)) then
        req.header.aid = m.state.anonId
    end if

    lastStatesVersion = m.state.callFunc("lastStatesVersion")
    if (isString(lastStatesVersion)) then
        req.header.v = lastStatesVersion.toInt()
    end if
    m.promise.observeFieldScoped("result", "onPromiseFinished")
    m.gateway.loadStates = {
        req: req
        query: query
        promise: m.promise
        reqId: m.loadStartId
    }
end function

'callbacks
function onPromiseFinished()
    m.timer.control = "stop"
    m.promise.unObserveFieldScoped("result")
    m.promise = invalid
end function

function onTimer()
    if isValid(m.state) then m.state.callFunc("waitElapsed", m.loadStartId)
end function

