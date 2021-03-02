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
  setupInitialUI()

  m.top.observeFieldScoped("focusedChild", "onFocused")
  m.header.setFocus(true)
  render()

  m.FAKE_USER = {
    id: "2id2f459d2s5"'",
    name: "Olivia",
    subscription: "gold"
    email: "rokuUser@gmail.com"
  }
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

function onLogout()
  render()
end function

function onLogin()
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
  onLogout()
end function

function logIn()
  m.authRequestInProgress = true
  onFocused()
  onLogin()
end function

function render(user = invalid as dynamic)
  renderHeader(user)
  renderBody(user)
  onFocused()
end function

function renderHeader(user)
  if user <> invalid then
    m.authButtonLabel.text = "Sign-out"
    m.userName.text = user.name
    color = "0xCF20BFFF"

    m.authRequestInProgress = false
    m.isSignedIn = true
  else
    m.authButtonLabel.text = "Sign-in"
    m.userName.text = ""
    color = "0x6F58C4FF"

    m.authRequestInProgress = false
    m.isSignedIn = false
  end if

  m.header.color = color
end function

function renderBody(user)
  if user <> invalid then
    m.hero.uri = "https://pkw.us.astcdn.com/img/sample/2=x700.jpg"
    m.joinNowButtonLabel.text = "Member"
  else
    m.hero.uri = "https://pkw.us.astcdn.com/img/sample/1=x700.jpg"
    m.joinNowButtonLabel.text = "Join Now"
  end if
end function
