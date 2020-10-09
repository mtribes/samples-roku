'request factory - responsible for executing of request and for retry logic if it fails
function requestFactory (config as object, messagePort as object)
  this = {
    config: config,
    urlTransfer: createObject("roUrlTransfer"),
    messagePort: messagePort,
    retryObj: {}
    retryTimespan: createObject("roTimeSpan")

    post: function(path as string, params as object, data as object, opt as object) as void
      qp = CreateObject("roArray", 0, true)
      qpItem ="k=" + m.config.apiKey
      qp.push(qpItem)
      if (isNotEmptyObject(params)) then
        for each k in params
          qpItem = k.toStr() + "=" + params[k].toStr().EncodeUri()
          qp.push(qpItem)
        end for
        qp.sort()
      end if
      m.execPost(path, qp.join("&"), data, opt)
    end function

    execPost: function(path as string, query as string, data, opt as object)
      key = opt.key
      m.retryObj.opt = opt
      m.retryObj.path = path
      m.retryObj.query = query
      m.retryObj.data = data

      url = m.config.serviceUrl + "" + path + "?" + query
      postString = FormatJSON(data)
      m.config.log.info("------------------------------------------------------")
      m.config.log.info("url = "+url)
      m.config.log.info("postString = "+postString)
      m.config.log.info("------------------------------------------------------")
      m.urlTransfer.setPort(m.messagePort)
      m.urlTransfer.setCertificatesFile("common:/certs/ca-bundle.crt")
      m.urlTransfer.initClientCertificates()
      m.urlTransfer.addHeader("Content-Type", "text/plain")
      m.urlTransfer.addHeader("Accept", "application/json")
      m.urlTransfer.setURL(url)
      m.urlTransfer.asyncPostFromString(postString)
    end function

    'retry attempt neediness checking and delay calculation
    checkRetry: function()
      if m.retryObj.opt.retries > 0 then
        jitter = Int(RND(0) * m.retryObj.opt.delayMsec)
        delayMsec = m.retryObj.opt.delayMsec + int(jitter/2)
        m.retryTimespan.mark()
        m.retryObj.opt.retries--
        return {timeSpan: m.retryTimespan, delayMsec: delayMsec}
      end if
      return invalid
    end function

    'execution of retry call
    execRetry: function() as void
      m.urlTransfer = createObject("roUrlTransfer")
      m.execPost(m.retryObj.path, m.retryObj.query, m.retryObj.data, m.retryObj.opt)
    end function

    getIdentity: function()
      return m.urlTransfer.getIdentity()
    end function

    cancelPost: function(fakeMessagePort)
      m.urlTransfer.setMessagePort(fakeMessagePort)
      m.urlTransfer.asyncCancel()
    end function
  }

  return this
end function
