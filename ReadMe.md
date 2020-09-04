'TODO



# Roku SDK: QA Sample App

## Prepare Roku device

First steep for launch any custom app on Roku device is enable developer mode.
It will allow you to access yor Roku device from PC. Please read
[developer setup guide](https://blog.roku.com/developer/developer-setup-guide)

## Prepare environment

For run app on Roku device, please install Ukor and Wist with CMD (if you
don't have npm command - please install [Node.js](https://nodejs.org/uk/)
first)

```
npm install -g @willowtreeapps/ukor @willowtreeapps/wist
```

## Configure device

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

## Run

For run use CMD Ukor install command (where last parameter is your device from
**ukor.properties.yaml** or "ukor.local"):

```
  ukor install main your_device
```

## Run app with package.zip

If you have application package as a zip file, you can simply upload it to
the target Roku device via web interface http://your_device_ip_adress. 
For it please see **Accessing the Development Application Installer** from
[developer setup guide](https://blog.roku.com/developer/developer-setup-guide)
