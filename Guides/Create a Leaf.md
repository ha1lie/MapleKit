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

# Create your Xcode Project

To get started, create a new Xcode project. Select `MacOS` -> `Command Line Tool`

![Xcode Project Type Selection](/createOne.png)

Then, give your project a name, and a Bundle Identifier. This will have to match your Leaf's Bundle ID, so make sure it is unique to you, and you won't cause any of your users problems.

![Xcode Project Creation Screen](/createOne.png)

When you're done, your project layout should look like this:

![Xcode Project Layout](/createLayout.png)

Now, we need to make a few changes to your Project's layout, and Build Settings, and Build Phases in order for your project to be built correctly

### Dependencies 

As all Maple Leaf's rely on both [MapleKit](https://github.com/ha1lie/MapleKit) and [Orion](https://github.com/theos/orion) to work, you will need to add these as dependencies to your Xcode project. To do so, go to the general tab for your Leaf's Target in Xcode. There, click the `+` button, select `Add Other` and choose `Add Package Dependency...`. Once in that window, paste both of the below URLs into the search bar to add them. 

**MapleKit URL**
`https://github.com/ha1lie/MapleKit`

**Orion URL**
`https://github.com/theos/orion`

When adding Orion, please ensure that your target selection screen matches the below:

![Orion Target Selection Screen](/orionTargetSelection.png)

### Project Layout

You'll need to add the following files to your project:

#### info.sap

This file is going to hold all of the configuration for your Maple Leaf to communicate the information to Maple. Below is an example

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

#### OrionGlue.swift

This file will be used by the Orion backend to add glue. You're adding this file to make it easier for Xcode to find the code it needs to compile. Create it in the same directory as `main.swift`, and leave it empty.

At this point, your Project Layout should look like below:

![Project Layout Final](/fileLayout.png)

### Build Settings

Ensure you have changed all settings below to match these. Other than that, you will not have to worry as everything should line up.

 - **Linking**
     - Mach-O Type: Dynamic Library
- **Packaging**
    - Product Name: This does not need to be changed, but does need to match the `lib-name` field in `info.sap` 

### Build Phases

You may have noticed earlier that we don't actually want a Command Line Tool when we're all said and done ~ we want a Maple Leaf. To do this, we add a few Build Phases to help accomplish this. 

First, add two `Run Script` phases in the order shown below. You can rename them if you would like, but it is not required. Ensure you drag them to reorder them as they are shown below.

![Build Phases Collapsed](/runScriptCollapsed.png)

Then, let's configure them to do what they must

#### Run Orion Script

Place this run script directly below the `Dependencies` phase. This will be used to run the Orion precompiler. If you'd like to learn more about it, the GitHub is [here](https://github.com/theos/orion). Firstly, you will need the compiled Orion executable. Build it by following the below instructions.

##### Building Orion

To build Orion, please find a directory where you would like to build it. Then, run the below commands via terminal from your chosen directory.

Clone Orion
`git clone --recurse-submodules https://github.com/theos/orion`

Get into the directory
`cd orion`

Build it
`swift build --configuration release`

Copy the finished product to where you'd like to store it, and remember it!
`cp .build/release/orion /path/to/storing/orion`

After this you're free to remove the GitHub cloned directory, but you do not have to. Make sure to not lose the executable though!

##### Making it run Orion

Back to your `Run Orion` script in Build phases, add the below script to this stage. Also make sure to uncheck `Based On Dependency Analysis` checkbox to force it to run at every build. 

`/path/to/orion -o "${SRCROOT}"/"${TARGET_NAME}"/OrionGlue.swift`

When complete, it should look exactly as below

![Run Orion Script Build Phase](/orionScriptOpen.png)

Note: Your path to the `orion` executable will likely not be the same. That's simply where I currently have orion stored.

#### Leaf Run Script

This Run Script Build Phase should be last in line, coming in just after `Copy Files`. This script is in charge of creating a .leaf file, and moving it to Maple's directory. Add the below script

```bash
cd "${TARGET_BUILD_DIR}"
mkdir "${TARGET_NAME}"Container
cp "${SRCROOT}"/"${TARGET_NAME}"/info.sap ./"${TARGET_NAME}"Container/info.sap
cp ./"${TARGET_NAME}" ./"${TARGET_NAME}"Container/"${TARGET_NAME}"

# Uncomment the below line if you have setup preferences for this leaf. Otherwise, leave commented
# swift "${SRCROOT}"/"${TARGET_NAME}"/"${TARGET_NAME}"Preferences.swift ./"${TARGET_NAME}"Container/prefs.json

zip -r "${TARGET_NAME}".zip ./"${TARGET_NAME}"Container

cp ./"${TARGET_NAME}".zip ~/Library/Application\ Support/Maple/Development/"${TARGET_NAME}".zip
rm -rf ./"${TARGET_NAME}"Container
rm ./"${TARGET_NAME}".zip
```

As you can see above, there is a commented line which regards to Maple Preferences, which you can uncomment once you have configured settings(If you choose to implement them for your Leaf). Uncommenting this line without having set that up will prevent it from finishing properly.

Again, you will also need to uncheck `Based on Dependency Analysis` checkbox to allow this script to run on every build. Once you're done, your phase will look like below.

![Leaf Run Phase Open](/leafScriptOpen.png)

### Complete!

Now, your project is setup and ready to start building. Once you put some form of an Orion class into the files, it should compile without issue. If you build your Maple Leaf now, you should receive an alert telling you that it has been installed and is now running. If you don't, then ensure you have your `info.sap` file configured properly, and you've followed all steps above. Just like below, you should be able to see your Leaf in Maple's list, just like below!

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

Now, you may notice that you have an error. This is because this file is meant to be run on it's own, and not compiled with your Leaf. To remove it, open the file inspector for this file, and uncheck your Leaf from the target membership section. Once you do that, it should look like the screenshot below, and you should have no more errors.

![Target Membership Preferences File](/prefTargetMember.png)

Finally, update the bundle identifiers and preference identifiers in the template file to match what you want. Also, add `PreferenceGroup`s and `Preference`s as you like! To clarify any questions, see the links to these objects in the leftside panel! Documentation will hopefully be updated whenever the dopamine allows.

## Uncomment the Run Script

Remember when we setup the Run Script build phase earlier in our project? There was a commented line which stopped it from crashing. Now, we need that line! Open the Xcode project editor, and go to `Your Target` -> `Build Phases` and select the last `Run Script` phase. In that script there should be two lines which look like below. 

![Commented Lines](/commentedPrefsScript.png)

Delete the `#` sign from the beginning of the `swift ...` line so that it instead looks like this:

![Uncommented Pref Line](/uncommentedPrefsLines.png)

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
