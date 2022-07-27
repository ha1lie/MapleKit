# An All-In-One Guide to Building a Leaf

Getting started creating your first Maple Leaf can be a difficult process. This Guide will show you everything you need to know, as well as the best ways to accomplish things!

# Configure Maple

Before you get started, you need to make sure Maple is properly configured. Please ensure the below:

 - Development Enabled: **ON**
 - Notify on Install: **ON**

While this may seem obvious, enabling development may be a silly slip up for some. Furthermore, I recommend you enable *Notify on Install* in the development section for security reasons - you'll never miss an unknown Maple Leaf being installed and hurting your Mac.

Your settings page should look like below

![Maple Settings Screen](/mapleSettings.png)

Now that Maple is ready to run your *Leaves-In-Development*, let's get started below. In this example, we'll make a simple Leaf which changes all NSTextViews in the Calculator app.

# Prep your Mac

If this is your first time developing a Maple Leaf, you'll need to install `mbuild` which is a small utility to simplify the install process of your Leaf when developing it. You can see the [GitHub here](https://github.com/ha1lie/mbuild).

### Install mbuild

Open a Terminal window, and directly from the home directory, run the following commands. 

1. Create a directory to hold mbuild. You can put this anywhere, or use any existing directory. I'll keep mine at `~/maple/`  Make sure you adjust all directories in the below commands to reflect where you will keep mbuild.

```bash
mkdir ~/maple
```

2. Download mbuild to the directory

```bash
curl -L -o ~/maple/mbuild https://github.com/ha1lie/mbuild/releases/download/v1.0/mbuild
```

3. Make it executable, so it can run. Enter your password if prompted

```bash
chmod +x ~/maple/mbuild
```

4. Add the containing folder to your `$PATH` variable. This will vary from machine to machine. Most Macs run zsh, like mine, and it should just be a matter of adding the below line to the **end** of your `~/.zprofile` file

```
export PATH="$PATH:/Users/hallie/maple"
```

Once you do that, close and open a new window, and you're all set!

### Testing mbuild

Before you get up and running, test mbuild to make sure you did all of the above steps correctly. In your home directory, run `mbuild` in your terminal, and it should spit out the help prompt for you. 

### Using mbuild

To use mbuild, you'll want to have a terminal open in the top level directory of your SPM project. Then, run it like below, replacing `PROJECTNAME` with the correct name. Running this command will run swift build to create the dylib, package your leaf, and install it to Maple. 

```bash
mbuild PROJECTNAME
```

If you're building a leaf with preferences, you'll want to add the `--prefs` flag as well. 

Finally, if you're building a final version of your leaf, you'll want to add the `--release-mode` flag to the end of the command. 

# Create your Xcode Project

Thanks to a quick update after Maple was initially released, building Maple Leafs actually got a reboot, and this section is now a lot quicker thanks to being able to utilize SPM projects!

First, start a new Xcode project, select `Multiplatform` -> `Swift Package`

![Xcode Project Type Selection](/createSPM.png)

Click `Next` and then choose a name for your Leaf, as well as where you'd like to store it. I created mine in the Documents directory, and named it MyVolume. When you're ready, click `Create`

![Xcode Project Configuration Screen](/spmConf.png)

Your project will initialize and open to it's `Package.swift` file, which should look extremely similar to the one below. 

```swift
// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyVolume",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "MyVolume",
                 targets: ["MyVolume"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "MyVolume",
                dependencies: []),
        .testTarget(name: "MyVolumeTests",
                    dependencies: ["MyVolume"]),
    ]
)
```

## Configure Package.swift 

As you can see, this file is responsible for all of the metadata associated with your project. We're going to make just a few tweaks to it.

### Platforms

Firstly, you're going to want to tell Xcode what platforms this software can run on. For us, it's any versions of MacOS higher than 11.0 (MacOS Big Sur). We can declare this by adding the following lines just under the `name` declaration.

```swift
platforms: [
    .macOS(.v11),
]
```

Of course, if your Leaf targets a higher version of MacOS for any reason, you can change it to that version, but because of what Maple supports, you cannot specify anything below 11.0, or else Xcode will complain. 

### Targets and Products

Targets and products specify what we are building. We'll be building a *Dynamic Library*, so we need to specify that. 

In `targets: []`, delete the `.target(name: "Project Name"...` object, and replace it with the below code while replacing `**PROJECTNAME**` with the name of your project.

```swift 
    .executableTarget(name: "**PROJECTNAME**",
                      dependencies: [
                          .product(name: "MapleKit", package: "maplekit"),
                          .product(name: "Orion", package: "orion"),
                      ], 
                      exclude: [
                          "info.sap"
                      ],
                      plugins: [
                          .plugin(name: "OrionPlugin", package: "orion"),
                      ],
                    ),
```

This does a few things...

1. Defines an executable target, meaning that it will compile code which can be run
2. Adds both `MapleKit` and `Orion` as dependencies. Xcode will complain for a minute, but we'll fix it below
3. Preliminarily excludes `info.sap` files from your sources... we'll add this later
4. Adds the Orion Pre-Processor so that Orion can be run

Now, products are the finished products created when compiling the source code. Most of the work has already been done for us, but Xcode generated code for a static library. We need ours to be dynamic. Change the `.library` argument in `products: []` to mirror below.

```swift
...
products: [
    .library(name: "MyVolume",
             type: .dynamic,
             targets: ["MyVolume"]),
],
...
```

### Dependencies

Remember how Maple Leafs are built with MapleKit, and the method replacement is done with Orion? Well, those are both dependencies, and we have to tell Xcode that. There is already a section for dependencies, so add the below lines within the `[]` array. 

```swift
    .package(url: "https://github.com/ha1lie/maplekit", branch: "main"),
    .package(url: "https://github.com/theos/orion", branch: "master"),
```

### Done

Once you're all said and done, your `Package.swift` file should look like below

```swift
// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyVolume",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "MyVolume",
                 type: .dynamic,
                 targets: ["MyVolume"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ha1lie/maplekit", branch: "main"),
        .package(url: "https://github.com/theos/orion", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(name: "MyVolume",
                      dependencies: [
                          .product(name: "MapleKit", package: "maplekit"),
                          .product(name: "Orion", package: "orion"),
                      ], 
                      exclude: [
                          "info.sap"
                      ],
                      plugins: [
                          .plugin(name: "OrionPlugin", package: "orion"),
                      ],
                    ),
        .testTarget(name: "MyVolumeTests",
                    dependencies: ["MyVolume"]),
    ]
)
```

## Add Needed Files

There is just one more file needed before you can begin compiling your leaf, and that's Maple's meta-data file, `info.sap`

#### info.sap

This file is going to hold all of the configuration for your Maple Leaf to communicate the information to Maple. Create this file in your Sources folder, within your Project Name folder. Below is an example

```
name: CalculatorLabels
author: Hallie
author-email: hallie@halz.dev
author-discord: hallie#2162
tweak-website: https://hey.halz.dev
description: Customizes your Calculator NSTextViews
image: x.squareroot
lib-name: CalculatorLabels
target-bundle-id: com.apple.calculator
leaf-id: dev.halz.calclabels
```

In this file, all fields should be seperated by **ONE** newline character, and the field name and contents should be seperated by a colon followed by a space. This file should be created in the same directory as `main.swift`. The field names are listed below. Bolded fields are required, all other fields can be left out, and won't be shown to the user.

- **name**: The name of the Maple Leaf
- **author**: The name of the developer.... You!
- author-email: Your email. This will be used for users to communicate with you on questions and concerns
- author-discord: Your discord tag. This will be used for users to communicate with you on questions and concerns
- tweak-website: A website which gives information about your Leaf. Could be a GitHub, your portfolio, or a dedicated website for this Leaf
- **description**: The description presented to the user in Maple app
- image: An image used when showing information about your leaf. The images can be chosen from SF Symbols app, and should be the name of an existing installed image
- **lib-name**: The name of the executable. If you don't know it right now, leave it blank, we'll get to it below
- **target-bundle-id**: The bundle identifier of the process which this Leaf will inject into. For our app, we'll be using `com.apple.Calculator`
- **leaf-id**: The bundle identifier for your Maple Leaf. This should match the bundle identifier from when you created your project.

### Complete!

Now, your project is setup and ready to start building. Once you put some form of an Orion class into the files, it should compile without issue. If you run mbuild now, you should receive an alert telling you that it has been installed and is now running. If you don't, then ensure you have your `info.sap` file configured properly, and you've followed all steps above. Just like below, you should be able to see your Leaf in Maple's list, just like below!

![Maple's Leaf List](/mapleLeafList.png)

When developing your Leaf, make sure to reference [Orion Docs](https://orion.theos.dev) as needed. Place all `Hook` Classes into the `main.swift` file, or at least one, to make sure that everything is loaded at runtime. Do not delete nor rename `main.swift` as it is needed by the Xcode compiler.

**ATTN DEVELOPERS:** If you know how to make Xcode templates, and would like to help contribute to Maple, please feel free to make some, and send me a message using any contact found on my GitHub profile or other website so that we can best work together to help other developers. While I attempted to make some, it was eventually simply not worth my time, and I did not know what I was doing well enough. 

# Use MapleLogger to Improve Your Flow

As a developer, you're familiar with the need to debug your code, and I'm sure your no newbie to this. However, when our code is running in a process we don't have access to, this can get complicated. Sure, you could attempt to tediously make Xcode's logging window attach to the new process, but in all honesty, that get's tiring, and well, I don't know where to start on making it do that anyway. So! This was the closest I got to figuring out a good alternative

Using MapleKit's package, you're able to easily send logs to Maple, and view them within Maple's log window. To get to this window, open Maple's Menu Bar Window, hover over the ellipsis(...) and click on `Logs`. This will open a window similar to below

![Maple's Log Window](/mapleLogWindow.png)

Then, to help you get rid of the junk, click on the 'Development Logs` tab. This will filter out all of the logs given from Maple's app, and limit it to just third party logs. If you have a lot of leaves installed, you can further limit the amount of logs that you see by entering your leave's Bundle Identifier into the search field.

It's important to note that all logs are also exportable. This means that any time a user is reporting a bug or problem, you can ask them for their exported `.log` file which they can export with the click of a button to send to you for easy debugging. 

Please also note that Maple Logs are **not encrypted**. This means that **ANY** process which listens for a Maple Log notification will be able to read the contents of it, as well as the stored file being readable by the user. **Do not store sensitive information in logs**. This includes developer keys, API endpoints, DRM protected content, etc. It is fine to use while developing on your own machine, but do not push without removing them. 

Now, to get to know how to use MapleLogger like a power user

### Log Types

Now, there are three types of logs that Maple will handle: `Normal`, `Error`, and `Warning`. All three of these logs are easy to use, but can help you by visually differentiating them within the log window. 

#### Normal Logs

These logs are the easiest to use, and act plainly, without any prefix, and they show up in the default text color

#### Warning Logs

These logs indicate that something might be awry, and guide you to take a look at them. They're displayed in a yellow color.

To use, simply preface your log with `WARNING `. This prefix will not be shown within the log displayed to the user, thus eliminating that ugly text block.

#### Error Logs

These logs indicate that something has crashed. It's best to use these in final products as well to ensure that users can report crashes to you. 

To use, simply preface your log with `ERROR` and it will be displayed as an error message. This prefix will not be shown within the log displayed to the user, thus eliminating that ugly text block.

### Best Practices

While documentation for MapleLogger can be found [here](https://maplekit.halz.dev/Classes/MapleLogger.html), here are some suggestions for how to best use it. 

Since MapleLogger relies on an initialized object to send logs to Maple(this is to help differentiate your logs from another leaf's), it's best that you only initialize this once. I personally recommend creating a shared public global variable, since this does not affect security(so long as you do not pass sensitive information to it), and allows you to simply call it however you need. An example is below

```swift
import MapleKit

public let logger: MapleLogger = MapleLogger(forBundle: "dev.halz.calculatorlabels")

class HookOne: ClassHook<NSTextView> {
    public `init`() {
        logger.log("Initializing Hook One!")
        orig.`init`()
    }
}

class HookTwo: ClassHook<NSSlider> {
    public `init`() {
        logger.log("Initializing Hook Two!")
        orig.`init`()
    }
}
```

#### Too Long?

If you think the syntax `logger.log("ERROR I don't know what I'm doing")` is too long, you're more than welcome to shorten it. Below is a code snippet which would allow you to call a shorter function name `mlog`

```swift
import MapleKit

public let logger: MapleLogger = MapleLogger(forBundle: "dev.halz.calculatorlabels")

public func mlog(_ log: String) {
    logger.log(log)
}
```

Now, simply replace your `print(_)` calls with `mlog(_)`, and you're good to go!

# Add Preferences

Now that you've built out a great Maple Leaf, you're wondering how you can best let your users do what Maple was built for... customize! Preferences are the best way to let a user make your Leaf, well, *theirs*! 

Follow the below steps to easily get setup and start using preferences

## Add Preferences File

First things first, you'll need a preferences file. This is used to create and export your preferences as a JSON file, which can be used to share them with the Maple app. While this file does have a lot of boiler plate code, you can get a copy of it [here on GitHub](https://gist.github.com/ha1lie/adccaefa3f7b0e67e95e6ecac4b57cef). Once you download the file, drag it into your Xcode project file structure, and rename it according to your Xcode project name. Make sure it matches exactly. After this step, your project layout should look like below

![Preferences File Xcode Project Layout](/preferencesFileLayout.png)

Now, you may notice that you have an error. This is because this file is meant to be run on it's own, and not compiled with your Leaf. To remove it, open `Package.swift` and add the file to the `exclude` array in the target section. Once you do that, you should have no more errors.

Finally, update the bundle identifiers and preference identifiers in the template file to match what you want. Also, add `PreferenceGroup`s and `Preference`s as you like! To clarify any questions, see the links to these objects in the leftside panel! Documentation will hopefully be updated whenever the dopamine allows.

## Make sure you use mbuild correctly

Now that you're adding preferences, make sure when you build you add the `--prefs` flag to your mbuild command so it looks like below!

```bash
mbuild MyVolume --prefs
```

Now your preferences will be bundled with your Leaf when you install them in Maple. See below.

![Preferences POC Screenshot](/settingsPocSS.png)

## Develop for Preferences

Now, you've reached the final step. It's time to develop your Leaf to make the best with it's new power!

There are two ways to interact with preferences. Unfortunately, you should only use one of them in any given Leaf: Instant Notifications and Value Retrieval or Asynchronous Notifications and Value Retreival. So, how do you know which to use?

#### The App Sandbox

Unfortunately for developers, but gratefully for users, Apple implemented something called the App Sandbox for most apps. Apps which are sandboxed are not allowed to access files stored outside of designated directories, as well as restrictions on Swift's `DistributedNotificationCenter` and other things. Due to this, there have been two Systems setup below. If you are modifying a sandboxed application, you will need to use the Asynchronous method, otherwise, it's recommended you use instantaneous for ease of development and a better user experience.

## Instantaneous

This Preference Value protocol should only be used in processes which are not sandboxed.

### Retrieve Value On Call

To get the value of a preference at any given time, use either of the below methods

```swift
let value: PreferenceValue? = Preferences.valueForKey("**PREFERENCE ID**", inContainer: "**YOUR LEAF BUNDLE ID**")
```

If you have a pre-existing `Preferences` object which is configured with your Bundle ID already, you can use:

```swift
// Global variable
let preferences: Preferences = Preferences(forBundle: "**YOUR LEAF BUNDLE ID**")

private func getTheValue() throws -> PreferenceValue {
    guard let value = preferences.valueForKey("**PREFERENCE ID**") else {
        throw Error()
    }
    
    return value
}
```

## Asynchronous

### Retrieve a value

Now, due to the limitations which were discussed earlier, your process isn't able to read the preferences file like non-sandboxed apps are. The other restriction placed is that Notifications sent through the `DistributedNotificationCenter` on MacOS can't have notifications with non-nil `userInfo` arguments. To get around this, we use the fact that Notification Listeners will stil trigger with `object` being non-nil. 

The function to use for this is: 

``` swift
Preferences.expensiveValueForKey(_ id: String, inContainer: String, withCompletionHandler: @escaping (_ prefValue: PreferenceValue) -> Void)
```

An example of this in use: 

```swift
func init() {
    var value: PreferenceValue?
    // Get the value
    Preferences.expensiveValueForKey("PreferenceKey", inContainer: "LeafBundleID") { prefValue in 
        value = prefValue
    }
    
    // Finish initialization
    // ...
}
```

Please note: Do not use this on Sandboxed app. This is a complicated pattern of adding multiple listeners to `DistributedNotificationCenter` which is used by a large portion of the MacOS system, and can get bogged down by using it too often. Once at initialization is enough :) 

## Notify On Change

Sometimes, you may want to initialize a variable at startup, but know when that value changes throughout runtime, and without having to retrieve it many times. This is the solution: 

1. Create a `Preference` object
2. Make sure `onSet` is non-nil
3. Watch the magic happen

This is an example below

```swift
var preference: Preference? = nil

func updatePreferenceValue(_ val: PreferenceValue) {
    updateStuff()
}

func init() {
    // Initialization
    preference = Preference(withTitle: "Title", withType: .bool, andIdentifier: "PREFERENCE ID", forContainer: "CONTAINER NAME",toRunOnSet: { newValue in
        if let pref    = newValue {
            updatePreferenceValue(pref)
        }
    })
}
```

# Done!

Now, you know how to make a Maple Leaf! It's time to get to work to make Maple an awesome tool for all of the users

If this guide helped you, give me a shoutout anywhere below, it really really helps! Any more questions? Send me a message! 

[Twitter @h4l1ie](https://twitter.com/h4l1ie)

[GitHub @ha1lie](https://github.com/ha1lie)

[Buy me a Coffee ☕️](https://www.buymeacoffee.com/ha1lie)

# Wanna Help Out?

**Contribute to the project!** Both [Maple](https://github.com/ha1lie/maple) and [MapleKit](https://github.com/ha1lie/maplekit)

**Make Leaves!** This project can't survive without people working to make it useful! Add your own spin on everything here!
