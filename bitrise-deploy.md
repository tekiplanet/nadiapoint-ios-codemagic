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
- **CRITICAL**: Make sure **Git Clone Repository** step is at the very top of your workflow (this clones your code before other steps run)
- How to add a step here:
  - Click the `Flutter Install` tile once so it's selected
  - Move your mouse just below it → click the purple **+ Add step** button that appears
  - A Step Library pops up → search the step name → click **Add**
  - Repeat: hover below the last step → **+ Add step** for the next item
- [ ] Clean up old steps (if present): delete `Certificate and profile installer`, `Flutter Analyze`, `Flutter Test`, `Flutter Build`, and `Deploy to Bitrise.io - Build Artifacts` (trash/bin icon on each). Keep `Git Clone Repository` at the top.
- [ ] Add and order the steps exactly like this (top to bottom):
  1. **Git Clone Repository** (MUST be first!)
  2. Flutter Install
  3. Flutter Pub Get
  4. CocoaPods Install
  5. Manage iOS Code Signing (App Store Connect)
  6. Xcode Archive & Export for iOS
  7. Deploy to App Store Connect (TestFlight)
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

If you cannot find "Flutter Pub Get" in the Step Library
- Add a step named **Script** right after `Flutter Install`
- Script content:
  ```bash
  #!/bin/bash
  set -ex
  flutter pub get
  ```
- **IMPORTANT**: Set the **Working Directory** to `$BITRISE_SOURCE_DIR` (this is the project root)

 Progress (mark as you go)
- [x] Added Script step to run `flutter pub get`
- [x] Added CocoaPods Install (choose step named "Run CocoaPods install"; set Workdir to `$BITRISE_SOURCE_DIR/ios`, leave others default)
- [x] Added Manage iOS Code Signing and configured fields
- [x] Configured Xcode Archive & Export for iOS
- [x] Added Deploy to App Store Connect
- [ ] Saved workflow

- Notes while adding steps
- If you can’t find “iOS Auto Provision with App Store Connect”, use the newer step named “Manage iOS Code Signing” (it replaces Auto Provision). If neither shows:
  1) Click **Clear filters** and search `Code Signing`.
  2) Click the **Step bundle** tab and ensure “Bitrise Step Library (Official)” is enabled, then search again.
  3) If still nothing, continue with the next step (Xcode Archive & Export) and we’ll revisit.
- Configure Auto Provision: Connection = your API key, Distribution type = `app-store`, Bundle ID = `com.nadiapoint.exchange`.

#### 4) Start a build
- [ ] Go to Builds → click "Start build" (branch `main`) or "Rebuild" the last one

**⚠️ IMPORTANT: Which workflow will be used?**

When you click "Start build", Bitrise will use the **default workflow** for your app. Here's how to confirm which one that is:

1. **Check the default workflow**:
   - Go to **Workflows** (top right) → **Triggers** tab
   - Look at the workflow dropdown (top-left) - this shows your current default
   - If it says `primary`, that's what will be used when you click "Start build"
   - If it says `deploy`, then `deploy` will be used

2. **If you want to use a specific workflow**:
   - When clicking "Start build", you can also:
     - Click the **down arrow** next to "Start build" 
     - Select your preferred workflow from the dropdown
     - Or use "Start/Schedule a Build" → select workflow manually

3. **To change the default workflow**:
   - Go to **Workflows** → **Triggers** tab
   - Use the workflow dropdown to select `primary` (or whichever you want as default)
   - Click **Save changes**

**Current recommendation**: Make sure `primary` is selected as your default workflow since that's the one we configured for iOS deployment.

#### 5) After it turns green
- [ ] Open App Store Connect → My Apps → your app → TestFlight and wait for the new build to appear (10–20 mins)

### 🚨 CURRENT ISSUE - CODE SIGNING PROBLEM (AS OF 2025-08-09)

**STATUS**: ❌ **BUILD FAILING** - Xcode Archive step failing due to code signing configuration

**EXACT ERROR**:
```
/Users/[REDACTED]/git/ios/Runner.xcodeproj: error: Signing for "Runner" requires a development team. Select a development team in the Signing & Capabilities editor.
```

**ROOT CAUSE ANALYSIS**:
1. ✅ **NadiaPoint CI API key is properly configured** in Bitrise Code signing section
2. ✅ **Git Clone Repository, Flutter Install, Script steps** are working correctly
3. ❌ **Xcode Archive step** has `automatic_code_signing: off` in the build log
4. ❌ **API key credentials** are not being passed to the Xcode Archive step (`api_key_path: <unset>`, `api_key_id: <unset>`, `api_key_issuer_id: <unset>`)

**PROBLEM**: The Xcode Archive step is not configured to use the API key for automatic code signing. Even though the API key is configured in Bitrise, the step itself needs to be told to use it.

**SOLUTION REQUIRED**:

**Option A: Configure Xcode Archive Step with API Key (Recommended)**
1. Open your **Xcode Archive & Export for iOS** step in Bitrise
2. Set these fields:
   - **Project path**: `ios/Runner.xcworkspace`
   - **Scheme**: `Runner`
   - **Export method**: `app-store`
   - **Automatic code signing**: `on` ← **CRITICAL CHANGE**
   - **API key path**: Leave empty (should use global config)
   - **API key ID**: Leave empty (should use global config)
   - **API key issuer ID**: Leave empty (should use global config)

**Option B: Add Manage iOS Code Signing Step Back**
1. Add **Manage iOS Code Signing** step before Xcode Archive step
2. Configure it with:
   - **Apple service connection method**: Select "NadiaPoint CI" (your API key)
   - **Distribution**: `app-store`
   - **Project path**: `ios/Runner.xcworkspace`
   - **Scheme**: `Runner`
   - **Build configuration**: `Release`

**WHY THIS HAPPENED**: 
- The "Manage iOS Code Signing" step was removed due to previous configuration issues
- The Xcode Archive step was left with `automatic_code_signing: off`
- Without either the Manage iOS Code Signing step OR automatic code signing enabled in Xcode Archive, the build fails

**NEXT ACTION**: Try **Option A** first (enable automatic code signing in Xcode Archive step) as it's the simplest fix.

#### If the build fails (quick checks)
- [ ] **Git Clone Repository missing**: If you see "Expected to find project root in current working directory" and the directory is empty, you're missing the **Git Clone Repository** step at the very top of your workflow
- [ ] **CocoaPods issues**: If you see "The Podfile does not contain any dependencies" or "Could not automatically select an Xcode workspace":
  1. **Check your Podfile**: Make sure it has dependencies and workspace specification
  2. **Add workspace to Podfile**: Add this line to your `ios/Podfile`:
     ```ruby
     workspace 'Runner.xcworkspace'
     ```
  3. **Alternative**: Skip CocoaPods step if your Flutter project doesn't use native iOS dependencies
  4. **Quick fix**: **Remove the "Run CocoaPods install" step** from your workflow - it's not essential for basic Flutter iOS builds
- [ ] **CocoaPods podhelper.rb error**: If you see "cannot load such file -- ../.ios/Flutter/podhelper.rb":
  1. **CRITICAL**: Make sure the **Script step** (running `flutter pub get`) runs BEFORE the CocoaPods step
  2. **Check Script step working directory**: Ensure it's set to `$BITRISE_SOURCE_DIR` (project root)
  3. **Alternative script content**: If still failing, try this script content:
     ```bash
     #!/bin/bash
     set -ex
     cd $BITRISE_SOURCE_DIR
     flutter clean
     flutter pub get
     # Generate iOS files properly
     flutter build ios --no-codesign --debug
     ```
  4. **Remove CocoaPods step**: If the issue persists, **remove the "Run CocoaPods install" step** entirely - Flutter handles iOS dependencies automatically
- [ ] Signing error: make sure the Auto Provision step is before Xcode Archive and uses the correct Bundle ID + API key
- [ ] Workspace/scheme error: ensure `ios/Runner.xcworkspace` and `Runner` are set in the Xcode Archive step
- [ ] CocoaPods error: ensure "CocoaPods Install" step exists and is before Xcode Archive
- [ ] **Script step directory error**: If you see "Expected to find project root in current working directory", try these solutions:
  1. **First, check if Git Clone Repository step exists**: This step MUST be at the very top of your workflow
  2. **Check if Flutter is properly installed**: The Script step should run after Flutter Install step
  3. **Verify working directory**: Make sure Script step has `$BITRISE_SOURCE_DIR` as Working Directory
  4. **Alternative script content**: If still failing, try this script content:
     ```bash
     #!/bin/bash
     set -ex
     cd $BITRISE_SOURCE_DIR
     pwd
     ls -la
     flutter --version
     flutter pub get
     ```
  5. **Check Flutter Install step**: Make sure Flutter Install step completed successfully (green checkmark)
- [ ] To see details: open the failed build → Logs → scroll to the first red error
- [ ] **Manage iOS Code Signing error**: If you see "CertificateURLList: required variable is not present":
  1. **Check Apple service connection method**: Make sure it's set to "Default (api-key)"
  2. **Select your API key**: In the "Apple service connection method" dropdown, select your "NadiaPoint CI" API key (not "Default (api-key)")
  3. **If API key doesn't appear in dropdown** (even though it's configured):
     - **Try selecting "api-key"** (without "Default") from the dropdown - this should use your configured API key
     - **Alternative**: Try selecting "Default (api-key)" - this should also work if your API key is properly configured
  4. **If still failing with API key method**:
     - **Remove the "Manage iOS Code Signing" step entirely** - it's not essential for basic Flutter iOS builds
     - **Let Xcode Archive step handle code signing automatically** - it will use your API key configuration
  5. **Verify settings**: Ensure these fields are set:
     - Apple service connection method: "api-key" or "Default (api-key)"
     - Distribution method: `app-store`
     - Project path: `ios/Runner.xcworkspace`
     - Scheme: `Runner`
     - Build configuration: `Release`


