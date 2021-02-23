# Roku SDK: QA Sample App
## CLI installation

This is the first step. We've purpose-built a command-line-interface (CLI) to automate most of the process,
and help integrate your mtribes Space quickly and accurately. 

Install via [Homebrew](https://brew.sh/)
```bash
brew install mtribes/tap/mtribes
```
Install via [Scoop](https://scoop.sh/)

```bash
scoop bucket add mtribes https://github.com/mtribes/cli.git
scoop install mtribes
```

## CLI upgrade

Upgrade the CLI at anytime via [Homebrew](https://brew.sh/)

```bash
brew upgrade mtribes
```

Upgrade the CLI at anytime via [Scoop](https://scoop.sh/)

```bash
scoop update mtribes
```
## Space setup

With the CLI installed, you can now set up your Space integration by running the
following command in the root folder of your project.

```bash
mtribes setup
```

The first time you run `setup`, you'll be prompted to enter your secret API key
to authenticate with mtribes. Your secret key is located on your organization's
[settings page](https://mtribes.com/developer/settings). **You'll need to be an
administrator to access this page**.

Once authenticated, follow the remaining prompts to configure your connection.

1. Select the mtribes Space to integrate with.
2. Choose a target language if the default is incorrect.
3. Type destination folder - "src/main/components/sample"

The CLI will now generate Space specific integration code for you to use.

## Prepare Roku device

Enable developer mode on your Roku device. It will allow you to access yor Roku 
device from PC. Please read
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

As an alternative you could use this command to run app
```
  ukor install main <your_roku_device_ip_adress> --auth=rokudev:1234
```

## Run app with package.zip

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
