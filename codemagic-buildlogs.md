== Gathering artifacts ==

== Publishing artifacts ==

Publishing artifact safejet_exchange.ipa
Publishing artifact Runner.app.zip
Publishing artifact Runner.app.dSYM.zip
Publishing safejet_exchange.ipa to App Store Connect
> app-store-connect publish --path /Users/builder/clone/build/ios/ipa/safejet_exchange.ipa --key-id X34JL7DAKG --issuer-id 90f3e8fa-7772-4017-a8aa-3e8bd09d1f8b --private-key @env:APP_STORE_CONNECT_PUBLISHER_PRIVATE_KEY

Publish "/Users/builder/clone/build/ios/ipa/safejet_exchange.ipa" to App Store Connect
App name: NadiaPoint Exchange
Bundle identifier: com.nadiapoint.exchange
Certificate expires: 2026-08-11T07:42:45.000+0000
Distribution type: App Store
Min OS version: 13.0
Provisioned devices: N/A
Provisions all devices: No
Supported platforms: iPhoneOS
Version code: 1
Version: 1.0.0

Upload "/Users/builder/clone/build/ios/ipa/safejet_exchange.ipa" to App Store Connect
Running altool at path '/Applications/Xcode-16.4.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Frameworks/AppStoreService.framework/Support/altool'...
Running altool at path '/Applications/Xcode-16.4.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Frameworks/AppStoreService.framework/Support/altool'...
{"tool-version":"8.303.16303","tool-path":"\/Applications\/Xcode-16.4.app\/Contents\/SharedFrameworks\/ContentDeliveryServices.framework\/Versions\/A\/Frameworks\/AppStoreService.framework","os-version":"15.5.0","product-errors":[{"code":-19000,"message":"No suitable application records were found. Verify your bundle identifier “com.nadiapoint.exchange” is correct and that you are signed in with an Apple ID that has access to the app in App Store Connect.","code-string":"ITunesSoftwareServiceApplicationMustEndWithProperExtension","userInfo":{"NSLocalizedFailureReason":"App Store operation failed.","NSLocalizedRecoverySuggestion":"No suitable application records were found. Verify your bundle identifier “com.nadiapoint.exchange” is correct and that you are signed in with an Apple ID that has access to the app in App Store Connect.","NSLocalizedDescription":"No suitable application records were found. Verify your bundle identifier “com.nadiapoint.exchange” is correct and that you are signed in with an Apple ID that has access to the app in App Store Connect."}}]}


Failed to upload archive at "/Users/builder/clone/build/ios/ipa/safejet_exchange.ipa"
Failed to publish /Users/builder/clone/build/ios/ipa/safejet_exchange.ipa

Failed to publish safejet_exchange.ipa to App Store Connect.

Build failed :|


Publishing failed :|
Failed to publish safejet_exchange.ipa to App Store Connect.

