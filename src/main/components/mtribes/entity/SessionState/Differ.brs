function diffStates(locked as object, oldStates as object, newStates as object, fallbacks as object) as object
    if (isInvalid(oldStates) or isEmptyObject(oldStates)) oldStates = fallbacks
    if (isInvalid(newStates)) newStates = {}

    newIds = getNewIds(newStates)
    changes = {}

    for each id in oldStates
        ' if in the lock cache then it can't change so skip it
        if (isValid(locked.callFunc("getItem", id)))
            newIds.delete(id)
        else
            sOld = ifElse(isValid(oldStates[id]), oldStates[id], fallbacks[id])
            sNew = newStates[id]
            state = ifElse(isValid(sNew), sNew, sOld)

            if (isInvalid(sNew)) then
                recordChange(changes, { source: id, eventType: "remove" }, state)
            else
                if (sOld.v <> sNew.v)
                    recordChange(changes, { source: id, eventType: "update" }, state)
                end if
                newIds.delete(id)
            end if
        end if
    end for

    for each id in newIds
        recordChange(changes, { source: id, eventType: "add" }, newStates[id])
    end for

    changeset = []
    for each c in changes
        changeset.push(changes[c])
    end for
    return changeset
end function

function recordChange(changes as object, change as object, state as object)
    existing = changes[change.source]
    if (toBoolean(existing)) change.children = existing.children
    changes[change.source] = change

    if (isInvalid(state) or isInvalid(state.pid)) return change

    pid = state.pid
    sParent = changes[pid]
    if (isInvalid(sParent)) then
        changes[pid] = {
            source: pid,
            eventType: "update",
            children: []
        }
        sParent = changes[pid]
    else if (isInvalid(sParent.children))
        sParent.children = []
    end if
    sParent.children.push(change)
    return change
end function

function getNewIds(newStates as object) as object
    ids = {}
    for each id in newStates
        ids[id] = true
    end for
    return ids
end function
