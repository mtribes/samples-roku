function init() as Void
  m.top.backgroundURI = ""
  m.top.backgroundColor = "0xffffffff"


  m.homePage = m.top.findNode("header")
  m.header = m.top.findNode("header")
  m.banner = m.top.findNode("banner")
  m.hero = m.top.findNode("hero")

  m.authButton = m.top.findNode("authButton")
  m.authButtonLabel = m.top.findNode("authButtonLabel")
  m.joinNowButton = m.top.findNode("joinNowButton")
  m.joinNowButtonLabel = m.top.findNode("joinNowButtonLabel")
  m.logo = m.top.findNode("logo")
  m.userName = m.top.findNode("userName")

  m.authRequestInProgress = false
  m.isSignedIn = false

  m.userName.visible = false

  initMtribes()
  m.global.mtribes.collections.homepage.header.observeFieldScoped("changed", "onHeaderChanged")
  m.global.mtribes.collections.homepage.body.observeFieldScoped("changed", "onBodyChanged")
  setupInitialUI()

  m.top.observeFieldScoped("focusedChild", "onFocused")
  m.header.setFocus(true)

  m.FAKE_USER = {
    id: "2id2f459d2s5"'",
    name: "Olivia",
    subscription: "gold"
    email: "rokuUser@gmail.com"
  }
  logOut()
end function

function onFocused()
  if m.authRequestInProgress then
    m.authButton.setFields(m.authButton.disabled)
    m.joinNowButton.setFields(m.joinNowButton.disabled)
  else
    if m.header.isSameNode(m.top.focusedChild) then
      m.authButton.setFields(m.authButton.focused)
    else
      m.authButton.setFields(m.authButton.unfocused)
    end if
    if m.banner.isSameNode(m.top.focusedChild) then
      m.joinNowButton.setFields(m.joinNowButton.focused)
    else
      m.joinNowButton.setFields(m.joinNowButton.unfocused)
    end if
  end if
end function

function onHeaderChanged(message)
  if m.global.mtribes.session.anonymous then
    renderHeader()
  else
    renderHeader(m.FAKE_USER)
  end if
end function

function onBodyChanged(message)
  if m.global.mtribes.session.anonymous then
    renderBody()
  else
    renderBody(m.FAKE_USER)
  end if
end function

function onLogout(event)
  m.isSignedIn = false
  render()
end function

function onLogin(event)
  m.isSignedIn = true
  render(m.FAKE_USER)
end function

function onKeyEvent(key as string, press as boolean) as boolean
  if press then
    key = LCase(key)
    if key = "up" then
      m.header.setFocus(true)
    else if key = "down" then
      m.banner.setFocus(true)
    else if key = "ok" then
      if m.header.isSameNode(m.top.focusedChild) then
        if NOT m.authRequestInProgress then
          if m.isSignedIn then
            logOut()
          else
            logIn()
          end if
        end if
      end if
    end if
  end if
  return true
end function

function logOut()
  m.authRequestInProgress = true
  onFocused()
  m.global.mtribes.session.callFunc("start").observeFieldScoped("result", "onLogout")
end function

function logIn()
  m.authRequestInProgress = true
  onFocused()
  m.global.mtribes.session.callFunc("start", {
    userId: m.FAKE_USER.id,
    fields: {subscription: m.FAKE_USER.subscription}
  }).observeFieldScoped("result", "onLogin")
end function

function render(user = invalid as dynamic)
  renderHeader(user)
  renderBody(user)
  onFocused()
end function

function renderHeader(user = invalid as dynamic)
  if user <> invalid then
    m.authButtonLabel.text = "Sign-out"
    m.userName.visible = true
    m.userName.text = user.name

    m.authRequestInProgress = false
  else
    m.authButtonLabel.text = "Sign-in"
    m.userName.visible = false
    m.userName.text = ""

    m.authRequestInProgress = false
  end if
  m.header.color = m.global.mtribes.collections.homepage.header.callFunc("data").backgroundColor
end function

function renderBody(user = invalid as dynamic)
  body = m.global.mtribes.collections.homepage.body
  bodyChildren = body.children
  supported = body.supported
  ' render each Experience of the Section in order
  for i = 0 to bodyChildren.count() - 1
    exp = bodyChildren[i]
    if exp.isSubtype(supported.Hero) then
      m.hero.uri = exp.callFunc("data").source
    else if exp.isSubtype(supported.Banner) then
      m.joinNowButtonLabel.text = exp.callFunc("data").label
      end if
  end for
end function

function initMtribes()
  createObject("roSGNode", "mtribes")
  client = m.global.mtribes.client
  client.setFields({
    waitForMsec : 5000
    sessionLock : false
    logLevel : 2
  })
end function
