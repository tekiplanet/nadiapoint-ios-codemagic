# How to Create an App Record in App Store Connect

This is a prerequisite for publishing your iOS app to TestFlight or the App Store. Before starting a build in Codemagic, you must have an app record in App Store Connect that matches your bundle ID.

1.  **Log In**: Go to `appstoreconnect.apple.com` and log in with your Apple Developer account.

2.  **Navigate to "My Apps"**: From the main dashboard, click on the **"My Apps"** icon.

3.  **Start New App Creation**: Click the **`+`** icon (usually near the top-left) and select **"New App"** from the menu.

4.  **Fill Out the App Information Form**:
    -   **Platforms**: Check the box for **iOS**.
    -   **Name**: Enter the name for your app as it will appear on the App Store (e.g., `NadiaPoint Exchange`).
    -   **Primary Language**: Select the default language for your app.
    -   **Bundle ID**: Click the dropdown menu and select the correct bundle ID that you have already registered. It should be `com.nadiapoint.exchange`.
    -   **SKU**: Enter a unique stock-keeping unit. This is a private identifier for your app. A good practice is to use your bundle ID, so enter `com.nadiapoint.exchange`.
    -   **User Access**: You can typically leave this set to **"Full Access"**.

5.  **Create the App**: Click the **"Create"** button. The button will only become active after all required fields (like SKU) are filled.

Once this is done, your app record is ready. You can now return to Codemagic and start your build.
