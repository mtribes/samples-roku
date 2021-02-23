function LoggerLogic()
    if m.logger = invalid then
        this = {
            logLevels: {
                error: 0
                warn: 1
                info: 2
            }
            logLevel: -1
            setLogLevel: function (logLevel)
                m.logLevel = logLevel
            end function

            error: function (msg)
                if m.logLevel >= m.logLevels.error
                    print "ERROR ";tab(20);msg
                end if
            end function

            info: function (msg)
                if m.logLevel >= m.logLevels.info
                    print "INFO ";tab(20);msg
                end if
            end function

            warn: function (msg)
                if m.logLevel >= m.logLevels.warn
                    print "WARN ";tab(20);msg
                end if
            end function
        }
        m.logger = this
        return this
    else
        return m.logger
    end if
end function
