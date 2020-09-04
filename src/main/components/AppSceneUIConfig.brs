function setupInitialUI()
  buttonFocusedHeight = 38
  buttonUnfocusedHeight = 32
  headerHeight = 56
  bannerHeight = 80

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

  m.authButton.setFields({
    focused: {
      uri: "pkg:/images/authButtonFocused.png"
      translation: [screenSize.w - 16 - 89, (headerHeight - buttonFocusedHeight)/2]
      height: buttonFocusedHeight
      width: 92
      loadHeight: buttonFocusedHeight
      loadWidth: 92
      opacity: 1
    }
    unfocused: {
      uri: "pkg:/images/authButtonUnfocused.png"
      translation: [screenSize.w - 16 - 86, (headerHeight - buttonUnfocusedHeight)/2]
      height: buttonUnfocusedHeight
      width: 86
      loadHeight: buttonUnfocusedHeight
      loadWidth: 86
      opacity: 1
    }
    disabled: {
      uri: "pkg:/images/authButtonUnfocused.png"
      translation: [screenSize.w - 16 - 86, (headerHeight - buttonUnfocusedHeight)/2]
      height: buttonUnfocusedHeight
      width: 86
      loadHeight: buttonUnfocusedHeight
      loadWidth: 86
      opacity: 0.5
    }
    loadDisplayMode: "scaleToFit"
  })
  font = createObject("roSGNode", "Font")
  font.uri = "pkg:/fonts/OpenSansRegular.ttf"
  font.size = 14
  m.authButtonLabel.setFields({
    text: ""
    height: buttonUnfocusedHeight
    width: 86
    font: font
    horizAlign: "center"
    vertAlign: "center"
    color: "0xFFFFFFFF"
    translation: [screenSize.w - 16 - 86, (headerHeight - buttonUnfocusedHeight)/2]
  })
  font = createObject("roSGNode", "Font")
  font.uri = "pkg:/fonts/OpenSansBold.ttf"
  font.size = 24
  m.userName.setFields({
    text: ""
    height: buttonUnfocusedHeight
    font: font
    translation: [64, 12]
    wrap: false
  })
  m.logo.setFields({
    uri: "pkg:/images/logo.png"
    loadHeight: buttonUnfocusedHeight
    loadWidth: buttonUnfocusedHeight
    loadDisplayMode: "scaleToFit"
    height: buttonUnfocusedHeight
    width: buttonUnfocusedHeight
    translation: [16, 12]
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
    height: 500
    loadHeight: 500
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
      translation: [(screenSize.w - 94)/2, (bannerHeight - buttonFocusedHeight)/2]
      height: buttonFocusedHeight
      width: 94
      loadHeight: buttonFocusedHeight
      loadWidth: 94
      opacity: 1
    }
    unfocused: {
      uri: "pkg:/images/joinNowButtonUnfocused.png"
      translation: [(screenSize.w - 88)/2, (bannerHeight - buttonUnfocusedHeight)/2]
      height: buttonUnfocusedHeight
      width: 88
      loadHeight: buttonUnfocusedHeight
      loadWidth: 88
      opacity: 1
    }
    disabled: {
      uri: "pkg:/images/joinNowButtonUnfocused.png"
      translation: [(screenSize.w - 88)/2, (bannerHeight - buttonUnfocusedHeight)/2]
      height: buttonUnfocusedHeight
      width: 88
      loadHeight: buttonUnfocusedHeight
      loadWidth: 88
      opacity: 0.5
    }
    loadDisplayMode: "scaleToFit"
  })
  font = createObject("roSGNode", "Font")
  font.uri = "pkg:/fonts/OpenSansRegular.ttf"
  font.size = 14
  m.joinNowButtonLabel.setFields({
    text: ""
    height: buttonUnfocusedHeight
    width: 88
    font: font
    horizAlign: "center"
    vertAlign: "center"
    color: "0xFFFFFFFF"
    translation: [(screenSize.w - 88)/2, (bannerHeight - buttonUnfocusedHeight)/2 + 2]
  })
end function
