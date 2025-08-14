# Firebase Cloud Messaging (FCM) on iOS - Troubleshooting Guide

This document outlines the steps taken to diagnose and resolve issues related to setting up Firebase Push Notifications for the NadiaPoint iOS app, specifically for simulator and remote builds on Codemagic.

## 1. Initial Problem: App Stuck on Splash Screen

- **Symptom**: When building and running the app on a remote macOS machine (via Codemagic) or a local simulator, the application would not proceed past the initial splash screen.
- **Initial Diagnosis**: This behavior often points to an issue with required capabilities or entitlements, particularly when services like Firebase Messaging are initialized at startup.

## 2. Missing Push Notification Capability

- **Investigation**: Checking the Xcode project settings (`Runner.xcworkspace`) revealed that the **Push Notifications** capability was not added to the app target.
- **Action**: Added the Push Notifications capability in Xcode under `Signing & Capabilities`.
- **Result**: This is a necessary step, but did not alone solve the problem. The app still required a valid provisioning profile with the correct entitlements and a configured APNs connection in Firebase.

## 3. APNs Auth Key (.p8) Download Failure

- **Goal**: To enable FCM, an Apple Push Notification service (APNs) connection must be configured in the Firebase project console.
- **Method 1 (Recommended)**: Use an APNs Authentication Key (`.p8` file).
- **Problem**: After creating a new `.p8` key in the Apple Developer portal, the download failed. The portal incorrectly stated, "Auth Key can only be downloaded once," even for a brand new key.
- **Troubleshooting**: This was attempted on multiple browsers, devices, and in private/incognito modes, all without success. Research confirmed this is a **known, ongoing bug** in the Apple Developer portal.

## 4. Alternative: APNs Certificate (.p12)

- **Method 2 (Legacy)**: As a workaround for the `.p8` bug, we switched to using the older APNs Certificate (`.p12`) method.
- **Initial Attempt**: An existing `.p12` distribution certificate was available.
- **Problem**: When uploading this `.p12` file to the Firebase console for the Production environment, it was rejected with the error: **"The certificate bundleId did not match that of your app."**
- **Conclusion**: The existing certificate was created for a different app (with a different Bundle ID) and cannot be used for `com.nadiapoint.exchange`.

## 5. Current Plan: Create New APNs Certificates

Since the `.p8` key is unavailable and the existing `.p12` is invalid, the only path forward is to create **new** APNs certificates specifically for the `com.nadiapoint.exchange` Bundle ID.

We need to create two separate certificates:
1.  **Development SSL Certificate**: For use with simulator/debug builds (to fix the current splash screen issue).
2.  **Production SSL Certificate**: For use with TestFlight and App Store builds.

The process starts by creating a Certificate Signing Request (CSR) on the remote Mac.

## 6. Step-by-Step: Creating a new APNs Certificate

### 6.1. Create a Certificate Signing Request (CSR) via Terminal

This is the first step and must be done on the remote macOS machine.

**Problem**: The `Keychain Access` application is missing from the Codemagic macOS VM image, so the standard GUI method cannot be used.

**Solution**: Use the `openssl` command-line tool in the Terminal to generate the CSR.

1.  **Open Terminal**: The Terminal app is located in the Dock.
2.  **Run `openssl` command**: A specific command will be used to generate a private key (`.key` file) and a Certificate Signing Request (`.certSigningRequest` file).
3.  The `.certSigningRequest` file is then uploaded to the Apple Developer portal to create the new certificate.

4.  **Execute the command**: Copy and paste the following command into the terminal and press Enter. This creates a private key (`nadiapoint.key`) and the CSR file (`nadiapoint.csr`).

    ```bash
    openssl req -new -newkey rsa:2048 -nodes -keyout nadiapoint.key -out nadiapoint.csr -subj "/C=US/ST=Edo/L=Benin/O=NadiaPoint/CN=NadiaPoint"
    ```

### 6.2. Create the Certificate in Apple Developer Portal

1.  **View the CSR content**: Use the `cat` command to display the content of the `.csr` file you just created.

    ```bash
    cat nadiapoint.csr
    ```

2.  **Transfer the CSR**: You need to get the `.csr` file or its contents from the remote Mac to your local machine. You can do this in two ways:
    - **File Transfer (Recommended)**: On the remote Mac, open a web browser, log in to your email (e.g., Gmail), and email the `nadiapoint.csr` file to yourself as an attachment. Download the file on your local machine.
    - **Copy/Paste**: Use the `cat nadiapoint.csr` command to view the content. Copy the entire text block and transfer it to your local machine (e.g., using a shared clipboard or an online notepad like shrib.com).
3.  **Navigate to Apple Developer Portal**: Go to the [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list) section of your developer account.
4.  Click the blue `+` button to add a new certificate.
5.  Under the **Services** section, select **Apple Push Notification service SSL (Sandbox & Production)** and click **Continue**. This single certificate will work for both development and production environments.
6.  **Select App ID**: On the next screen, choose your app's bundle ID (`com.nadiapoint.exchange`) from the dropdown menu and click **Continue**.
7.  **Upload CSR**: Click **Choose File**, select the `nadiapoint.csr` file you transferred from the remote Mac, and click **Continue**.
8.  **Download Certificate**: On the final screen, click the **Download** button. This will save a certificate file (usually named `aps.cer`) to your computer.

### 6.3. Create the .p12 Certificate File

This final step combines your private key and the new certificate into a single `.p12` file that can be uploaded to Firebase.

1.  **Transfer `aps.cer` to Mac**: Transfer the `aps.cer` file from your local computer back to the remote Mac's home directory (the same place where `nadiapoint.key` is stored). Using email is a good method.
2.  **Combine to create .p12**: Run the following command in the terminal on the remote Mac. It will combine `aps.cer` and `nadiapoint.key` into `nadiapoint.p12`.

    ```bash
    openssl pkcs12 -export -in aps.cer -inkey nadiapoint.key -out nadiapoint.p12 -name "NadiaPoint APNS"
    ```

3.  **Set a Password**: The command will prompt you for an `Export Password`. You **must** create and enter a password. Firebase will require this password when you upload the file. Remember it!
4.  **Transfer `.p12` to Local**: Transfer the final `nadiapoint.p12` file from the remote Mac to your local computer.

## 7. Upload Certificate to Firebase

1.  **Navigate to Firebase**: Go to your project in the [Firebase Console](https://console.firebase.google.com/), open **Project Settings** > **Cloud Messaging**.
2.  **Select iOS App**: Make sure your iOS app (`com.nadiapoint.exchange`) is selected.
3.  **Upload Certificate**: Scroll down to the **APNs Certificates** section.
    - Click **Upload** for the **Production APNs certificate**.
    - Select the `nadiapoint.p12` file and enter the password you created.
    - Repeat the process for the **Development APNs certificate**, using the same file and password.

## 8. Regenerate the Provisioning Profile

Now that the App ID has Push Notifications enabled and the APNs certificate is configured, the provisioning profile must be regenerated to include these new entitlements.

1.  **Navigate to Profiles**: In the Apple Developer Portal, go to the **Profiles** section.
2.  **Select Profile**: Find and click on the provisioning profile associated with `com.nadiapoint.exchange`.
3.  **Regenerate**: The profile may be marked as "Invalid". Click the **Edit** and then **Save** (or **Generate**) button to create a new version of the profile. This new version will include the necessary `aps-environment` entitlement.
4.  **Download**: Download the updated `.mobileprovision` file to your local computer.

## 9. Install New Profile, Verify, and Test

1.  **Transfer Profile to Mac**: Transfer the newly downloaded `.mobileprovision` file to the remote Mac (e.g., via email) and save it to the Desktop or Downloads folder.
2.  **Install Profile**: On the remote Mac, find the `.mobileprovision` file and double-click it. Xcode should open and automatically install the profile. There might not be any confirmation message, which is normal.
3.  **Verify Xcode Setup**: Open `ios/Runner.xcworkspace` in Xcode. Select the `Runner` target, then the **Signing & Capabilities** tab. **Confirm that Push Notifications is listed as a capability.** This is a critical check.
4.  **Clean and Build**: Open your project in the terminal on the remote Mac, and run the following commands to ensure a clean build:

    ```bash
    flutter clean
    flutter pub get
    cd ios
    pod install
    cd ..
    flutter run
    ```

4.  **Test**: The app should now build and run without getting stuck on the splash screen. You can then proceed to test if push notifications are being received.