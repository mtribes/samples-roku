function constructor(arguments={} as Object)
    m.config = arguments.config
    m.loggerLogic = LoggerLogic()
    m.loggerLogic.setLogLevel(arguments.logLevel)
    m.config.observeFieldScoped("logLevel", "setLoglevel")
end function

function warn(msg = invalid as dynamic)
    m.loggerLogic.warn(msg)
end function

function error(msg = invalid as dynamic)
    m.loggerLogic.error(msg)
end function

function info(msg = invalid as dynamic)
    m.loggerLogic.info(msg)
end function

function setLoglevel(msg as object)
    m.loggerLogic.setLoglevel(msg.getData())
end function
