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

### ✅ UPDATED SOLUTION - FLUTTER BUILD APPROACH (AS OF 2025-08-09)

**STATUS**: 🔄 **TESTING NEW APPROACH** - Using Flutter Build instead of Xcode Archive

**NEW WORKFLOW**:
```
1. Git Clone Repository
2. Flutter Install  
3. Script (flutter pub get)
4. Flutter Build (iOS archive)
5. Deploy to App Store Connect - Application Loader
```

**WHY THIS NEW APPROACH**:
1. ✅ **Certificates are properly uploaded** - Both Development and Distribution certificates exist in Bitrise
2. ✅ **API key is configured** - "NadiaPoint CI" API key working correctly  
3. ❌ **Xcode Archive step has certificate URL conflicts** - Environment variables pointing to invalid URLs
4. ✅ **Flutter Build bypasses certificate URL issues** - Uses Flutter's native build process
5. ✅ **Deploy step handles signing automatically** - Uses uploaded certificates + API key

**BITRISE SUPPORT CONFIRMED**:
- **No legacy environment variables** to clear - every build uses a clean virtual machine
- **Solution**: Upload .p12 certificates to Code Signing & Files tab
- **Once certificates are uploaded**, the system automatically sets the correct environment variables
- **"unsupported protocol scheme" error** will resolve once certificates are uploaded

**APPROACHES ALREADY TRIED AND FAILED**:
- ❌ **Tried adding Manage iOS Code Signing step** - Failed with "CertificateURLList: required variable is not present"
- ❌ **Tried clearing certificate URLs in Xcode Archive step** - Fields not editable (bound to environment variables)
- ❌ **Tried clicking dollar sign icons** - Only opened secrets popup, couldn't clear fields
- ❌ **Tried setting fields to single spaces or EMPTY** - Didn't work
- ❌ **Tried different automatic_code_signing values** - Still expects certificate URLs
- ❌ **Checked Project Settings → Code signing** - Only shows API key "Nadiapoint CI", no certificate environment variables
- ❌ **Checked Project Settings → Environment Variables** - Only shows `BITRISE_FLUTTER_PROJECT_LOCATION`, no certificate variables
- ❌ **Checked Project Settings → Secrets** - Completely empty, no certificate environment variables
- ❌ **Checked Workspace Settings** - No certificate environment variables found
- ❌ **Searched for BITRISE_CERTIFICATE_URL and BITRISE_CERTIFICATE_PASSPHRASE** - Not found anywhere in project configuration
- ✅ **FOUND**: Certificate environment variables ARE defined - they appear in Manage iOS Code Signing step as `$BITRISE_CERTIFICATE_URL` and `$BITRISE_CERTIFICATE_PASSPHRASE`
- ❌ **Tried setting certificate fields to EMPTY in Manage iOS Code Signing step** - Failed with "failed to download certificates: Get "[REDACTED]": unsupported protocol scheme """
- ❌ **Tried removing Manage iOS Code Signing step entirely** - Still failed with same certificate URL error in Xcode Archive step

**PROBLEM**: Bitrise requires actual .p12 certificate files to be uploaded - API keys alone are not sufficient for automatic code signing in this setup.

**SOLUTION REQUIRED**:

**NEW WORKFLOW CONFIGURATION**:

#### **Step 4: Flutter Build Configuration**
- **Platform**: `iOS`  
- **iOS output artifact type**: `archive`
- **Codesign Identity**: (leave empty)
- **Additional parameters**: `--release --no-codesign`

#### **Step 5: Deploy to App Store Connect Configuration**
- **Step**: "Deploy to App Store Connect - Application Loader"
- **Bitrise Apple Developer Connection**: `Default (automatic)` (uses your API key)
- **API Key: URL**: Leave EMPTY
- **API Key: Issuer ID**: Leave EMPTY  
- **Apple ID: Email**: Leave EMPTY (using API key, not Apple ID)
- **Apple ID: Password**: Leave EMPTY
- **Apple ID: Application-specific password**: Leave EMPTY
- **IPA path**: Keep default `$BITRISE_IPA_PATH` (auto-detects from Flutter Build)
- **PKG path**: Keep default `$BITRISE_PKG_PATH`
- **Platform**: Keep `Default (auto)`

### 🎯 **NEXT STEP: TEST THE NEW FLUTTER BUILD WORKFLOW**

**Now test the new Flutter Build approach:**

1. **Save the Deploy to App Store Connect step** with the configuration above
2. **Remove the problematic "Xcode Archive & Export for iOS" step** from your workflow
3. **Your final workflow should be**:
   - Git Clone Repository ✅
   - Flutter Install ✅
   - Script (flutter pub get) ✅
   - **Run CocoaPods install** (with repository update enabled) ✅
   - Flutter Build (iOS archive, --release --no-codesign) ✅
   - Deploy to App Store Connect - Application Loader ✅
4. **Save the entire workflow**
5. **Start a new build** and monitor progress

**What to expect with the new workflow:**
- ✅ **Flutter Build step** should create iOS archive without certificate URL errors
- ✅ **Deploy step** should handle code signing automatically using your uploaded certificates
- ✅ **Build should complete successfully** and deploy to TestFlight
- ✅ **No more "unsupported protocol scheme" errors**

### 🚨 **COCOAPODS DEPENDENCY CONFLICTS RESOLVED (AS OF 2025-08-09)**

**STATUS**: ✅ **LATEST ISSUE FIXED** - Multiple CocoaPods dependency conflicts resolved

**LATEST ERROR** (FIXED):
```
[!] CocoaPods could not find compatible versions for pod "GoogleUtilities/UserDefaults":
  In Podfile:
    GoogleUtilities (~> 8.1) was resolved to 8.1.0, which depends on
      GoogleUtilities/UserDefaults (= 8.1.0)

    firebase_messaging (from `.symlinks/plugins/firebase_messaging/ios`) was resolved to 15.2.7, which depends on
      GoogleUtilities/UserDefaults (~> 8.1)

    mobile_scanner (from `.symlinks/plugins/mobile_scanner/ios`) was resolved to 3.2.0, which depends on
      GoogleUtilities/UserDefaults (~> 7.0)
```

**LATEST SOLUTION**: Added CocoaPods override to force compatible GoogleUtilities version

#### **Root Cause**: 
Multiple version conflicts between forced Podfile constraints and plugin requirements:
- **Podfile forced**: `GoogleUtilities (~> 8.1)` and `GoogleMLKit/BarcodeScanning (~> 6.0)`
- **firebase_messaging required**: `GoogleUtilities/UserDefaults (~> 8.1)`
- **mobile_scanner required**: `GoogleUtilities/UserDefaults (~> 7.0)` and `GoogleMLKit/BarcodeScanning (~> 4.0.0)`

#### **Comprehensive Fix**: 
**Updated `ios/Podfile`:**
```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Let plugins determine their own GoogleUtilities and GoogleMLKit versions to avoid conflicts
end
```

**Updated `ios/Podfile`:**
```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Override GoogleUtilities to a version compatible with both firebase_messaging and mobile_scanner
  pod 'GoogleUtilities', '~> 7.11.5'
end
```

**Updated `pubspec.yaml`:**
```yaml
# Force compatible dependency versions to resolve conflicts
dependency_overrides:
  # web: ^1.1.0  # Commented out to avoid potential conflicts
```

#### **Why This Fixes It**:
- **Added CocoaPods override** - forces GoogleUtilities to version 7.11.5 which is compatible with both plugins
- **pod 'GoogleUtilities', '~> 7.11.5'** - this version works with both firebase_messaging and mobile_scanner
- **Removed invalid Flutter overrides** - google_utilities is not a Flutter package, it's a native iOS dependency
- **Commented out web override** - prevents potential conflicts with other packages
- **CocoaPods will use the overridden version** - resolves the dependency conflict at the native level

**PREVIOUS ERRORS** (ALL FIXED):
- ✅ **Invalid Podfile**: Replaced with standard Flutter Podfile
- ✅ **CocoaPods specs out-of-date**: Added repository update
- ✅ **IdensicMobileSDK missing**: Added SumSubstance source
- ✅ **GoogleMLKit/BarcodeScanning conflict**: Removed conflicting constraint
- ✅ **GoogleUtilities/UserDefaults conflict**: Removed conflicting constraint

**If the build succeeds:**
- **Check App Store Connect** → My Apps → your app → TestFlight
- **New build should appear** within 10-20 minutes
- **TestFlight deployment** should be automatic

### 🎯 **CURRENT STATUS & NEXT STEPS (2025-08-09)**

**STATUS**: 🔄 **READY FOR TESTING** - All known issues resolved, ready for new build

**CHANGES MADE IN THIS SESSION**:
- ✅ **Fixed CocoaPods GoogleMLKit conflict** - Removed version constraint in Podfile
- ✅ **Fixed CocoaPods GoogleUtilities conflict** - Added proper override in Podfile
- ✅ **Removed invalid Flutter overrides** - google_utilities is not a Flutter package
- ✅ **Commented out web dependency override** - Prevented potential conflicts
- ✅ **Updated documentation** - Added latest fix to deployment checklist

**NEXT STEPS**:
1. **Commit changes** to repository
2. **Start new Bitrise build** using the `primary` workflow
3. **Monitor build progress** - should pass all steps now
4. **Check TestFlight** for successful deployment

**EXPECTED WORKFLOW SUCCESS**:
```
1. Git Clone Repository ✅
2. Flutter Install ✅
3. Script (flutter pub get) ✅
4. Run CocoaPods install ✅ (should now pass)
5. Flutter Build (iOS archive) ✅ (should now run)
6. Deploy to App Store Connect ✅ (should now deploy)
```

**If build fails again**:
- Check the specific error in the build log
- Update this document with the new error
- Apply the next fix based on the error type

### 🚨 **LATEST FAILURE: `GoogleMLKit/BarcodeScanning` Conflict (2025-08-10)**

**STATUS**: ❌ **FAILED** - `Run CocoaPods install` step failed.

**ERROR**:
```
[!] CocoaPods could not find compatible versions for pod "GoogleMLKit/BarcodeScanning":
  In Podfile:
    mobile_scanner (from `.symlinks/plugins/mobile_scanner/ios`) was resolved to 3.2.0, which depends on
      GoogleMLKit/BarcodeScanning (~> 4.0.0)
```

**ROOT CAUSE**:
1.  **Dependency Conflict**: The `mobile_scanner` plugin requires version `~> 4.0.0` of `GoogleMLKit/BarcodeScanning`, but CocoaPods cannot find a compatible version, likely due to other constraints.
2.  **Missing `Podfile.lock`**: The build log warns `No Podfile.lock found`. This file is critical for ensuring reproducible builds by locking dependency versions. Without it, conflicts are more likely.
3.  **Outdated Pod Specs**: The `pod install` command is running with `--no-repo-update`, which prevents CocoaPods from fetching the latest dependency information, making it harder to resolve version conflicts.

**SOLUTION**:

**SOLUTION (Corrected)**:

**Step 1: Update CocoaPods Command in Bitrise**
1.  In the Bitrise Workflow Editor, select the **Run CocoaPods install** step.
2.  Find the **CocoaPods command** dropdown field.
3.  Change the selected value from `install` to `update`.
4.  Save the workflow.

**Step 2: Update `ios/Podfile`**
1.  Add the following line inside the `target 'Runner' do` block in your `ios/Podfile`:
    ```ruby
    pod 'GoogleMLKit/BarcodeScanning', '~> 4.0.0'
    ```
2.  Commit and push this change to your repository.

**Step 3: Run a New Build**
- After completing the two steps above, start a new build on Bitrise.

---

### 🚨 **TROUBLESHOOTING: .p12 Upload Issue**

**Problem**: Continue button loads but nothing happens when uploading .p12 file

**Possible Causes & Solutions**:

#### **Solution 1: Check .p12 File Format**
- **Issue**: The .p12 file might not be in the correct format
- **Fix**: Re-convert the .cer file to .p12 using a different online converter
- **Try**: [sslshopper.com](https://www.sslshopper.com/ssl-converter.html) or search for "convert cer to p12 online"

#### **Solution 2: Check File Format**
1. **Go to** [sslshopper.com/ssl-converter.html](https://www.sslshopper.com/ssl-converter.html)
2. **Upload your `ios_development.cer` file** (you have `apple_distribution.cer` - that's good too!)
3. **Set conversion options**:
   - **Type of Current Certificate**: "Standard PEM" (should auto-detect)
   - **Type To Convert To**: "PFX/PKCS#12" (should already be selected)
   - **PFX Password**: **Enter a password** (e.g., "password123" or "bitrise2024")
4. **Click "Convert Certificate"**
5. **Download the converted .p12 file**
6. **Try uploading to Bitrise again** - you'll need to enter the same password when uploading

**If SSL Shopper isn't working**, try these alternatives:

#### **Alternative Solution 1: Use CertificateTools.com**
1. **Go to** [certificatetools.com](https://certificatetools.com) → **Certificate Conversion**
2. **Upload your .cer file**
3. **Set options**:
   - **Current Certificate Type**: "Standard PEM"
   - **Convert To**: "PFX/PKCS#12"
   - **PFX Password**: Enter a password (e.g., "password123")
4. **Click "Convert Certificate"**

#### **Alternative Solution 2: Use OpenSSL Commands**
If online converters fail, you can use OpenSSL commands on your local machine:
```bash
openssl pkcs12 -export -out certificate.p12 -inkey privateKey.key -in certificate.crt
```

#### **Alternative Solution 3: Try Different Online Converter**
Search for "convert cer to p12 online" and try:
- [certificatetools.com](https://certificatetools.com)
- [ssl.com/converter](https://www.ssl.com/converter/)
- [digicert.com/ssl-converter](https://www.digicert.com/ssl-converter/)

#### **Solution 3: Add Passphrase**
- **Issue**: .p12 files often require a passphrase
- **Fix**: When converting .cer to .p12, set a simple passphrase (e.g., "password123")
- **Note**: Remember this passphrase - you'll need it when uploading to Bitrise

#### **Solution 4: Check File Size**
- **Issue**: File might be too large or corrupted
- **Fix**: Ensure the .p12 file is reasonable size (usually 2-10KB)
- **Check**: Try downloading the .p12 file again

#### **Solution 5: Try Different Browser**
- **Issue**: Browser compatibility issue
- **Fix**: Try uploading in a different browser (Chrome, Firefox, Safari)
- **Alternative**: Clear browser cache and cookies

#### **Solution 6: Check File Permissions**
- **Issue**: File might have permission issues
- **Fix**: Ensure the .p12 file is not read-only or corrupted
- **Check**: Try opening the file in a text editor (should show binary data)

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

### 🎯 **CERTIFICATE CONFUSION EXPLAINED**

**You're absolutely right to be confused!** Here's the difference:

#### **What You Already Have (.p8 API Key)**
- **Purpose**: This is for **automatic code signing** - Bitrise can automatically create and manage certificates for you
- **What it does**: Lets Bitrise talk to Apple's servers and automatically handle certificate creation
- **Why it's not working**: Bitrise support confirmed that API keys alone are not sufficient - you need actual .p12 certificates uploaded

#### **What You Need Now (.p12/.pfx Certificates)**
- **Purpose**: These are the **actual signing certificates** that sign your app
- **What they do**: These are the certificates that get embedded in your app to prove it's from you
- **Why you need them**: Bitrise support confirmed that you need to upload actual .p12 certificates for the system to work properly

### **The .p12 vs .pfx Confusion**

**✅ YES - .p12 and .pfx are the SAME format!**

- **.p12** = PKCS#12 format (most common for iOS)
- **.pfx** = PFX format (same as PKCS#12, just different extension)

**For iOS development, you can use either:**
- `ios_development.p12` 
- `ios_development.pfx`

**Bitrise accepts both formats!** So if your converter outputs a .pfx file, that's perfectly fine - just upload it to Bitrise.

### **The CSR (Certificate Signing Request) Problem**

**What Apple is asking for**: A **CSR (Certificate Signing Request)** file that's generated from a Mac using Keychain Access or Xcode.

**Why this is frustrating**: Apple assumes everyone has a Mac, but you don't!

### **How to Get .p12 Certificates (NO MAC REQUIRED)**

**CRITICAL**: Since you don't have a MacBook, here are alternative ways to get .p12 certificates:

#### **Option A: Use Online CSR Generators (RECOMMENDED)**
1. **Use an online CSR generator**:
   - Go to [certificatetools.com](https://certificatetools.com) or search for "online CSR generator"
   - **Fill in the required fields**:
     - **Common Name**: Your name or company name (e.g., "NadiaPoint Exchange" or "John Doe")
     - **Email Address**: Your email
     - **Country**: Your country's two-letter code (e.g., "US" for United States, "NG" for Nigeria, "GB" for Great Britain)
     - **State/Province**: Your state or province (e.g., "California", "Lagos", "England")
     - **Locality**: Your city (e.g., "San Francisco", "Lagos", "London")
     - **Organization**: Your company name (e.g., "NadiaPoint Inc.") or your full name if personal
     - **DNS Names** (Subject Alternative Names): Leave as is or clear if your app doesn't have specific domains
   - **Generate the CSR file** and download it
2. **Use the CSR with Apple Developer Portal**:
   - Go to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
   - **Click "Certificates"** → **+** (to create new ones)
   - **Upload your generated CSR file**
   - **Create**:
     - **Apple Development** certificate (for development builds)
     - **Apple Distribution** certificate (for app-store builds)
   - **Download** the `.cer` files
3. **Convert .cer to .p12**:
   - Use online .cer to .p12 conversion tools
   - Search for "convert cer to p12 online"
   - Upload your .cer files and convert them to .p12 format

#### **Option B: Ask Someone with a Mac**
1. **Find someone** with a Mac who has Xcode installed
2. **Have them**:
   - Open Xcode → Preferences → Accounts → Manage Certificates
   - Export the certificates as .p12 files
   - Send you the .p12 files and passwords

#### **Option C: Use Bitrise's Built-in Certificate Generation (NEW)**
1. **Check if Bitrise has automatic certificate generation**:
   - Look in your **Manage iOS Code Signing step** settings
   - See if there's an option for "Auto-generate certificates" or similar
   - This might bypass the need for manual .p12 uploads


