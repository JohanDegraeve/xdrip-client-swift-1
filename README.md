NB! This project requires LoopWorkspace dev. You *must* use the workspace to buid this.

## Start with a clean LoopWorkspace based on dev

* Download a fresh copy of LoopWorkspace dev into a subfolder of your choice
```
cd ~
mkdir Code && cd Code
git clone --branch=dev --recurse-submodules https://github.com/LoopKit/LoopWorkspace
cd LoopWorkspace
```

* Add xDripClient submodule
```
git submodule add -b main git@github.com:julian-groen/xdrip-client-swift.git xDripClient
```

## In Xcode, Add xDripClient project into LoopWorkspace
* Open Loop.xcworkspace
* Drag xDripClient.xcodeproj from the Finder (from the xDripClient submodule) into the xcode left menu while having the loop workspace open 
* It should Look like this:
![CGMManager_swift](https://user-images.githubusercontent.com/442324/111884066-63241500-89bf-11eb-9b0c-14a440111cda.jpg "LibreTransmitter as part of workspace")

* Select the "Loop (Workspace)" scheme and then "Edit scheme.."
* In the Build Dialog, make sure to add xDripClientPlugin as a build target, and place it just before "ShareClientPlugin"
* In Xcode 13 this can be accessed from the top menu `Product -> Scheme -> Edit Scheme`
* it should look like this: ![CGMManager_swift](https://user-images.githubusercontent.com/442324/111884191-41775d80-89c0-11eb-8f8a-51290e85d9a5.jpg)

## Build the LoopWorkspace with xDripClient Plugin
* In xcode, go to Product->"Clean Build Folder"
* Make sure you build "Loop (Workspace)" rather than "Loop"
