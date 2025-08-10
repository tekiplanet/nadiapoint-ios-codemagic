### Xcode Archive & Export for iOS: Configuration Fix

**Update:** We have a new error! This is progress. The previous "missing development team" error is gone.

The new error is: `No profiles for 'com.nadiapoint.exchange' were found`.

This usually happens when Xcode is looking for the wrong type of provisioning profile (e.g., a Development profile instead of a Distribution profile). We can fix this by explicitly setting the **Build Configuration** to `Release`.

---

#### Step 1: Set Build Configuration

1.  Navigate to the **Xcode Archive & Export for iOS** step in your Bitrise workflow.
2.  In the **xcodebuild configuration** section, find the input field for **Build Configuration**.
3.  Enter `Release` into this field.

#### Step 2: Set Development Team (If you haven't already)

To fix the original error **'Signing for "Runner" requires a development team'**, you need to add your Team ID to the build command options.

1.  In the same **xcodebuild configuration** section, locate the field named **Additional options for the xcodebuild command**.
2.  Enter the following value, replacing `J3RMZWZ73D` with your actual Apple Developer Team ID:

    ```
    DEVELOPMENT_TEAM=J3RMZWZ73D
    ```

This setting ensures your development team is used during the code signing phase of the archive process.
