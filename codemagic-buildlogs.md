== Gathering artifacts ==

== Publishing artifacts ==

Publishing artifact nadiapoint.ipa
Publishing artifact Runner.app.zip
Publishing artifact Runner.app.dSYM.zip
Publishing nadiapoint.ipa to App Store Connect
> app-store-connect publish --path /Users/builder/clone/build/ios/ipa/nadiapoint.ipa --key-id X34JL7DAKG --issuer-id 90f3e8fa-7772-4017-a8aa-3e8bd09d1f8b --private-key @env:APP_STORE_CONNECT_PUBLISHER_PRIVATE_KEY

Publish "/Users/builder/clone/build/ios/ipa/nadiapoint.ipa" to App Store Connect
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

Upload "/Users/builder/clone/build/ios/ipa/nadiapoint.ipa" to App Store Connect
Running altool at path '/Applications/Xcode-16.4.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Frameworks/AppStoreService.framework/Support/altool'...
Running altool at path '/Applications/Xcode-16.4.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Frameworks/AppStoreService.framework/Support/altool'...
2025-08-12 10:12:55.598 ERROR: [altool.600003708180] [ContentDelivery.Uploader.600003708180] The provided entity includes an attribute with a value that has already been used (-19232) The bundle version must be higher than the previously uploaded version: ‘1’. (ID: de67e1e6-3358-496a-b567-d6c3023f1a6c)
{"tool-version":"8.303.16303","tool-path":"\/Applications\/Xcode-16.4.app\/Contents\/SharedFrameworks\/ContentDeliveryServices.framework\/Versions\/A\/Frameworks\/AppStoreService.framework","os-version":"15.5.0","product-errors":[{"message":"The provided entity includes an attribute with a value that has already been used","userInfo":{"NSUnderlyingError":"Error Domain=IrisAPI Code=-19241 \"The provided entity includes an attribute with a value that has already been used\" UserInfo={status=409, detail=The bundle version must be higher than the previously uploaded version., source={\n    pointer = \"\/data\/attributes\/cfBundleVersion\";\n}, id=de67e1e6-3358-496a-b567-d6c3023f1a6c, code=ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE, title=The provided entity includes an attribute with a value that has already been used, meta={\n    previousBundleVersion = 1;\n}, NSLocalizedDescription=The provided entity includes an attribute with a value that has already been used, NSLocalizedFailureReason=The bundle version must be higher than the previously uploaded version.}","NSLocalizedDescription":"The provided entity includes an attribute with a value that has already been used","previousBundleVersion":"1","iris-code":"ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE","NSLocalizedFailureReason":"The bundle version must be higher than the previously uploaded version: ‘1’. (ID: de67e1e6-3358-496a-b567-d6c3023f1a6c)"},"code":-19232}]}


Failed to upload archive at "/Users/builder/clone/build/ios/ipa/nadiapoint.ipa"
Failed to publish /Users/builder/clone/build/ios/ipa/nadiapoint.ipa

Failed to publish nadiapoint.ipa to App Store Connect.

Build failed :|


Publishing failed :|
Failed to publish nadiapoint.ipa to App Store Connect.
