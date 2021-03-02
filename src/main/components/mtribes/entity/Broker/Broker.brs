function constructor(arguments=invalid as Object)
    m.nodes = {}
    m.sectionsIds = {}
    m.c = {}
end function

function register(node as object) as void
    if (isInvalid(m.nodes[node.id])) then
        m.nodes[node.id] = CreateObject("roArray", 0, true)
    end if
    m.nodes[node.id].push(node)
    m.sectionsIds[node.id] = node.isSection
end function

function state(id as string, ctx=invalid as object) as object
    if isInvalid(ctx) then ctx = m.top.defaultSession
    return ctx.callFunc("experienceState", id, m.sectionsIds[id])
end function

function defaultState(id as string, ctx=invalid as object) as object
    if isInvalid(ctx) then ctx = m.top.defaultSession
    return ctx.callFunc("defaultExperienceState", id)
end function

function children(id as string, ctx=invalid as object)
    node = m.nodes[id][0]
    emptyArray = CreateObject("roArray", 0, true)
    if (isInvalid(node) or isInvalid(node.childTypes)) then return emptyArray

    if (isInvalid(ctx)) then ctx = m.top.defaultSession

    sectionState = state(id, ctx)
    if (isInvalid(sectionState)) then return emptyArray

    saved = m.c[id]
    ' return previously cached version if no changes to children
    if (isValid(saved) and sectionState.v >= 0 and saved.v = sectionState.v) then
        return saved.c
    end if

    resultChildren = _reduce(ifElse(isNotEmptyArray(sectionState.se), sectionState.se, emptyArray), node)

    ' cache children so we only recreate when they change
    m.c[id] = { v: sectionState.v, c: resultChildren }

    return resultChildren
end function

'function responsible for clearing saved sections when removeSubscribers called in Session.
function removeFromSaved(expId as string) as void
	m.c.delete(expId)
end function

function isNotEmptySpace()
    return m.nodes.count()> 0
end function

'this is a replacement of _ScopeSignaller.emit logic in ts. This function is responsible for update of each Experience
'state of what was changed according to latest Gateway response. This logic is placed inside Broker, because only
'Broker contains info about all Experiences in code, what is required for execution of this logic.
function updateNodeStateById(child as object, ctx=invalid as object) as void
  if (isValid(m.nodes[child.source])) then
    for each node in m.nodes[child.source]
      if node.target.isSubtype("MTExperience")  then
        node.target.changed = {
          eventType : child.eventType
          source : child.source
        }
      else if node.target.isSubtype("MTSection")   then
        event = {
          eventType : child.eventType
          source : child.source
          children : children(child.source, ctx)
        }
        node.target.changed = event
        node.target.children = event.children
      end if
    end for
  end if
end function

function track(id as string, eventType as string, details={} as object, ctx=invalid as object)
    if (isInvalid(ctx)) then ctx = m.top.defaultSession
    ctx.callFunc("track", id, eventType, details)
end function

function template(id as string) as object
    nodesArray = m.nodes[id]
    if (isArray(nodesArray) and nodesArray.count() > 0) then
        return nodesArray[0].template
    end if
    return invalid
end function

'private

function _reduce(se as object, node as object) as object
    acc = CreateObject("roArray", 0, true)
    for each entry in se
        experience = _createExperience(entry, node)
        ' In future we may support a fallback Experience type if unknown
        ' but for now we strip these experiences out to avoid any potential
        ' runtime issues for clients
        if (isValid(experience)) then acc.push(experience)
    end for
    return acc
end function

function _createExperience(entry as object, parent as object)
    ExperienceType = parent.childTypes[entry.et]
    if (isInvalid(ExperienceType)) then
        return invalid
    end if

    return createMtribesNode(ExperienceType, {id: entry.id, parentId: parent.id, broker: m.top})
end function
