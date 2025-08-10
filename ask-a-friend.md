# Guide for Miracle and Wisdom: Generating a .p12 File

This is a step-by-step script for a screen-sharing call. **Miracle**, you will guide **Wisdom** through these steps. **Wisdom**, you will perform the actions on your Mac.

**Goal**: To securely create a `.p12` file from Wisdom's Mac for Miracle's app.

--- 

### **Part 1: Wisdom Creates a Certificate Request**

**Miracle**: "Wisdom, please start sharing your screen so I can guide you."

**Wisdom**: 
1.  Click the magnifying glass icon in the top-right corner of your screen.
2.  Type `Keychain Access` and press `Enter`.

**Miracle**: "Great. Now, in the menu bar at the very top of the screen, click `Keychain Access`, then go to `Certificate Assistant`, and click `Request a Certificate From a Certificate Authority...`"

**Wisdom**: A new window should appear. 

**Miracle**:
1.  "In the `User Email Address` field, I'll give you my Apple Developer email. Please type it in."
2.  "In the `Common Name` field, please type `Goddey Ojabuoma`."
3.  "Leave the `CA Email` field blank."
4.  "Now, click the little circle that says `Saved to disk`."
5.  "Click `Continue`."

**Wisdom**:
1.  A save window will pop up. Save the file to your Desktop. It should be named `CertificateSigningRequest.certSigningRequest`.
2.  Click `Save`.

**Miracle**: "Perfect. Now, please find that file on your Desktop and send it to me through our chat or email."

**Wisdom**: Send the file to Miracle.

--- 

### **Part 2: Miracle Creates the Official Certificate**

**Miracle**: "Thanks, Wisdom. I have the file. Now I need to do a few things on my end. It will just take a minute."

**Miracle (Your Steps)**:
1.  Go to the Apple Developer website (`developer.apple.com`) and log in.
2.  Go to `Certificates, IDs & Profiles`.
3.  Click the `+` button to add a new certificate.
4.  Select `Apple Distribution` and click `Continue`.
5.  When it asks you to upload a signing request, click `Choose File` and upload the `CertificateSigningRequest.certSigningRequest` file that Wisdom just sent you.
6.  Click `Continue` and then `Download` to get the official certificate. It will be named `distribution.cer`.

**Miracle**: "Okay, Wisdom. I've created the certificate. I'm sending it to you now. It's called `distribution.cer`."

--- 

### **Part 3: Wisdom Creates the Final .p12 File**

**Wisdom**:
1.  Save the `distribution.cer` file from Miracle onto your Desktop.
2.  Find the file and double-click it. Keychain Access will open and install it. It might seem like nothing happened, but it's done.

**Miracle**: "Okay, now let's check if it installed correctly. Go back to the Keychain Access app."

**Wisdom**:
1.  In the `My Certificates` category, look for `Apple Distribution: Goddey Ojabuoma (J3RMZWZ73D)`.

**Miracle**: "This next part is the most important check. Do you see a little arrow to the left of that certificate name? Please click it."

**Wisdom**: Click the arrow. A "private key" should appear nested underneath the certificate.

**Miracle**: "Perfect! Seeing that private key means everything is working. Now we'll export the final file."

**Wisdom**:
1.  Click on the `Apple Distribution...` certificate line to highlight it.
2.  Hold down the `Command` (⌘) key and click on the private key underneath it. (Both lines should now be selected).
3.  Right-click on either of the selected lines and choose `Export 2 items...`.

**Miracle**: "A save window will appear. Please name the file `Nadiapoint_Distribution.p12` and make sure the `File Format` at the bottom says `.p12`. Save it to your Desktop."

**Wisdom**: Save the file.

**Miracle**: "It's going to ask for a password. I'll give you one to type in. You'll have to enter it twice. This is the password for the file itself."

**Wisdom**: Enter the password Miracle provides. It may then ask for your Mac's login password to approve the export. Enter your own Mac password if it asks.

**Miracle**: "That's it! Please send me that final `Nadiapoint_Distribution.p12` file from your Desktop."

**Wisdom**: Send the final `.p12` file to Miracle.

**Miracle**: "Thank you so much, Wisdom! That's everything I need. You can delete all the files from your Desktop now."