
'handling requests and responses logic
function MTGatewayLogic(config as object, messagePort as object) as object
  this = {
    fakeMessagePort: createObject("roMessagePort")
    config: config
    messagePort: messagePort
    MAX_RETRY: 2,
    DELAY_MSEC: 1000,
    analyticsRequests: {}
    promiseStatus: MTPromiseStatus()

    handleMessage: function(message=invalid as Dynamic) as Boolean
      if type(message) = "roUrlEvent" then
        transferId = message.getSourceIdentity()

        if isValid(m.statesTransfer) AND m.statesTransfer.getIdentity() = transferId then
          m.handleStatesTransferMessage(message)
          return true
        else if isValid(m.analyticsRequests[transferId.toStr()]) then
          m.analyticsRequests.delete(transferId.toStr())
          return true
        end if
      else if isValid(m.retryObj) AND isValid(m.statesTransfer) then
        if m.retryObj.timeSpan.totalMilliseconds() >= m.retryObj.delayMsec then
          m.statesTransfer.execRetry()
          m.retryObj = invalid
        end if
      end if

      return false
    end function

    handleStatesTransferMessage: function(message) as void
      responseCode = message.getResponseCode()
      if responseCode < 200 OR responseCode > 300 then
        m.retryObj = m.statesTransfer.checkRetry()
        if isInvalid(m.retryObj) then
          m.promise.result = {
            status: m.promiseStatus.error
            error: message.getString()
            reqId: m.reqId
          }
          m.statesTransfer = invalid
          m.retryObj = invalid
        end if
      else
        responseString = message.getString()
        responseObject = parseJSON(responseString)
        m.promise.result = {
          status: m.promiseStatus.success
          data: responseObject
          reqId: m.reqId
        }
        m.statesTransfer = invalid
        m.retryObj = invalid
      end if
    end function

    loadStates: function(req as object, params as object, promise as object, reqId as string)
      if isValid(m.statesTransfer) then
        m.statesTransfer.cancelPost(m.fakeMessagePort)
        m.retryObj = invalid
      end if

      'requests results for state update will be applied to promise.result field.
      'Promise is generated inside Primer. It is not real promise-pattern, it mostly some-kind of
      '"bridge" between task and render thread, that allows more flexibly use request results execution.
      m.promise = promise
      m.reqId = reqId
      m.statesTransfer = requestFactory(m.config, m.messagePort)
      opt = { key: "exp", retries: m.MAX_RETRY, delayMsec: m.DELAY_MSEC }
      m.statesTransfer.post("/ex/states", params, req, opt)
    end function

    cancelRequestWithId: function(reqId)
      if m.reqId = reqId then
        m.statesTransfer.cancelPost(m.fakeMessagePort)
        m.statesTransfer = invalid
        m.retryObj = invalid
        m.reqId = invalid
        m.promise = invalid
      end if
    end function

    sendEvents: function(bundle as object)
      opt = { retries: m.MAX_RETRY, delayMsec: m.DELAY_MSEC }

      analyticsTransfer = requestFactory(m.config, m.messagePort)
      transferId = analyticsTransfer.getIdentity()
      m.analyticsRequests[transferId.toStr()] = analyticsTransfer
      analyticsTransfer.post("/ev/batch", "", bundle, opt)
    end function
  }

  return this
end function
