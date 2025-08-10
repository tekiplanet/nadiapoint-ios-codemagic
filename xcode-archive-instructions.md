### Definitive iOS Build Signing Configuration

> **CRITICAL WARNING:** A valid code signing certificate (`.p12` file) **MUST** contain both the public certificate AND its corresponding private key. The only way to create a valid `.p12` file is to export it from the **Keychain Access** application on the specific Mac computer that originally created the certificate request. 
> 
> A `.cer` file downloaded from the Apple Developer portal is **NOT** sufficient. Converting a `.cer` file will result in a `.p12` file that is missing the private key, and it will cause the build to fail. You must obtain the correct `.p12` file from a team member with access to the necessary Mac.

This document outlines the complete and final three-part configuration required to resolve iOS build signing errors on Bitrise. Follow all three parts carefully.

---

### Part 1: Xcode Project File (`project.pbxproj`)

The Xcode project must be the single source of truth for all signing settings. Both `Release` build configurations must be updated with the following manual signing information.

-   **File**: `ios/Runner.xcodeproj/project.pbxproj`
-   **Required settings for BOTH `Release` configurations**:
    -   `CODE_SIGN_STYLE = Manual;`
    -   `"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";`
    -   `PROVISIONING_PROFILE_SPECIFIER = "14385a45-f676-46d8-af8e-ba68b50ed804";`
    -   `DEVELOPMENT_TEAM = J3RMZWZ73D;`

This configuration explicitly tells Xcode which certificate, provisioning profile, and development team to use, removing all ambiguity.

---

### Part 2: Bitrise Code Signing Tab

Bitrise must have the correct signing files uploaded and configured.

1.  Navigate to your app on Bitrise, go to the **Workflow** tab, and then the **Code Signing** tab.
2.  Ensure your **Apple Distribution Certificate (`.p12` file)** is uploaded.
3.  Ensure your **App Store Provisioning Profile (`.mobileprovision` file)** is uploaded.
4.  For the provisioning profile, ensure the **"Exposed" toggle is turned ON**. This prevents issues with pull request builds.

---

### Part 3: Bitrise Workflow Editor

The workflow must be configured to correctly install the signing files and not override the project settings.

1.  **Add and Configure the Installer Step**: Add the **`Certificate and profile installer`** step to your workflow, placing it immediately after `Git Clone Repository`. Then, click on the step and configure it:
    -   Find the **`Installs default Codesign Files`** input and set it to **`no`**. This is critical to prevent the step from trying to install blank default files.

2.  **Configure the Xcode Archive Step**: Click on the **`Xcode Archive & Export for iOS`** step and ensure the following fields are **EMPTY** to prevent them from overriding the project settings:
    -   `Developer Portal team`
    -   `Additional options for the xcodebuild command`

3.  **(Recommended) Add Cache Clearing Script**: Add a **`Script`** step immediately after the `Certificate and profile installer` step. Add the following commands to the script content to prevent issues with stale cache:

    ```bash
    echo "Clearing Xcode caches..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/
    rm -rf $BITRISE_CACHE_DIR
    echo "Caches cleared."
    ```

4.  **Save** the workflow.

After completing all three parts, run a new build. This comprehensive setup should resolve all signing errors.
