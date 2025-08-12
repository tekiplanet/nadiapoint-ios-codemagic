# Definitive Bitrise iOS Code Signing Guide (Script Method)

This guide provides the single, correct method for configuring iOS code signing on Bitrise using a custom script. This approach bypasses the unreliable default Bitrise steps and provides full control.

---

### Part 1: Prerequisites

1.  **Valid Signing Files**: In the Bitrise **Code Signing** tab, ensure you have:
    *   A valid `.p12` certificate (containing the private key) uploaded.
    *   The correct `.mobileprovision` profile uploaded.
    *   The password for the `.p12` file entered correctly.
    *   The **Exposed** toggle turned **ON** for both files is recommended.

2.  **Manual Signing in Xcode Project**: Your `ios/Runner.xcodeproj/project.pbxproj` file must be configured for manual signing with the correct identifiers.

---

### Part 2: Bitrise Workflow Configuration

> **CRITICAL: The script will fail if the 'Exposed' toggles are not enabled.** Before running the build, go to the **Code Signing** tab and ensure the toggle is **ON (green)** for **BOTH** the certificate and the provisioning profile. This allows the script to access the file URLs.

This is the entire workflow setup. Do not use the `File Downloader` or `Certificate and profile installer` steps.

1.  **Delete Old Steps**: In the Workflow Editor, **delete** the `Certificate and profile installer` step and any `File Downloader` steps you may have added.

2.  **Add a `Script` Step**: Immediately after the `Git Clone Repository` step, add a new **`Script`** step.

3.  **Paste the Script**: Click on the new `Script` step and paste the following code into the **Script content** box. This script manually handles the entire code signing setup.

    ```bash
    #!/bin/bash

    echo "--- Downloading Signing Files ---"
    curl -fLso certificate.p12 "$BITRISE_CERTIFICATE_URL"
    curl -fLso profile.mobileprovision "$BITRISE_PROVISION_URL"
    
    echo "--- Installing Provisioning Profile ---"
    mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
    cp profile.mobileprovision "$HOME/Library/MobileDevice/Provisioning Profiles/"
    
    echo "--- Installing Certificate & Key ---"
    security import certificate.p12 -k "$HOME/Library/Keychains/login.keychain-db" -P "$BITRISE_CERTIFICATE_PASSPHRASE" -A
    
    echo "--- Code Signing Setup Complete ---"
    ```

    **Note:** When copying the script, be aware that formatting issues may occur. Ensure that the script is pasted correctly to avoid errors.

4.  **Save and Run**: Save the workflow. This is the final and correct configuration. Run your build.

    **If the Script Still Fails (One-Liner Fallback):**

    If you still see formatting errors (`command not found`, `illegal option`), try replacing the script with this single, continuous line. This is much more robust against copy-paste issues:

    ```bash
    curl -Lso certificate.p12 "$BITRISE_CERTIFICATE_URL" && curl -Lso profile.mobileprovision "$BITRISE_PROVISION_URL" && mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles" && cp profile.mobileprovision "$HOME/Library/MobileDevice/Provisioning Profiles/" && security import certificate.p12 -k "$HOME/Library/Keychains/login.keychain-db" -P "$BITRISE_CERTIFICATE_PASSPHRASE" -A
    ```


