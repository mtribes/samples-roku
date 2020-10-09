function baseConstructor(arguments as Object)
  m.id = arguments.id
  m.parentId = arguments.parentId
  m.broker = arguments.broker
  m.template = arguments.template

  m.broker.callFunc("register", {id: m.id, parentId: m.parentId, template: m.template, target: m.top})
  m.defaultState = m.broker.callFunc("defaultState", m.id)

  m.top.setFields({
    defaultData : m.defaultState.data
    enabled : m.defaultState.on = true
    data : m.defaultState.data
    id : arguments.id
  })
end function

function data()
  return m.broker.callFunc("state", m.id).data
end function

function scenarioId()
  return m.broker.callFunc("state", m.id).sid
end function

function enabled()
  return m.broker.callFunc("state", m.id).on = true
end function

function track(eventType as String, details={} as Object) as Void
  m.broker.callFunc("track", m.id, eventType, details)
end function
