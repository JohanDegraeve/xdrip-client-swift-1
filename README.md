<h1>Build</h1>
<p>This guide will help you integrating JohanDegraeve's xdripswift (https://github.com/JohanDegraeve/xdripswift) into Loop.</p> 

<p>Here are the steps we're going to take:</p>
<ul>
  <li>Update Cartfile dependencies</li> 
  <li>Carthage update</li>
  <li>Add xDrip as a CGM source to Loop in Xcode</li>
  <li>Add the xDrip frameworks</li>
  <li>Link binaries</li>
  <li>Build and launch</li>
  <li>Troubleshoot</li>
</ul>

<h1>Update Cartfile dependencies</h1>
<p>Loop and almost all its elements are constituted of many different projects. These projects lay down the proper foundation for Loop to build successfully. For example, the project LoopKit is fundamental in Loop's inner-workings. Elements such as RileyLink, the Dexcom share client, and the xDrip client rely upon it, depend upon it, in order to function properly. These dependencies are declared in what's called the Cartfile. Here we tell Carthage, the dependency manager, where to go on GitHub to find these constituting elements of Loop. Carthage then fetches that information from GitHub, clones it onto your computer, and then builds it. The result of this is also logged into the Cartfile.resolved. Those very long numbers you see at the end of each declared dependency are what we call a SHA-1. It's like a fingerprint - each one is unique, and is attributed to the version of the dependency you told Carthage to go get. This can help us make sure that we've gone and gotten the right version when we want to be vigilant, but don't worry about that for now.</p>
<p>Because we want Loop to also depend upon the xDrip client, we have to edit the Cartfile and tell Carthage where to go get it so it can import the xDrip client. NOTE: To continue this guide I assume you have a recent version of Loop, which is up and running! If you open Loop's Cartfile, you'll notice it has multiple dependencies but is missing the xDrip client. So we want to tell Loop to use the xDrip client. We can tell Loop to use the client by adding this line of text at the end of the Cartfile: <code>gitHub "julian-groen/xdrip-client-swift" "master"</code>. Copy that into Loop's Cartfile, then save and exit. Do the same for the Cartfile.resolved.</p> 
  
<blockquote>
<p>Note that you may have to right click on the Cartfile or the Cartfile.resolved in order to open it with TextEdit. TextEdit is usually the default editor for the Cartfile, but often the default editor for the Cartfile.resolved is Xcode. Try and be consistent with the editor you use when appending the Cartfiles.
</p>
</blockquote> 

<h1>Carthage update</h1>
<p>Time to tell Carthage to do its thing. In Terminal, type : <br><br>
<code>cd ~/LOCATION_OF_LOOP_FOLDER && carthage update</code></p>
<p>If you get any errors, type <code>rm -rf ~/Library/Caches/org.carthage.CarthageKit</code> and then <code>rm -rf ~/Library/Developer/Xcode/DerivedData</code>. Terminal should not tell you anything after you type these out. If you still get an error, Carthage should tell you what went wrong, but often much too vaguely to do anything about it. At the end of its message, it'll tell you that you can "check the log" at <code>/var/folders/...</code>. Highlight this with your curser and copy it with <code>command+c</code>, then type <code>open</code>, paste the file path with <code>command+v</code>, and hit enter. You'll get a detailed log as to what's happening and where to fix it.</p>

<h1>Add xDrip as a CGM source to Loop in Xcode</h1>
<p>Open up your Loop folder and open the Loop project. In the project manager pane on the lefthand side of your screen, navigate into Loop &gt; Managers &gt; CGMManager.swift.</p>
<p>At the top of the file, you'll see a bunch of frameworks being imported via the declaration <code>import LoopKit</code>, or <code>import ShareClient</code>. We also want to import something : the xDrip client. Click at the end of the last framework being imported, hit enter, and type <code>import xDripClient</code>.</p>
<p>A little further down you'll notice the constant <code>allCGMManagers</code> being declared, with the required syntax being <code>CGMManager.Type</code>. Add xDrip to the list by typing : <code>xDripClientManager.self</code>.</p>

<h1>Add the xDrip frameworks</h1>
<p>Time to use the xDrip frameworks that Carthage went and got for us.</p>
<p>At the top of the project manager pane you'll see "Loop" with the app icon symbol next to it, under TARGETS. Click on that. Along the top of the screen, right under the name of the project, you'll see a range of tabs listed horizontally, such as "General", "Capabilities", "Resource tags"... Find "Build Phases" and click on it. You'll see a list of options appear. Near the bottom you'll see "Copy Frameworks with Carthage". Click on that.</p>
<p>Under "Input Files", you'll see a bunch of things that start with <code>$(BUILT_PRODUCTS_DIR)</code>. All of those files are the frameworks that we asked Carthage to get. We're going to add the xDrip client and its UI onto the list, so that Loop can access the files while it's building and running.</p>
<p>Click on the <code>+</code> and type :</p>
<p><code>$(BUILT_PRODUCTS_DIR)/xDripClient.framework/xDripClient</code></p>
<p><code>$(BUILT_PRODUCTS_DIR)/xDripClientUI.framework/xDripClientUI</code></p>
<p>Now do the same under "Output Files", click on the <code>+</code> and type :</p>
<p><code>$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/xDripClient.framework</code></p>
<p><code>$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKS_FOLDER_PATH)/xDripClientUI.framework</code></p>

<h1>Link binaries</h1>
<h1>Build and launch</h1>
<h1>Troubleshoot</h1>
