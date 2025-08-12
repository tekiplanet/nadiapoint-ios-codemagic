# Apple Internal Testing Guide

This guide documents the steps for managing and distributing builds via TestFlight.

---

### ✅ **Step 1: Handle Export Compliance**

After a successful build, App Store Connect will flag the build with "Missing Compliance." This is a mandatory check to see if your app uses non-standard encryption.

1.  **Navigate to TestFlight**: In App Store Connect, go to your app's **TestFlight** tab.
2.  **Find the Build**: Locate the build with the yellow warning icon.
3.  **Manage Compliance**: Click **Manage** next to the warning. A popup titled **App Encryption Documentation** will appear.
4.  **Select the Correct Option**: For most apps using standard HTTPS for API calls, the correct option is:
    -   `Standard encryption algorithms instead of, or in addition to, using or accessing the encryption within Apple's operating system`
5.  **Select the Correct Option**: For most apps using standard HTTPS for API calls, the correct option is:
    -   `Standard encryption algorithms instead of, or in addition to, using or accessing the encryption within Apple's operating system`
6.  **Answer French Distribution Question**: On the next screen, when asked if the app will be available for distribution in France, select **No** (unless you have specific authorization).
7.  **Save**: Click **Save**.

To automate this for future builds, we have added the `ITSAppUsesNonExemptEncryption` key (set to `false`) to the `Info.plist` file.

---

### ✅ **Step 2: Invite Internal Testers**

Once the build is marked as "Ready to Test," you can invite your team to try it out.

1.  **Navigate to Internal Testing**: In App Store Connect, go to the **TestFlight** tab and click on **Internal Testing** in the left sidebar.
2.  **Create an Internal Group**: Click the **+** icon next to "Internal Testing." A dialog will appear.
    -   **Group Name**: Give the group a descriptive name (e.g., `Internal Testers`).
    -   **Enable automatic distribution**: Keep this checked. This ensures all new builds are automatically sent to this group.
    -   Click **Create**.
3.  **Add Testers to the Group**: Once the group is created, you can select it and add testers by clicking the **+** icon next to the "Testers" section within the group.
3.  **Testers Receive an Email**: Once added, each tester will receive an email invitation with a link to install the build via the **TestFlight app** on their iOS device.
4.  **Monitor Feedback**: You can track installation status, sessions, and crashes for each tester directly within the TestFlight section.

---

### ✅ **Step 3: Handle Common Build Warnings**

Even after a successful build, you may receive emails from Apple about non-blocking issues. It's best to resolve these for the next build.

-   **Issue**: `ITMS-90683: Missing purpose string in Info.plist` for `NSLocationWhenInUseUsageDescription`.
-   **Meaning**: Your app (or a dependency) has the capability to access user location, and you must explain why.
-   **Resolution**: Add the `NSLocationWhenInUseUsageDescription` key to your `ios/Runner/Info.plist` file with a user-facing description. We have already done this for the next build.

-   **Issue**: Build fails during the "Publishing to App Store Connect" step with the error `The bundle version must be higher than the previously uploaded version`.
-   **Meaning**: You cannot upload a new build with the same build number as one that already exists in App Store Connect.
-   **Resolution**: Before starting a new build, increment the build number in your `pubspec.yaml` file. For example, change `version: 1.0.0+1` to `version: 1.0.0+2`. We have already done this.
