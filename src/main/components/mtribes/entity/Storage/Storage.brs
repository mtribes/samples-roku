function constructor(arguments as Object)
    m.mem = {}
    m.ns = arguments.ns
    m.storageType = arguments.storageType
    m.top.storageType = arguments.storageType
    m.store = getStorage(arguments.storageType)
    m.secure = m.top.secure

    m.top.observeFieldScoped("storageType", "setStorageType")
    m.top.observeFieldScoped("secure", "setSecure")
end function

'public
function getItem(key as string) as object
    if (m.storageType = "none") then return invalid
    if (m.mem[key] <> invalid) then return m.mem[key]
    if (m.store = invalid) then return invalid
    m.mem[key] = m.store.getItem(m.ns + key)
    return m.mem[key]
end function

function removeItem(key as string) as void
    if (m.storageType = "none") then return
    m.mem.delete(key)
    if (isValid(m.store)) then m.store.removeItem(m.ns + key)
end function

function setItem(key as string, value as object) as void
    if (m.storageType = "none") then return
    m.mem[key] = value
    if (m.store = invalid or m.secure = false) then return

    m.store.setItem(m.ns + key, value)
end function

function clear() as void
    if (m.storageType = "none") then return
    m.mem = {}
    if (isObject(m.store)) then m.store.clear()
end function

'callback
function setStorageType(message as object) as void
    m.storageType = message.getData()
    t = m.storageType
    m.store = getStorage(t)
    oldMem = m.mem
    m.mem = {}
    'copy over values added in prev store type
    for each k in oldMem
        setItem(k, oldMem[k])
    end for
end function

function setSecure(message as object) as void
    m.secure = message.getData()
end function

'private
function getStorage(kind as string) as object
    if (kind = "local") then return MTRegistryFactory({id: "MTLocalRegistry"})
    return invalid
end function
