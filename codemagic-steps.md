# Codemagic iOS Deployment Checklist

Use this checklist to configure your Flutter application for deployment to the App Store via Codemagic. This guide uses the **App Store Connect API key method**, which is the most reliable approach and does not require a macOS machine.

---

### ✅ **Phase 1: Initial Codemagic Setup**

This phase covers connecting your app to Codemagic.

-   [x] **Sign up for Codemagic**: If you haven't already, create an account at [codemagic.io](https://codemagic.io) and sign in with your Git provider (GitHub, GitLab, Bitbucket).
-   [x] **Add Your Application**:
    -   On the Applications page, find your repository and click **Set up build**.
    -   When asked, select **Flutter App** as the project type.
-   [ ] **Confirm Basics**:
    -   Ensure your Apple Developer account is active.
    -   Confirm your app's Bundle ID is correct (e.g., `com.nadiapoint.exchange`).
    -   Make sure the `ios/Runner/GoogleService-Info.plist` file exists in your repository.

---

### ✅ **Phase 2: Create App Store Connect API Key**

This is the most critical step for code signing. If you already have a `.p8` key from the Bitrise setup, you can reuse it.

-   [ ] **Navigate to App Store Connect**: Open [App Store Connect → Users and Access → Keys](https://appstoreconnect.apple.com/access/api).
-   [ ] **Generate API Key**:
    -   Click the **+** button to generate a new key.
    -   **Name**: `Codemagic CI` (or similar).
    -   **Role**: `App Manager`.
    -   Click **Generate**.
-   [ ] **Download and Save Credentials**:
    -   **Download .p8 Key**: Click **Download API Key** next to the newly created key. Save the `.p8` file securely. **You can only download this once.**
    -   **Copy Issuer ID**: Find this at the top of the page.
    -   **Copy Key ID**: Find this in the table row for your new key.

---

### ✅ **Phase 3: Configure Codemagic Distribution**

Here, you'll connect Codemagic to your Apple Developer account using the key you just created.

-   [ ] **Open App Settings**: In Codemagic, open your application and click the **Settings** gear icon on the right side of the screen.
-   [ ] **Navigate to Distribution**: Go to the **Distribution → iOS** tab.
-   [ ] **Connect with App Store Connect**:
    -   Select **App Store Connect** as the signing method.
    -   **App Store Connect API key name**: Give the key a recognizable name (e.g., `NadiaPoint CI Key`).
    -   **Issuer ID**: Paste the Issuer ID you copied.
    -   **Key ID**: Paste the Key ID you copied.
    -   **Private key**: Upload the `.p8` file you downloaded.
-   [ ] **Save Connection**: Click **Save connection**. Codemagic will verify the key.

## Final Sanity Checks

-   [ ] **Create App Record in App Store Connect**: Before publishing, you must create an app record in App Store Connect. See the detailed guide here: [createapp-app-store.md](./createapp-app-store.md)

---

### ✅ **Phase 4: Configure Project Settings**

-   [ ] **Change App Name (Optional)**: To change the output file name (e.g., from `safejet_exchange.ipa` to `nadiapoint.ipa`), open your `pubspec.yaml` file and change the `name:` property to `nadiapoint`. Commit and push this change.

### ✅ **Phase 5: Configure the Build Workflow**

-   [ ] **Select Build Platform**: In the **Build for platforms** section, ensure only **iOS** is checked. Uncheck Android, Web, etc., to focus the build.

Use the Workflow Editor to define the build steps.

-   [ ] **Open Workflow Editor**: Go to your app's **Settings → Workflow** tab.
-   [x] **Build Triggers**: Left disabled for now to allow for manual builds during setup.
-   [x] **Environment Variables**: Add the following project-specific variables. Make sure to check the **Secret** box for the `JWT_KEY`.
    -   `API_URL` = `https://decrypted.nadiapoint.com`
    -   `JWT_KEY` = `482577dbc71da156764d3ba2a755db2ca3eb5ec735568ceef5118e4bf3ee4c93b209bfb4ffff2823c92ef3870bf5be7cfafbdf65b1aa66ee5b63f3fcaed861da`
    -   `APP_NAME` = `NadiaPoint`
-   [x] **Dependency Caching**: Leave this disabled for now to ensure a clean build environment during setup.
-   [x] **Pre-build Script**: Add the following script to create the `.env` file from your secure environment variables. This makes them accessible to your app during the build.
    ```bash
    #!/bin/sh
    set -e
    set -x

    # Create the .env file from Codemagic environment variables
    echo "API_URL=${API_URL}" > .env
    echo "JWT_KEY=${JWT_KEY}" >> .env
    echo "APP_NAME=${APP_NAME}" >> .env

    echo "Successfully created .env file:"
    cat .env
    ```

-   [x] **Build**: Configure the build settings as follows:
    -   **Flutter version**: Ensure this is set to `channel Stable` or the specific version your project requires.
    -   **Mode**: Select `Release`.
    -   **Build arguments**: Clear the text field for **iOS**.
-   [x] **Distribution**: This is the final step for configuration.
    -   [x] **iOS code signing**: Select **Automatic** and set **Provisioning profile type** to `App Store`.
    -   [x] **App Store Connect publishing**: 
        -   Check **Enable App Store Connect publishing**.
        -   Select your API Key from the dropdown.
        -   Check **Submit to TestFlight beta review**.

-   [x] **Tests**: Leave all testing options disabled for the initial setup to simplify the first build. We can enable them later.

---

### ✅ **Phase 5: Start the Build and Deploy**

-   [ ] **Save Workflow**: Click **Save changes** at the top right.
-   [ ] **Start a New Build**:
    -   Go to your application's main page.
    -   Click **Start new build**.
    -   Select the branch you want to build from (e.g., `main`).
    -   Click **Start build**.
-   [ ] **Monitor Progress**: Watch the build logs for any errors. The steps should be:
    -   Cloning repository.
    -   Flutter install, pub get.
    -   CocoaPods install.
    -   Building IPA and code signing.
    -   Publishing to App Store Connect.
-   [ ] **Check TestFlight**: After the build succeeds, it can take 10-30 minutes for the build to appear in App Store Connect under your app's **TestFlight** section.