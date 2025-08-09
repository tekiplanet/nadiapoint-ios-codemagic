### Bitrise iOS Deploy — One-Step-at-a-Time Checklist

Use this list from top to bottom. Do the next unchecked item and come back.

#### 0) Confirm these basics
- [ ] You can sign in to Apple Developer / App Store Connect
- [ ] Bundle ID for this app: `com.nadiapoint.exchange`
- [ ] File exists in repo: `ios/Runner/GoogleService-Info.plist`

#### 1) Create an App Store Connect API Key (one time)
- [x] Open App Store Connect → Users and Access → Integrations → App Store Connect API → Keys
- [x] Click “Generate API Key” (or +)
- [x] Name it anything (e.g., NadiaPoint CI), Role: App Manager
- [x] On the Keys list, click **Download** next to your key → save the `.p8` file
- [x] Copy the **Issuer ID** (top of the page) and the key’s **Key ID** (table column)
- [x] Keep the `.p8`, Issuer ID, and Key ID handy for the next step

Tip: If you cannot see “Integrations” or “App Store Connect API,” you must be signed in as the **Account Holder** or **Admin**. Ask the Account Holder to grant Admin, or have them create the key and send you the `.p8`, Issuer ID, and Key ID.

#### 2) Add that key in Bitrise (code signing)
- [x] In Bitrise, open your app → Project settings → Code signing → click **Set up connection**
- [x] You will land on Project settings → **Integrations → Stores → App Store Connect**
- [x] Click **Add API key** (Recommended)
- [x] Fill the form:
  - Name: `NadiaPoint CI`
  - Issuer ID: paste from App Store Connect
  - Key ID: paste from App Store Connect
  - Private key: upload the `.p8` you downloaded
  - Team: pick your Apple team (if asked)
- [x] If it redirects to Workspace settings, add the key there, then come back to this screen and select it
- [x] Return to Project settings → **Code signing** and confirm the “App Store connection” now shows your team (not “None selected”)

#### 2.5) Stop automatic builds from webhooks (optional)
- [ ] In Bitrise, click **Workflows** (top right) → **Triggers** tab
- [ ] In the workflow dropdown (top-left), switch to `primary` and repeat the same check
- [ ] In the “Build trigger map”, remove all rows for Push, Pull request, and Tag (trash/bin icon at row end)
- [ ] Ensure **Enable triggers** toggle is OFF for each workflow you use (especially `primary`)
- [ ] Click **Save changes** (top right)
- Note: The “Automatic webhook: Connected” can stay; with an empty trigger map, pushes/PRs won’t start builds. You can still start builds manually from the Builds page.

#### 3) Configure the workflow steps
- [ ] Open Bitrise → **Workflows** (top right)
- [ ] Select the default workflow (often `primary`)
- How to add a step here:
  - Click the `Flutter Install` tile once so it’s selected
  - Move your mouse just below it → click the purple **+ Add step** button that appears
  - A Step Library pops up → search the step name → click **Add**
  - Repeat: hover below the last step → **+ Add step** for the next item
- [ ] Clean up old steps (if present): delete `Certificate and profile installer`, `Flutter Analyze`, `Flutter Test`, `Flutter Build`, and `Deploy to Bitrise.io - Build Artifacts` (trash/bin icon on each). Keep `Git Clone Repository` at the top.
- [ ] Add and order the steps exactly like this (top to bottom):
  1. Flutter Install
  2. Flutter Pub Get
  3. CocoaPods Install
  4. Manage iOS Code Signing (App Store Connect)
  5. Xcode Archive & Export for iOS
  6. Deploy to App Store Connect (TestFlight)
- [ ] In “Manage iOS Code Signing” set:
  - Apple service connection method: Default (api-key)
  - Distribution: `app-store`
  - Project path: `ios/Runner.xcworkspace`
  - Scheme: `Runner`
  - Build configuration: `Release`
- [ ] Click the “Xcode Archive & Export for iOS” step and set:
  - Project path: `ios/Runner.xcworkspace`
  - Scheme: `Runner`
  - Export method: `app-store`
- [ ] In “Deploy to App Store Connect” → select the same API key integration
- [ ] Save the workflow

If you cannot find “Flutter Pub Get” in the Step Library
- Add a step named **Script** right after `Flutter Install`
- Script content:
  ```bash
  #!/bin/bash
  set -ex
  flutter pub get
  ```

 Progress (mark as you go)
- [x] Added Script step to run `flutter pub get`
- [x] Added CocoaPods Install (choose step named “Run CocoaPods install”; set Workdir to `$BITRISE_SOURCE_DIR/ios`, leave others default)
- [x] Added Manage iOS Code Signing and configured fields
- [ ] Configured Xcode Archive & Export for iOS
- [ ] Added Deploy to App Store Connect
- [ ] Saved workflow

- Notes while adding steps
- If you can’t find “iOS Auto Provision with App Store Connect”, use the newer step named “Manage iOS Code Signing” (it replaces Auto Provision). If neither shows:
  1) Click **Clear filters** and search `Code Signing`.
  2) Click the **Step bundle** tab and ensure “Bitrise Step Library (Official)” is enabled, then search again.
  3) If still nothing, continue with the next step (Xcode Archive & Export) and we’ll revisit.
- Configure Auto Provision: Connection = your API key, Distribution type = `app-store`, Bundle ID = `com.nadiapoint.exchange`.

#### 4) Start a build
- [ ] Go to Builds → click “Start build” (branch `main`) or “Rebuild” the last one

#### 5) After it turns green
- [ ] Open App Store Connect → My Apps → your app → TestFlight and wait for the new build to appear (10–20 mins)

#### If the build fails (quick checks)
- [ ] Signing error: make sure the Auto Provision step is before Xcode Archive and uses the correct Bundle ID + API key
- [ ] Workspace/scheme error: ensure `ios/Runner.xcworkspace` and `Runner` are set in the Xcode Archive step
- [ ] CocoaPods error: ensure “CocoaPods Install” step exists and is before Xcode Archive
- [ ] To see details: open the failed build → Logs → scroll to the first red error


