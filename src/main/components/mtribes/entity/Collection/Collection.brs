function baseConstructor(arguments as Object)
    m.top.id = arguments.id
    m.id = arguments.id
    m.broker = arguments.broker
    m.template = arguments.template

    m.broker.callFunc("register", {id: m.id, template: m.template, target: m.top})
end function
