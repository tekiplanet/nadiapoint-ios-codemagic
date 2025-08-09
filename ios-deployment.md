### iOS Deployment Readiness Report (NadiaPoint Exchange)

This report reviews iOS configuration and readiness for Bitrise CI and App Store submission.

> Note for future me: I am new to iOS deployment. Please keep all steps explicit and beginner-friendly.

## Identifiers crash course (very short)
- **Bundle ID**: Reverse-DNS string embedded in the app, e.g. `com.nadiapoint.exchange`.
- **Team ID (App ID Prefix)**: Your Apple Developer Team identifier, shown as the App ID Prefix.
- **App ID (Identifier)**: Team ID + Bundle ID. For explicit apps it looks like `<TEAM_ID>.com.nadiapoint.exchange`.

## How to find my App ID
1) Go to Apple Developer Portal → Certificates, Identifiers & Profiles → Identifiers.
2) Search for `com.nadiapoint.exchange` and open it.
3) On that screen you will see:
   - **Bundle ID**: `com.nadiapoint.exchange`
   - **App ID Prefix (Team ID)**: your team code (e.g., `J3RMZWZ73D`)
4) Your full App ID is: `<App ID Prefix>.<Bundle ID>` → e.g., `J3RMZWZ73D.com.nadiapoint.exchange`.
5) If the page looks like your screenshot (Edit App ID Configuration) you already have the identifier. Click Save if you changed anything.

## If the App ID does not exist (create it)
1) In Identifiers, click the + button → choose App IDs → App → Continue.
2) Select **Explicit** and enter `com.nadiapoint.exchange` as the Bundle ID.
3) Enable needed capabilities now (at least Push Notifications). You can add others later.
4) Register. The App ID will then appear with the App ID Prefix (Team ID).

## App Identity & Versions
- **Display name**: NadiaPoint Exchange
- **Bundle identifier**: com.nadiapoint.exchange (updated)
- **iOS deployment target**: 13.0
- **App version/build**: from Flutter `version: 1.0.0+1` unless overridden at build

Checklist
- [x] Bundle identifier set in `ios/Runner.xcodeproj/project.pbxproj` to `com.nadiapoint.exchange`
- [x] iOS Minimum OS set to 13.0 in project and `ios/Flutter/AppFrameworkInfo.plist`

## Permissions (Info.plist)
Configured in `ios/Runner/Info.plist`:
- [x] NSCameraUsageDescription
- [x] NSMicrophoneUsageDescription (video verification)
- [x] NSPhotoLibraryUsageDescription
- [x] NSPhotoLibraryAddUsageDescription
- [x] NSFaceIDUsageDescription (for `local_auth`)
- [x] UIBackgroundModes: `fetch`, `remote-notification` (for FCM/APNs)
- [x] LSApplicationQueriesSchemes: facebook/google schemes for social auth

 Pending/Confirm
- [x] CFBundleURLTypes for Google sign-in (added)
- [x] Add `GoogleService-Info.plist` for Firebase (Messaging/Auth/Core) — present at `ios/Runner/GoogleService-Info.plist` and copied into app bundle at build

## Icons
Located in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- [x] All required iPhone/iPad sizes present, including 1024 marketing icon
- [x] `pubspec.yaml` uses `flutter_launcher_icons` with iOS true
Action
- [ ] If icon has changed, run: `dart run flutter_launcher_icons`

## Splash / Launch Screen
- Assets: `LaunchBackground.imageset`, `LaunchImage.imageset`
- Storyboard: `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `pubspec.yaml` configured for iOS splash (`flutter_native_splash`)
Actions
- [ ] If splash assets/colors changed, run: `dart run flutter_native_splash:create`

## Plugins and iOS Notes
- Firebase: `firebase_core`, `firebase_auth`, `firebase_messaging`
  - Requires `GoogleService-Info.plist` and APNs setup in Apple Developer
 - Social: `google_sign_in` (Facebook intentionally omitted)
   - Google scheme added from REVERSED_CLIENT_ID; no Facebook App ID configured
- Auth: `local_auth` (Face ID/Touch ID) – Face ID key added
- Media: `image_picker`, `flutter_image_compress`, `image_cropper` – Photo/Camera ok
- Scanner: `mobile_scanner` – Camera ok
- Web: `webview_flutter`, `url_launcher` – no extra plist keys needed; add ATS exceptions only if using non-HTTPS URLs

## Networking / ATS
- Found default fallbacks to `http://localhost:3000` in code. For release builds, ensure `.env` sets `API_URL` to an HTTPS endpoint.
- If any non-HTTPS endpoints are required on iOS, add `NSAppTransportSecurity` exceptions (not currently present).

## Push Notifications (APNs/FCM)
- Skipping for this release. `UIBackgroundModes` for push removed from `Info.plist` to avoid review questions.
- To enable later: turn on Push capability, create/download APNs key, upload to Firebase, and re-add `remote-notification` background mode.

### Enable Push on App ID (what to click on your screen)
1) Check only **Push Notifications**.
2) Leave **Broadcast Capability** unchecked (not needed for standard FCM pushes).
3) Click **Confirm**, then click **Save** on the page.
4) Apple will invalidate existing provisioning profiles; re-create the App Store profile for `com.nadiapoint.exchange`.

### Create APNs key and connect to Firebase
1) Apple Developer → **Keys** → + → name it e.g. "APNs Key" → check **Apple Push Notifications service (APNs)** → Continue → Register → Download `.p8`.
2) Note the **Key ID** from the Keys list and your **Team ID** (App ID Prefix).
3) Firebase Console → Project settings → Cloud Messaging → iOS app → **APNs Authentication Key** → upload the `.p8`, enter **Key ID** and **Team ID** → Save.
4) Reinstall the app on a device and test FCM.

### If you can't download the APNs key (already downloaded once)
- Apple allows each APNs Auth Key to be downloaded only once. If you see the message "Auth Key can only be downloaded once", you have two options:
  1) Ask your teammate or check your password manager/cloud storage for the previously downloaded `.p8` file.
  2) If you cannot find it, click **Revoke** on that key, then create a new APNs key and download the new `.p8`. Update Firebase with the new key (Key ID will change). No client app changes are needed.
- Best practice: store the `.p8` securely (password manager or secure cloud) and record the **Key ID** and **Team ID** in this document.

### Where exactly is the .p8 file after creation?
- On the final "Key Registered" screen (immediately after you click Register), Apple shows a **Download** button. You must click it on that screen before navigating away.
- The file name is `AuthKey_<KEY_ID>.p8` (for example: `AuthKey_V448SVZB6C.p8`).
- It saves to your browser's default Downloads folder:
  - Windows Chrome/Edge: `C:\Users\<you>\Downloads\`
  - Check browser downloads: Chrome `Ctrl+J` (chrome://downloads), Edge `Ctrl+J` (edge://downloads).
- If you created the key and then opened the Key Details page later, the Download button will be greyed out and you cannot download again. You must revoke and recreate.

Troubleshooting if no file appears
- Stay on the "Key Registered" confirmation page and click **Download** there. Do not refresh or navigate away.
- Disable pop-up/download blockers and extensions for `developer.apple.com` and try again.
- Try another browser or Incognito/Private window, sign in again, and recreate the key.
- Confirm your browser is not asking "Always open certain file types"; check the downloads tray.
- Search your PC for `AuthKey_*.p8`.

## CocoaPods / Build Settings
- Podfile platform iOS 13.0; has extra Specs source for SumSub (Idensic)
- Ensure Bitrise runs `pod install` with Ruby/CocoaPods preinstalled

## Code Signing (Bitrise)
- [ ] Create App ID for `com.nadiapoint.exchange`
- [ ] Create/Upload Distribution certificate (.p12) and App Store provisioning profile to Bitrise
- [ ] Configure Bitrise iOS workflow: Flutter build, Cocoapods install, Xcode Archive & Export

## App Store Compliance
- App icon: no transparency, squared. Present.
- Privacy: Data usage descriptions present for camera/mic/photos/biometrics.
- Tracking: Not used explicitly; add ATT if you introduce cross-app tracking or ad SDKs.

## Action Items (Do before Bitrise build)
1) Add `ios/Runner/GoogleService-Info.plist` (done).
2) Configure URL Schemes in `Info.plist`:
   - Google: REVERSED_CLIENT_ID from `GoogleService-Info.plist` (done)
   - Facebook: omitted by choice (no changes required)
3) Enable Push Notifications capability and Background Modes in Xcode (project signing settings) to create entitlements with `aps-environment`.
4) Ensure `.env` (or build config) provides production `API_URL` (HTTPS) at build time.
5) If you changed app icon/splash, run:
   - `dart run flutter_launcher_icons`
   - `dart run flutter_native_splash:create`
6) Set up Bitrise:
   - Steps: Flutter Install, Flutter Pub Get, Flutter Build iOS (or Xcode Archive), Cocoapods Install, Xcode Archive & Export, Deploy to App Store Connect.
   - Upload signing certs/profiles to Bitrise Codesigndoc and set env vars.

## Quick Verification Commands (locally or in CI)
```sh
flutter clean && flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
cd ios && pod repo update && pod install
cd .. && flutter build ios --release --no-codesign
```

## Status
- Ready after completing the Action Items marked [ ] above (Firebase plist, URL Schemes, push capability, HTTPS API URL, codesigning on Bitrise).

