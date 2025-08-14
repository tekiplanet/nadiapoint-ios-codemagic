# How to Test Your App on Codemagic Before Deploying

This guide explains how to remotely access the Codemagic build machine to run your app in the iOS Simulator, view logs, and debug issues before deploying to TestFlight. This is essential for developers without a physical Mac.

---

### ✅ **Step 1: Create a Debug Workflow**

It's a best practice to create a separate workflow for debugging so you don't alter your main deployment configuration.

1.  **Navigate to Workflow Settings**: In Codemagic, go to your app's **Settings > Workflow** tab.
2.  **Duplicate Workflow**: At the top of the page, click the **Duplicate** button.
3.  **Name the New Workflow**: Give it a clear name, like `debug-ios`.
4.  **Select the New Workflow**: Make sure you are editing the new `debug-ios` workflow for the next steps.
5.  **Enable Remote Access**: In the **Run build on** section at the top of the workflow, check the box for **Enable SSH/VNC access**. This is the most important step.

---

### ✅ **Step 2: Enable Remote Access in Your Debug Workflow**

Now, in your new `debug-ios` workflow, you can add the script to pause the build.

1.  **Edit Pre-build Script**: Scroll to the **Pre-build script** section.
2.  **Add Pause Script**: Add the following lines to the **very end** of your script. This will pause the build after all setup is complete.

    ```bash
    # Pause the build for 60 minutes (3600 seconds) to allow for remote access
    echo "Build paused for 60 minutes for remote debugging..."
    echo "Connect using the VNC details from the Codemagic UI."
    sleep 3600
    ```

4.  **Disable Publishing**: Scroll to the **Distribution** section and **uncheck** the box for **Enable App Store Connect publishing**. This prevents the debug build from being sent to TestFlight.
5.  **Save Changes**: Click **Save changes** for your workflow.

---

### ✅ **Step 2: Start a Build and Connect Remotely**

1.  **Start a New Build**: Go to your app's main page and click **Start new build**.
2.  **Find VNC Details**: As the build runs, the **Remote access** section will appear in the build logs. It will provide:
    *   An SSH command (for terminal access).
    *   A VNC address (e.g., `vnc://123.45.67.89:1234`).
    *   A password.
3.  **Connect with a VNC Client**:
    *   You will need to download and install a VNC client on your Windows machine. It is a desktop application, not a website.
    *   We recommend **RealVNC Viewer**, which is free. You can download it here: [RealVNC Viewer for Windows](https://www.realvnc.com/en/connect/download/viewer/windows/).
    *   Once installed, open RealVNC Viewer and enter the VNC address and password provided by Codemagic to connect.

---

### ✅ **Step 3: The Final Pre-Build Script (The Definitive Fix)**

After extensive debugging, the root cause was identified as a corrupted Xcode project configuration (`Runner.xcodeproj`) that was preventing CocoaPods from correctly linking libraries.

The only reliable solution is to regenerate the entire `ios` project folder from scratch with every build. This ensures a clean slate and resolves all configuration issues.

#### Part A: Create the Secure `plist` Variable

Because we will be deleting the `ios` folder, we must automate the creation of the `GoogleService-Info.plist` file. The best way is to store its contents in a secure variable.

1.  **Encode the file**: Use the easiest method - an online tool.
    *   Go to **[https://www.base64encode.net/](https://www.base64encode.net/)**.
    *   Click **"Choose File"** and select your `GoogleService-Info.plist` from `ios/Runner`.
    *   Click **"Encode"** and then **"Copy to Clipboard"**.
2.  **Create the Codemagic Variable**:
    *   In your Codemagic workflow, go to the **"Environment variables"** tab.
    *   Create a new variable named `GOOGLE_SERVICE_INFO_PLIST_BASE64`.
    *   Paste the long string you copied into the value field.
    *   Check the **"Secure"** box and add the variable to your workflow group.

#### Part B: Update the Pre-Build Script

In your `debug-ios` workflow settings, replace the entire **Pre-build script** with the following code. This script performs a full project regeneration and uses the secure variable you just created.

```sh
#!/bin/sh
set -e
set -x

# --- FULL PROJECT REGENERATION ---
echo "Regenerating the iOS project to fix configuration issues..."
flutter clean
flutter pub get
rm -rf ios
flutter create --platforms=ios .

# --- AUTOMATICALLY ADD FIREBASE CONFIG ---
echo $GOOGLE_SERVICE_INFO_PLIST_BASE64 | base64 --decode > ios/Runner/GoogleService-Info.plist
echo "Successfully created GoogleService-Info.plist"

# Create the .env file
echo "API_URL=${API_URL}" > .env
echo "JWT_KEY=${JWT_KEY}" >> .env
echo "APP_NAME=${APP_NAME}" >> .env
echo "Successfully created .env file"

# --- INSTALL DEPENDENCIES ---
echo "Installing iOS dependencies (CocoaPods)..."
cd ios
pod install --repo-update
cd ..

# --- PAUSE FOR DEBUGGING ---
echo "Build paused for debugging..."
sleep 3600
```

### ✅ **Step 4: Connect via VNC and Run the App in the iOS Simulator**

Once you are connected to the remote Mac desktop, follow these steps to get the app running.

1.  **Navigate to Project Folder**: In the Terminal window, navigate to the project directory:
    ```bash
    cd /Users/builder/clone
    ```
2.  **Open Xcode**: Open the iOS project in Xcode:
    ```bash
    xed ios
    ```

#### Troubleshooting the First Xcode Build

When you run the app in Xcode for the first time on a clean machine, you will likely encounter build errors. Follow these steps in order, proceeding to the next only if the problem persists.

**Level 1: Basic Setup**

1.  **Generate Flutter Files**: Fix `Generated.xcconfig not found` errors.
    *   In the **Terminal**, from the project root (`/Users/builder/clone`), run:
      ```bash
      flutter pub get
      flutter build ios --simulator
      ```

**Level 2: Fix Module Not Found Errors**

1.  **Deep Clean Pods**: Fix errors like `Module 'firebase_auth' not found`.
    *   In the **Terminal**, navigate to the `ios` directory:
      ```bash
      cd ios
      ```
    *   Remove old pod files and reinstall:
      ```bash
      rm -rf Pods Podfile.lock
      pod install --repo-update
      ```
2.  **Reload Project**: When Xcode prompts you, always select **"Use Version on Disk"**.
3.  **Clean Xcode Build Folder**: In the Xcode menu, select **Product > Clean Build Folder**.

**Level 3: Fix Firebase Initialization Failure**

If the build succeeds but the app crashes immediately on launch with a `No app has been configured yet` error in the logs, it means Firebase isn't set up correctly.

1.  **Check for `GoogleService-Info.plist`**: In the Xcode Project Navigator, expand **Runner > Runner**. The `GoogleService-Info.plist` file must be listed there. 
2.  **Add if Missing**: If the file is not in the project, drag it from the Finder (`/Users/builder/clone/ios/Runner`) and drop it into the `Runner` folder in Xcode. Ensure **"Copy items if needed"** and the **`Runner`** target are both checked.

**Level 4: Fix Push Notification / Splash Screen Hang**

1.  **Add Capability**: The root cause is often a missing push notification entitlement. In Xcode, go to **Runner > Signing & Capabilities** and add the **Push Notifications** capability.

**Level 5: The "Nuclear Option" (If all else fails)**

If deep cleaning the pods doesn't fix module errors, Xcode's workspace is likely corrupted. This process forces a complete reset.

1.  **Quit Xcode**: From the menu bar, select **Xcode > Quit Xcode**.
2.  **Run `flutter pub get`**: In the **Terminal**, navigate to the project root and run `pub get` to ensure all Flutter dependencies are correct.
    ```bash
    cd /Users/builder/clone
    flutter pub get
    ```
3.  **Navigate to `ios` directory**:
    ```bash
    cd ios
    ```
4.  **Delete Workspace**: Delete the corrupted Xcode workspace file.
    ```bash
    rm -rf Runner.xcworkspace
    ```
5.  **Re-create Workspace**: Re-run the pod installation to create a fresh, clean workspace file.
    ```bash
    pod install --repo-update
    ```
6.  **Re-open Xcode**: Open the newly created workspace.
    ```bash
    xed .
    ```
7.  **Re-add Project Items**: Since the workspace was reset, you must re-add the following items in Xcode:
    *   Drag and drop the **`GoogleService-Info.plist`** file back into the `Runner` folder.
    *   Go to **Signing & Capabilities** and re-add the **Push Notifications** capability.
8.  **Run the App**: Click the **Run (▶)** button.

1.  **Fix `Generated.xcconfig` Error**:
    *   The first build will likely fail with a `Generated.xcconfig not found` error.
    *   In the **Terminal**, run the following commands to generate the necessary Flutter files for Xcode:
      ```bash
      flutter pub get
      flutter build ios --simulator
      ```

2.  **Fix `Module not found` Errors (The Deep Clean)**:
    *   If builds fail with errors like `Module 'firebase_auth' not found`, it indicates a problem with the CocoaPods installation. The most reliable fix is a deep clean.
    *   In the **Terminal**, navigate to the `ios` directory:
      ```bash
      cd ios
      ```
    *   Then, remove the old pod files and reinstall them completely:
      ```bash
      rm -rf Pods Podfile.lock
      pod install --repo-update
      ```

3.  **Handle Xcode Project Reload**:
    *   After the `pod install` command, Xcode will detect that the project file has changed.
    *   A dialog box will appear asking if you want to "Keep Xcode Version" or "Use Version on Disk".
    *   **Always select "Use Version on Disk"**. This loads the new configuration from CocoaPods.

4.  **Fix Search Path Errors**:
    *   If build errors persist, clean the build folder in **Xcode** by going to the menu bar and selecting **Product > Clean Build Folder**.

5.  **Enable Push Notifications**:
    *   The root cause of the splash screen hang is often a missing `aps-environment` entitlement. This is because Firebase Cloud Messaging tries to register for push notifications and fails.
    *   In Xcode, with the **Runner** project selected, go to the **Signing & Capabilities** tab.
    *   Click the **+ Capability** button.
    *   Search for and add **Push Notifications**.

6.  **Run the App**: After completing all the above steps, click the **Run (▶)** button in Xcode. The app should now build and launch successfully in the simulator.

5.  **View Logs**: The Xcode debug console at the bottom of the window will display all your app's logs. Watch this for errors when the splash screen appears.

---

### ✅ **Step 4: Resume the Build**

After you have finished debugging:

1.  **Return to the Terminal**: Go back to the terminal window where the build is paused.
2.  **Press Enter**: Press the **Enter** key to resume the build process.
3.  **Disconnect**: You can now close your VNC client. The build will continue and deploy to TestFlight if successful.
