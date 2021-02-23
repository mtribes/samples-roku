function init()
  m.top.setFields({
    duration: 0.01
    repeat: false
  })
  m.top.observeFieldScoped("fire", "onFire")
end function

'public
function resolve(result)
  m.result = result
  m.top.control = "start"
end function

'callbacks
function onFire()
  m.top.result = m.result
end function
