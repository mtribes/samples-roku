function constructor(arguments = {} as Object)
    m.messagePort = createObject("roMessagePort")
    m.top.id = arguments.id
    if isValid(arguments.config) then m.config = arguments.config else m.config = {}
    m.top.observeFieldScoped("config", m.messagePort)
    m.top.observeFieldScoped("logLevel", m.messagePort)
    m.top.observeFieldScoped("loadStates", m.messagePort)
    m.top.observeFieldScoped("cancelRequestWithId", m.messagePort)
    m.top.observeFieldScoped("sendEvents", m.messagePort)
    m.top.functionName = "mtTaskThread"
    m.top.control = "RUN"
end function

function mtTaskThread() as Void
    m.initialized = false
    m.logger = LoggerLogic()
    if isNotEmptyObject(m.config) then m.gatewayLogic = initialize(m.config)
    msg = m.messagePort.getMessage()
    while msg <> invalid
        processLoop(msg)
        msg = m.messagePort.getMessage()
    end while
    while (true)
        msg = wait(1000, m.messagePort)
        processLoop(msg)
    end while
end function

function processLoop(msg)
    if m.initialized then
        m.gatewayLogic.handleMessage(msg)
        if type(msg) = "roSGNodeEvent" then
            field = msg.getField()
            if field = "loadStates" then
                params = msg.getData()
                m.gatewayLogic.loadStates(params.req, params.query, params.promise, params.reqId)
            else if field = "cancelRequestWithId" then
                m.gatewayLogic.cancelRequestWithId( msg.getData())
            else if field = "sendEvents" then
                bundle = msg.getData()
                m.gatewayLogic.sendEvents(bundle)
            else if field = "config" then
                config = msg.getData()
                for each field in config
                    m.config[field] = config[field]
                end for
                m.config.log.setLogLevel(config.logLevel)
            else if field = "logLevel" then
                logLevel = msg.getData()
                m.config.logLevel = logLevel
                m.logger.setLogLevel(logLevel)
            end if
        end if
    else if type(msg) = "roSGNodeEvent" AND msg.getField() = "config" then
        m.gatewayLogic = initialize(msg.getData())
    end if
end function

function initialize(config)
    m.initialized = true
    for each field in config
        m.config[field] = config[field]
    end for
    m.logger.info("Gateway -> mtTaskThread(... config = " + toString(config))
    config.log = m.logger
    config.log.setLogLevel(m.config.logLevel)
    return MTGatewayLogic(m.config, m.messagePort)
end function
