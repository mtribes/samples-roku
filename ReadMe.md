# mtribes samples - Roku
The sample project below show how mtribes can be integrated with various Roku applications. These samples demonstrate how to easily add targeting control into an existing app.

## Running

### Prepare Roku device

Enable developer mode on your Roku device. It will allow you to access yor Roku 
device from PC. Please read
[developer setup guide](https://blog.roku.com/developer/developer-setup-guide)

### Prepare environment

For run app on Roku device, please install Ukor and Wist with CMD (if you
don't have npm command - please install [Node.js](https://nodejs.org/uk/)
first)

```
npm install -g @willowtreeapps/ukor @willowtreeapps/wist
```

### Configure device

To "explain" Ukor which device to use for Run app, please add your device to
the list of available device in file **ukor.properties.yaml**.

Example:

```
rokus: {
  your_device: {
    serial: 'YH00C4474609',
    auth: {
      user: 'rokudev',
      pass: '1234'
    }
  }
}
```

### Run

For run use CMD Ukor install command (where last parameter is your device from
**ukor.properties.yaml** or "ukor.local"):

```
  ukor install main your_device
```

As an alternative you could use this command to run app
```
  ukor install main <your_roku_device_ip_adress> --auth=rokudev:1234
```

### Run app with package.zip

If you have application package as a zip file, you can simply upload it to
the target Roku device via web interface http://your_roku_device_ip_adress. 
For it please see **Accessing the Development Application Installer** from
[developer setup guide](https://blog.roku.com/developer/developer-setup-guide)

## Structure
App code lies in "src/main/components". It contains 4 important files:
- `AppScene_before.brs` - sample app code before mtribes integration
- `AppScene_after.brs` - sample app code after mtribes integration
- `AppSceneUIConfig.brs` - general UI configuration
- `AppScene.xml` - Main entry point to app. Can be updated to point at `AppScene_before.brs` or `AppSceneUIConfig.brs` 

App consist of following UI elements.
1. `Header` - Displays sign-in/out button along with welcome message when signed in
2. `Hero` - Displays different image depending on whether signed in or out
3. `Banner` - Displays Visitor label when signed out, and Member label when signed in
Hero and Banner are moved into an mtribes Section to highlight the dynamic capabilities these can provide.

### mtribes Space with sample app
