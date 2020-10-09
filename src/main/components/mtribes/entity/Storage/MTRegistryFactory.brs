function MTRegistryFactory(arguments)
    this = {
        appInfo : CreateObject("roAppInfo")
        registry: CreateObject("roRegistry")
    }
    this.sectionName = this.appInfo.GetID() + "_" + arguments.id
    this.section = createObject("roRegistrySection", this.sectionName)
    this.getItem = function (keyName as string) as object
        dataStr = m.section.read(keyName)
        if isNotEmptyString(dataStr) then return parseJSON(dataStr)
        return invalid
    end function

    this.setItem = function (keyName as string, data as object) as void
        m.section.write(keyName, formatJSON(data))
        m.section.flush()
    end function

    this.removeItem = function (keyName as string) as boolean
        isRemoved = false
        if(m.section.exists(keyName)) then
            isRemoved = m.section.delete(keyName)
            m.section.flush()
        end if
        return isRemoved
    end function

    this.clear = function () as void
        m.registry.delete(m.sectionName)
        m.registry.flush()
    end function

    return this

end function
