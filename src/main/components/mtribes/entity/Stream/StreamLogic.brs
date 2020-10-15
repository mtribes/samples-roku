
function MTStreamFactory(config as Object, messagePort as Object, callbacks) as Object

  this = {
    config: config
    messagePort: messagePort
    fakePort: createObject("roMessagePort")
    streamExpiringTime: 300
    maxFrameSize: 1024
    socketReadSize: 1024
    isHandshakeFinished: false
    callbacks: callbacks
    headerDelimiterCode: 35
    notHandledMessages: []
    notHandledBytes: createObject("roByteArray")
    ws: WebSocketClient()

    start: function() as Void
      resource = m.config.serviceUrl + "/ws/tk?k=" + m.config.apiKey
      m.config.log.info("Establishing stream pre-handshake: " + resource)
      m.handshakeTransfer = createObject("roUrlTransfer")
      m.handshakeTransfer.setMessagePort(m.messagePort)
      m.handshakeTransfer.setCertificatesFile("common:/certs/ca-bundle.crt")
      m.handshakeTransfer.initClientCertificates()
      m.handshakeTransfer.addHeader("Content-Type", "application/json")
      m.handshakeTransfer.setURL(resource)
      m.handshakeTransfer.asyncGetToString()
    end function

    handleMessage: function(message as Dynamic) as Boolean
      if type(message) = "roUrlEvent" AND isValid(m.handshakeTransfer) then
        if message.getSourceIdentity() = m.handshakeTransfer.getIdentity() then
          handled = m._handleHandshake(message)
          if handled then
            m.ws.set_message_port(m.messagePort)
            m.config.log.info("Establishing ws connection: " + m.wsURL)
            m.ws.secret = m.secret
            m.ws.open(m.wsURL)
          else
            m.disconnect()
          end if
          return true
        end if
      end if
      m.ws.run()
      return false
    end function

    processMessage: function(messageText) as Void
      parsedData = parseJSON(messageText)
      incomingHash = parsedData.sig
      parsedData.delete("sig")
      if m.ws._calcHMAC(FormatJSON(parsedData.body)) = incomingHash then
        if isNotEmptyObject(parsedData) AND parsedData.op <> "p" then
          if isInvalid(parsedData.body) then parsedData.body = {}
          m.callbacks.newMessage(parsedData)
          m.config.log.info("New stream message received: " + FormatJSON(parsedData))
        end if
      else
        m.disconnect()
      end if
    end function

    disconnect: function() as Void
      if isValid(m.handshakeTransfer) then
        m.handshakeTransfer.asyncCancel()
        m.handshakeTransfer = invalid
      end if
      if isValid(m.ws) then
        m.config.log.info("WS connection stopped")
        m.ws.close([1000, "Client closing"])
      end if
    end function

    sendMessage: function(message as object) as Void
      m.ws.send(message)
    end function

    _handleHandshake: function(message as Dynamic) as boolean
      code = message.getResponseCode()
      responseData = ""

      m.handshakeTransfer.setMessagePort(m.fakePort)
      m.handshakeTransfer.asyncCancel()
      m.handshakeTransfer = invalid

      if code >= 200 AND code <= 300 then
        responseData = parseJSON(message.getString())
        if isInvalid(responseData) then
          m.config.log.error("pre-handshake: failed json decoding")
          return false
        else if isEmptyObject(responseData) then
          m.config.log.error("pre-handshake: empty response")
          return false
        end if
      else if code = 401 OR code = 403 then
        m.config.log.error("pre-handshake: not authorized")
        return false
      else if code = 404 then
        m.config.log.error("pre-handshake: endpoint not found")
        return false
      else
        m.config.log.error("pre-handshake: failed")
        return false
      end if
      m.wsURL = responseData.url
      m.secret = CreateObject("roByteArray")
      m.secret.fromAsciiString(responseData.secret)

      return true
    end function
  }

  return this
end function
