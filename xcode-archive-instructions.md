### iOS Build Signing Fix: Final Steps

This document provides the final instructions to resolve the iOS build signing errors on Bitrise.

---

### Current Status

1.  **Project File Corrected**: The Xcode project (`.pbxproj`) is now correctly configured to use manual signing with the `Apple Distribution` certificate and to look for a provisioning profile named `match AppStore com.nadiapoint.exchange`.

2.  **New Error**: The build is failing with `No profile ... matching 'match AppStore com.nadiapoint.exchange' found`.

3.  **Root Cause**: This error is happening because the required provisioning profile has not been uploaded to your Bitrise project's **Code Signing** section.

---

### **ACTION REQUIRED**: Generate and Upload Provisioning Profile

You must now generate an **App Store** provisioning profile with the correct name and upload it to Bitrise.

**Step 1: Generate the Provisioning Profile**

1.  Log in to your [Apple Developer Account](https://developer.apple.com/account/).
2.  Navigate to **Certificates, Identifiers & Profiles**.
3.  Select **Profiles** from the sidebar.
4.  Click the **+** button to create a new profile.
5.  Under the **Distribution** section, select **App Store** and click **Continue**.
6.  Select the correct App ID: `com.nadiapoint.exchange` and click **Continue**.
7.  Select your active **Apple Distribution** certificate and click **Continue**.
8.  For the **Provisioning Profile Name**, you must enter the name **exactly** as it appears in the project file: `match AppStore com.nadiapoint.exchange`.
9.  Click **Generate**, and then **Download** the `.mobileprovision` file.

**Step 2: Upload the Profile to Bitrise**

1.  Go to your app on **Bitrise.io**.
2.  Navigate to the **Workflow** tab, then select the **Code Signing** tab.
3.  In the **Provisioning Profiles** section, drag and drop (or use the uploader) to add the `.mobileprovision` file you just downloaded.

**Step 3: Run a New Build**

- Once the profile is uploaded, go back to your app's main page and trigger a new build.

This should resolve the final signing error. Please let me know the result of the next build.

### Solution Implemented

Since you don't have access to a macOS machine with Xcode, we performed the following actions directly:

1.  **Manually Edited Project File**: I directly edited the `ios/Runner.xcodeproj/project.pbxproj` file.
2.  **Corrected Signing Identity**: I changed the `CODE_SIGN_IDENTITY` for the `Release` build configuration from `iPhone Developer` to `Apple Distribution`.
3.  **Set Manual Signing Style**: I also set the `CODE_SIGN_STYLE` to `Manual` for the `Release` configuration to ensure it uses the specified certificate.

### Current Status

The necessary changes have been applied to the project file. You should now commit and push these changes, then re-run the Bitrise build.
