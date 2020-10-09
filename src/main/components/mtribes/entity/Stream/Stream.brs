function connect()
  m.top.enable = true
end function

function disconnect()
  m.top.enable = false
end function

function constructor(arguments = {} as Object)
  m.messagePort = createObject("roMessagePort")
  m.top.id = arguments.id
  if isValid(arguments.config) then m.config = arguments.config else m.config = {}
  m.top.observeFieldScoped("enable", m.messagePort)
  m.top.observeFieldScoped("logLevel", m.messagePort)
  m.top.observeFieldScoped("config", m.messagePort)
  m.top.observeFieldScoped("autoUpdate", m.messagePort)
  m.top.functionName = "processStream"
  m.top.control = "RUN"
end function

function processStream()
  m.logger = loggerLogic()
  m.callbacks = {
    disconnected: function()
      disconnected()
    end function

    connected: function()
      connected()
    end function

    newMessage: function(message)
      newMessage(message)
    end function
  }

  m.attempts = 0
  m._PING_RATE_MSEC = 58000
  m._SHORT_RETRY_WAIT_MSEC = 1000
  m._LONG_RETRY_WAIT_MSEC = 4 * 60 * 1000
  m.waitForNewConnectionMode = false
  m.newConnectionDelay = 0
  m.newConnectionTimer = createObject("roTimeSpan")
  m.pingTimer = createObject("roTimeSpan")

  if isNotEmptyObject(m.config) then m.streamInstance = initialize(m.config)
  msg = m.messagePort.getMessage()
  while msg <> invalid
    processLoop(msg)
    msg = m.messagePort.getMessage()
  end while
  while true
    msg = wait(1000, m.messagePort)
    processLoop(msg)
  end while

end function

function processLoop(msg)
  if m.initialized then
    if type(msg) = "roSGNodeEvent" then
      field = msg.getField()
      if field = "logLevel" then
        logLevel = msg.getData()
        m.logger.setLogLevel(logLevel)
        m.config.logLevel = logLevel
      else if field = "autoUpdate" then
        m.config.autoUpdate = msg.getData()
      else if field = "config" then
        initialize(msg.getData())
      else if field = "enable" AND NOT msg.getData() AND isValid(m.streamInstance) then
        m.streamInstance.disconnect()
        m.streamInstance = invalid
        m.attempts = 0
        m.waitForNewConnectionMode = false
      else if field = "enable" AND msg.getData() AND isInvalid(m.streamInstance) AND m.config.autoUpdate = true then
        initialize(m.config)
        m.pingTimer.mark()
        m.streamInstance = MTStreamFactory(m.config, m.messagePort, m.callbacks)
        m.streamInstance.start()
        m.waitForNewConnectionMode = false
      end if
    else if type(msg) = "roAssociativeArray"
      if msg.id = "on_open"
        connected()
      else if msg.id = "on_close"
        disconnected()
      else if msg.id = "on_message"
        m.streamInstance.processMessage(msg.data.message)
      else if msg.id = "on_error"
'        m.top.on_error = msg.data
      else if msg.id = "ready_state"
      end if
    end if

    if m.waitForNewConnectionMode AND m.newConnectionTimer.totalMilliseconds() > m.newConnectionDelay
      initialize(m.config)
      m.streamInstance = MTStreamFactory(m.config, m.messagePort, m.callbacks)
      m.streamInstance.start()
      m.waitForNewConnectionMode = false
    end if

    if isValid(m.streamInstance) then m.streamInstance.handleMessage(msg)
    if m.pingTimer.totalMilliseconds() > m._PING_RATE_MSEC then ping()

  else if type(msg) = "roSGNodeEvent" AND msg.getField() = "config" then
    initialize(msg.getData())
  end if
end function

function ping()
  if isValid(m.streamInstance) then
    m.pingTimer.mark()
    m.streamInstance.sendMessage({op: "p", body: invalid})
  end if
end function

function disconnected()
  m.streamInstance = invalid
  m.newConnectionTimer.mark()
  m.pingTimer.mark()

  m.attempts++
  m.newConnectionDelay = m._SHORT_RETRY_WAIT_MSEC
  if m.attempts > 2 then m.delay = m._LONG_RETRY_WAIT_MSEC
  m.waitForNewConnectionMode = true

  m.top.setFields({
    onStatus: "disconnected"
    active: false
  })
end function

function connected()
  m.attempts = 0
  m.pingTimer.mark()
  m.waitForNewConnectionMode = false

  m.top.setFields({
    onStatus: "connected"
    active: true
  })
end function

function newMessage(message)
  m.top.onMessage = message
end function

function initialize(config)
  m.initialized = true
  for each field in config
    m.config[field] = config[field]
  end for
  if isValid(m.streamInstance) then
    m.streamInstance.disconnect()
    if m.config.autoUpdate then
      m.streamInstance = MTStreamFactory(m.config, m.messagePort, m.callbacks)
      m.streamInstance.start()
    end if
  end if
  config.log = m.logger
  config.log.setLogLevel(m.config.logLevel)
end function
