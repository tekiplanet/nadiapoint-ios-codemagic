### iOS Deployment Readiness Report (NadiaPoint Exchange)

This report reviews iOS configuration and readiness for Bitrise CI and App Store submission.

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
- [ ] CFBundleURLTypes for Google/Facebook sign-in callbacks (configured via each plugin’s iOS guide)
- [x] Add `GoogleService-Info.plist` for Firebase (Messaging/Auth/Core)

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
- Social: `google_sign_in`, `flutter_facebook_auth`
  - Requires URL Schemes in Info.plist and App ID configs
- Auth: `local_auth` (Face ID/Touch ID) – Face ID key added
- Media: `image_picker`, `flutter_image_compress`, `image_cropper` – Photo/Camera ok
- Scanner: `mobile_scanner` – Camera ok
- Web: `webview_flutter`, `url_launcher` – no extra plist keys needed; add ATS exceptions only if using non-HTTPS URLs

## Networking / ATS
- Found default fallbacks to `http://localhost:3000` in code. For release builds, ensure `.env` sets `API_URL` to an HTTPS endpoint.
- If any non-HTTPS endpoints are required on iOS, add `NSAppTransportSecurity` exceptions (not currently present).

## Push Notifications (APNs/FCM)
- [x] Background modes set to include `remote-notification`
- [ ] Add `Push Notifications` capability in Xcode (enables `aps-environment` in entitlements)
- [ ] Upload APNs key to Firebase and enable push in Apple Developer portal

## CocoaPods / Build Settings
- Podfile platform iOS 12.0; has extra Specs source for SumSub (Idensic)
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
1) Add `ios/Runner/GoogleService-Info.plist` (download from Firebase console for iOS app with bundle `com.nadiapoint.exchange`).
2) Configure URL Schemes in `Info.plist`:
   - Google: REVERSED_CLIENT_ID from `GoogleService-Info.plist`
   - Facebook: `fb<FACEBOOK_APP_ID>` and `FacebookAppID`/`FacebookDisplayName`
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

