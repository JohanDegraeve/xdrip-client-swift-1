
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
git submodule add -b master https://github.com/julian-groen/xdrip-client-swift.git xdrip-client-swift
```

## In Xcode, add xDripClient project into LoopWorkspace
1. Open Loop.xcworkspace
2. Drag xDripClient.xcodeproj from the Finder (from the xDripClient submodule) into the xcode left menu while having the loop workspace open
3. Select the "Loop (Workspace)" scheme and then "Edit scheme.."
4. In the Build Dialog, make sure to add xDripClientPlugin as a build target, and place it just before "ShareClientPlugin"
5 In Xcode 13 this can be accessed from the top menu `Product -> Scheme -> Edit Scheme`

<details>
<summary>Reference material: Step 2</summary>

  ![Schermafbeelding 2022-03-15 om 20 42 54](https://user-images.githubusercontent.com/55219001/158459048-e0fd4d82-780c-4452-851d-4d48a3e15594.png)

</details>

<details>
<summary>Reference material: Step 4</summary>

  ![Schermafbeelding 2022-03-15 om 20 43 16](https://user-images.githubusercontent.com/55219001/158459062-1e267e3f-33cb-431b-874c-688555a7a099.png)

</details>

## Build the LoopWorkspace with xDripClient Plugin
* In xcode, go to Product->"Clean Build Folder"
* Make sure you build "Loop (Workspace)" rather than "Loop"

## Troubleshooting
Loop not getting xDrip data?
* Wait a moment. On first launch the plugin will probably be empty, as it doesn't prompt xDrip to re-read.
* Make sure xDrip is receiving readings! (Did you open the correct copy of xDrip? You might now have two copies. Delete both, and reinstall.)
* Make sure Loop and xDrip are using the same App Group! Really!
* Make sure both Loop and xDrip are still running in the background - try killing recent apps, then killing and reopening Loop and xDrip. Make ure they have all the iOS permissions they need.

## Miscellaneous (Navigate to xDrip4iOS via Loop HUD)

<details>
<summary>Add 'xdripswift' to LSApplicationQueriesSchemes</summary>

  ![Schermafbeelding 2022-03-15 om 20 38 37](https://user-images.githubusercontent.com/55219001/158460127-6f55a457-fcb4-4dbd-ba55-8c744b66782a.png)

</details>
