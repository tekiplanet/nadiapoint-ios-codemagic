

== Building for iOS ==

> xcode-project use-profiles
Configure code signing settings
Searching for files matching /Users/builder/Library/MobileDevice/Provisioning Profiles/*.mobileprovision
Searching for files matching /Users/builder/Library/MobileDevice/Provisioning Profiles/*.provisionprofile
List available code signing certificates in keychain /Users/builder/Library/codemagic-cli-tools/keychains/12-08-25_y1b1ryej.keychain-db
Searching for files matching /Users/builder/clone/ios/**/*.xcodeproj
Completed configuring code signing settings
 - Using profile "nadiapoint ios_app_store 1754988941" [6f3bace2-ade2-47d4-81c1-36b18c21139a] for target "Runner" [Debug] from project "Runner"
 - Using profile "nadiapoint ios_app_store 1754988941" [6f3bace2-ade2-47d4-81c1-36b18c21139a] for target "Runner" [Profile] from project "Runner"
 - Using profile "nadiapoint ios_app_store 1754988941" [6f3bace2-ade2-47d4-81c1-36b18c21139a] for target "Runner" [Release] from project "Runner"
Generated options for exporting the project
 - Method: app-store
 - Provisioning Profiles:
     - com.nadiapoint.exchange: nadiapoint ios_app_store 1754988941
 - Signing Certificate: Apple Distribution
 - Signing Style: manual
 - Team Id: J3RMZWZ73D
Saved export options to /Users/builder/export_options.plist

> flutter build ipa --release --export-options-plist /Users/builder/export_options.plist
Resolving dependencies...
Downloading packages...
  _flutterfire_internals 1.3.56 (1.3.60 available)
  animate_do 3.3.4 (4.2.0 available)
  archive 3.6.1 (4.0.7 available)
  carousel_slider 4.2.1 (5.1.1 available)
  characters 1.4.0 (1.4.1 available)
  checked_yaml 2.0.3 (2.0.4 available)
  csslib 0.17.3 (1.0.2 available)
  dio 5.7.0 (5.9.0 available)
  dio_web_adapter 2.0.0 (2.1.1 available)
  facebook_auth_desktop 1.0.3 (2.1.1 available)
  ffi 2.1.3 (2.1.4 available)
  file_selector_macos 0.9.4+2 (0.9.4+3 available)
  file_selector_windows 0.9.3+3 (0.9.3+4 available)
  firebase_auth 5.6.0 (6.0.1 available)
  firebase_auth_platform_interface 7.7.0 (8.1.0 available)
  firebase_auth_web 5.15.0 (6.0.1 available)
  firebase_core 3.14.0 (4.0.0 available)
  firebase_core_platform_interface 5.4.0 (6.0.0 available)
  firebase_core_web 2.23.0 (3.0.0 available)
  firebase_messaging 15.2.7 (16.0.0 available)
  firebase_messaging_platform_interface 4.6.7 (4.7.0 available)
  firebase_messaging_web 3.10.7 (4.0.0 available)
  fl_chart 0.66.2 (1.0.0 available)
  flutter_carousel_widget 2.3.0 (3.1.0 available)
  flutter_facebook_auth 6.2.0 (7.1.2 available)
  flutter_facebook_auth_platform_interface 5.0.0 (6.1.2 available)
  flutter_facebook_auth_web 5.0.0 (6.1.2 available)
  flutter_html 3.0.0-beta.2 (3.0.0 available)
  flutter_idensic_mobile_sdk_plugin 1.35.2 (1.37.1 available)
  flutter_image_compress_common 1.0.5 (1.0.6 available)
  flutter_keyboard_visibility 5.4.1 (6.0.0 available)
  flutter_launcher_icons 0.13.1 (0.14.4 available)
  flutter_lints 4.0.0 (6.0.0 available)
  flutter_native_splash 2.4.4 (2.4.6 available)
  flutter_plugin_android_lifecycle 2.0.24 (2.0.29 available)
  flutter_secure_storage_linux 1.2.2 (2.0.1 available)
  flutter_secure_storage_macos 3.1.3 (4.0.0 available)
  flutter_secure_storage_platform_interface 1.1.2 (2.0.1 available)
  flutter_secure_storage_web 1.2.1 (2.0.0 available)
  flutter_secure_storage_windows 3.1.2 (4.0.0 available)
  flutter_typeahead 4.8.0 (5.2.0 available)
  get_it 7.7.0 (8.2.0 available)
  google_sign_in 6.3.0 (7.1.1 available)
  google_sign_in_android 6.2.1 (7.0.3 available)
  google_sign_in_ios 5.9.0 (6.1.0 available)
  google_sign_in_platform_interface 2.5.0 (3.0.0 available)
  google_sign_in_web 0.12.4+4 (1.0.0 available)
  html 0.15.4 (0.15.6 available)
  http 1.2.2 (1.5.0 available)
  http_parser 4.0.2 (4.1.2 available)
  image 4.3.0 (4.5.4 available)
  image_picker_android 0.8.12+20 (0.8.12+25 available)
  image_picker_linux 0.2.1+1 (0.2.1+2 available)
  image_picker_macos 0.2.1+1 (0.2.1+2 available)
  intl 0.18.1 (0.20.2 available)
  js 0.6.7 (0.7.2 available)
  leak_tracker 10.0.9 (11.0.1 available)
  leak_tracker_flutter_testing 3.0.9 (3.0.10 available)
  leak_tracker_testing 3.0.1 (3.0.2 available)
  lints 4.0.0 (6.0.0 available)
  local_auth_android 1.0.46 (1.0.51 available)
  local_auth_darwin 1.4.2 (1.6.0 available)
  lottie 3.2.0 (3.3.1 available)
  material_color_utilities 0.11.1 (0.13.0 available)
  meta 1.16.0 (1.17.0 available)
  mime 1.0.6 (2.0.0 available)
  mobile_scanner 6.0.10 (7.0.1 available)
  path_provider_android 2.2.15 (2.2.17 available)
  petitparser 6.0.2 (7.0.0 available)
  photo_view 0.14.0 (0.15.0 available)
  pointer_interceptor 0.9.3+7 (0.10.1+2 available)
  provider 6.1.2 (6.1.5 available)
  rive 0.12.4 (0.13.20 available)
  rive_common 0.2.8 (0.4.15 available)
  share_plus 7.2.2 (11.1.0 available)
  share_plus_platform_interface 3.4.0 (6.1.0 available)
  shared_preferences 2.3.5 (2.5.3 available)
  shared_preferences_android 2.4.0 (2.4.11 available)
  shared_preferences_web 2.4.2 (2.4.3 available)
  socket_io_client 2.0.3+1 (3.1.2 available)
  socket_io_common 2.0.3 (3.1.1 available)
  test_api 0.7.4 (0.7.7 available)
  timezone 0.9.4 (0.10.1 available)
  url_launcher 6.3.1 (6.3.2 available)
  url_launcher_android 6.3.14 (6.3.17 available)
  url_launcher_ios 6.3.2 (6.3.3 available)
  url_launcher_web 2.3.3 (2.4.1 available)
  url_launcher_windows 3.1.3 (3.1.4 available)
  vector_math 2.1.4 (2.2.0 available)
  vm_service 15.0.0 (15.0.2 available)
  web 1.1.0 (1.1.1 available)
  webview_flutter 4.10.0 (4.13.0 available)
  webview_flutter_android 4.2.0 (4.9.1 available)
  webview_flutter_platform_interface 2.10.0 (2.14.0 available)
  webview_flutter_wkwebview 3.16.3 (3.23.0 available)
  win32 5.10.0 (5.14.0 available)
  xml 6.5.0 (6.6.0 available)
Got dependencies!
97 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Archiving com.nadiapoint.exchange...
.gitignore does not ignore Swift Package Manager build directories, updating.
Upgrading Runner.xcscheme
Automatically signing iOS for device deployment using specified development team in Xcode project: J3RMZWZ73D
Running pod install...                                             73.5s
Running Xcode build...                                          
Xcode archive done.                                         113.8s
✓ Built build/ios/archive/Runner.xcarchive (361.8MB)

[✓] App Settings Validation
    • Version Number: 1.0.0
    • Build Number: 2
    • Display Name: NadiaPoint Exchange
    • Deployment Target: 13.0
    • Bundle Identifier: com.nadiapoint.exchange

To update the settings, please refer to https://flutter.dev/to/ios-deploy

Building App Store IPA...                                          11.9s
✓ Built IPA to build/ios/ipa (54.8MB)
To upload to the App Store either:
    1. Drag and drop the "build/ios/ipa/*.ipa" bundle into the Apple Transporter macOS app https://apps.apple.com/us/app/transporter/id1450874784
    2. Run "xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey your_api_key --apiIssuer your_issuer_id".
       See "man altool" for details about how to authenticate with the App Store Connect API key.