function setupInitialUI()

  scene = m.global.getScene()
  UIResolution = scene.currentDesignResolution
  divider = 1
  screenSize = {
    h: UIResolution.height
    w: UIResolution.width
  }

  if LCase(uiResolution.resolution) = "hd" then
    divider = 1.5
  else if LCase(uiResolution.resolution) = "sd" then
    divider = 2.25
  end if

  buttonFocusedHeight = int(38/divider)
  buttonUnfocusedHeight = int(32/divider)
  headerHeight = int(56/divider)
  bannerHeight = int(80/divider)
  heroHeight = int(500/divider)
  authButtonFocusedWidth = int(92/divider)
  authButtonUnfocusedWidth = int(86/divider)
  joinButtonFocusedWidth = int(92/divider)
  joinButtonUnfocusedWidth = int(86/divider)

  m.authButton.setFields({
    focused: {
      uri: "pkg:/images/authButtonFocused.png"
      translation: [screenSize.w - int(16/divider) + 3 - authButtonFocusedWidth, (headerHeight - buttonFocusedHeight)/2]
      height: buttonFocusedHeight
      width: joinButtonFocusedWidth
      loadHeight: buttonFocusedHeight
      loadWidth: joinButtonFocusedWidth
      opacity: 1
    }
    unfocused: {
      uri: "pkg:/images/authButtonUnfocused.png"
      translation: [screenSize.w - int(16/divider) - joinButtonUnfocusedWidth, (headerHeight - buttonUnfocusedHeight)/2]
      height: buttonUnfocusedHeight
      width: joinButtonUnfocusedWidth
      loadHeight: buttonUnfocusedHeight
      loadWidth: joinButtonUnfocusedWidth
      opacity: 1
    }
    disabled: {
      uri: "pkg:/images/authButtonUnfocused.png"
      translation: [screenSize.w - int(16/divider) - joinButtonUnfocusedWidth, (headerHeight - buttonUnfocusedHeight)/2]
      height: buttonUnfocusedHeight
      width: joinButtonUnfocusedWidth
      loadHeight: buttonUnfocusedHeight
      loadWidth: joinButtonUnfocusedWidth
      opacity: 0.5
    }
    loadDisplayMode: "scaleToFit"
  })
  font = createObject("roSGNode", "Font")
  font.uri = "pkg:/fonts/OpenSansRegular.ttf"
  font.size = int(14/divider)
  m.authButtonLabel.setFields({
    text: ""
    height: buttonUnfocusedHeight
    width: authButtonUnfocusedWidth
    font: font
    horizAlign: "center"
    vertAlign: "center"
    color: "0xFFFFFFFF"
    translation: [screenSize.w - int(16/divider) - authButtonUnfocusedWidth, (headerHeight - buttonUnfocusedHeight)/2]
  })
  font = createObject("roSGNode", "Font")
  font.uri = "pkg:/fonts/OpenSansBold.ttf"
  font.size = int(24/divider)
  m.userName.setFields({
    text: ""
    height: buttonUnfocusedHeight
    font: font
    translation: [int(64/divider), int(12/divider)]
    wrap: false
  })
  m.logo.setFields({
    uri: "pkg:/images/logo.png"
    loadHeight: buttonUnfocusedHeight
    loadWidth: buttonUnfocusedHeight
    loadDisplayMode: "scaleToFit"
    height: buttonUnfocusedHeight
    width: buttonUnfocusedHeight
    translation: [int(16/divider), int(12/divider)]
  })
  m.header.setFields({
    height: headerHeight
    width: screenSize.w
    translation: [0,0]
    visible: true
  })
  m.hero.setFields({
    width: screenSize.w
    loadWidth: screenSize.w
    height: heroHeight
    loadHeight: heroHeight
    loadDisplayMode: "scaleToZoom"
    translation: [0, m.header.height]
  })
  m.banner.setFields({
    width: screenSize.w
    color: "0xF0EEF9FF"
    height: bannerHeight
    translation: [0, m.hero.height + m.header.height + 16]
  })

  m.joinNowButton.setFields({
    focused: {
      uri: "pkg:/images/joinNowButtonFocused.png"
      translation: [(screenSize.w - joinButtonFocusedWidth)/2, (bannerHeight - buttonFocusedHeight)/2]
      height: buttonFocusedHeight
      width: joinButtonFocusedWidth
      loadHeight: buttonFocusedHeight
      loadWidth: joinButtonFocusedWidth
      opacity: 1
    }
    unfocused: {
      uri: "pkg:/images/joinNowButtonUnfocused.png"
      translation: [(screenSize.w - joinButtonUnfocusedWidth)/2, (bannerHeight - buttonUnfocusedHeight)/2]
      height: buttonUnfocusedHeight
      width: joinButtonUnfocusedWidth
      loadHeight: buttonUnfocusedHeight
      loadWidth: joinButtonUnfocusedWidth
      opacity: 1
    }
    disabled: {
      uri: "pkg:/images/joinNowButtonUnfocused.png"
      translation: [(screenSize.w - joinButtonUnfocusedWidth)/2, (bannerHeight - buttonUnfocusedHeight)/2]
      height: buttonUnfocusedHeight
      width: joinButtonUnfocusedWidth
      loadHeight: buttonUnfocusedHeight
      loadWidth: joinButtonUnfocusedWidth
      opacity: 0.5
    }
    loadDisplayMode: "scaleToFit"
  })
  font = createObject("roSGNode", "Font")
  font.uri = "pkg:/fonts/OpenSansRegular.ttf"
  font.size = int(14/divider)
  m.joinNowButtonLabel.setFields({
    text: ""
    height: buttonUnfocusedHeight
    width: joinButtonUnfocusedWidth
    font: font
    horizAlign: "center"
    vertAlign: "center"
    color: "0xFFFFFFFF"
    translation: [(screenSize.w - joinButtonUnfocusedWidth)/2, (bannerHeight - buttonUnfocusedHeight)/2 + int(2/divider)]
  })
end function
