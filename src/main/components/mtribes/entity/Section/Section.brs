function baseConstructor(arguments as Object)
    m.top.id = arguments.id
    m.id = arguments.id
    m.parentId = arguments.parentId
    m.broker = arguments.broker
    m.childTypes = arguments.childTypes
    m.template = arguments.template
    m.broker.callFunc("register", {id: m.id,  parentId: m.parentId, template: m.template, childTypes: m.childTypes, target: m.top, isSection: true})

    m.top.children = m.broker.callFunc("children", m.id)
end function

