# Apple Internal Testing Guide

This guide documents the steps for managing and distributing builds via TestFlight.

---

### ✅ **Step 1: Handle Export Compliance**

After your first build, App Store Connect will flag it with "Missing Compliance." This is a one-time setup.

1.  **Navigate to TestFlight**: In App Store Connect, go to your app's **TestFlight** tab.
2.  **Manage Compliance**: Click **Manage** next to the build warning. 
3.  **Answer Encryption Question**: Select `Standard encryption algorithms...`.
4.  **Answer French Distribution Question**: Select **No**.
5.  **Save**. This process is automated for future builds by a key we added to `Info.plist`.

---

### ✅ **Step 2: Add Testers to Your Team**

Testers must be invited to your App Store Connect team before they can test builds.

1.  **Navigate to Users and Access**.
2.  **Invite New User**: Click the **+** icon and fill in their name and email address.
3.  **Assign Role**: Assign a role like `Developer` or `App Manager`.
4.  **Send Invitation**: Click **Invite**. The user must accept the email invitation.

*Note: Testers only need a standard Apple ID; they do not need a paid developer account.*

---

### ✅ **Step 3: Create a Test Group and Invite Testers**

1.  **Navigate to Internal Testing**: In the **TestFlight** tab, click **Internal Testing**.
2.  **Create Group**: Click the **+** icon, name the group (e.g., `Internal Testers`), and click **Create**.
3.  **Add Testers to Group**: Select the new group, click the **+** icon next to "Testers," and add your team members.
4.  **Notifications**: Testers will receive an email with instructions to download the app via TestFlight.

---

### ✅ **Step 4: Handle Common Build Issues**

If a new build fails, check for these common issues.

-   **Issue**: `Missing purpose string` (e.g., for `NSLocationWhenInUseUsageDescription`).
    -   **Resolution**: Add the required privacy key to `ios/Runner/Info.plist`. We have already done this for the location permission.

-   **Issue**: `The bundle version must be higher than the previously uploaded version`.
    -   **Resolution**: Before starting a new build, increment the build number in `pubspec.yaml` (e.g., `version: 1.0.0+2` to `1.0.0+3`).
