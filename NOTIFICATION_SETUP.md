# Push Notification Setup Guide

This guide covers everything required to enable APNs push notifications for the ColourNote app — from the Apple Developer Portal through to the Irids Node server.

---

## Prerequisites

- Access to the Apple Developer account for the ColourNote app bundle ID (`com.paulwilliams.colornote`)
- SSH or direct access to the Irids production server
- Xcode with the ColourNote project open
- Node.js server running (Irids_Web)

---

## Part 1: Apple Developer Portal

### 1.1 — Enable Push Notifications for the App ID

1. Sign in to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. Select **Identifiers** from the left sidebar
3. Find and click the identifier for `com.paulwilliams.colornote`
4. Scroll down to **Capabilities** and tick **Push Notifications**
5. Click **Save**

### 1.2 — Create an APNs Auth Key

Using an Auth Key (`.p8`) is preferred over a certificate — it never expires and works for both sandbox and production.

1. In the Developer Portal left sidebar, select **Keys**
2. Click the **+** button to create a new key
3. Give it a name, e.g. `ColourNote APNs Key`
4. Tick **Apple Push Notifications service (APNs)**
5. Click **Continue**, then **Register**
6. Click **Download** — you will only be able to download this file once. Save it securely.
7. Note down:
   - **Key ID** — shown on the key detail page (10-character alphanumeric string, e.g. `ABC1234567`)
   - **Team ID** — shown in the top-right of the Developer Portal under your account name (e.g. `XYZ9876543`)

The downloaded file will be named `AuthKey_<KEY_ID>.p8`.

---

## Part 2: Xcode — Add the Push Notifications Capability

1. Open the ColourNote project in Xcode
2. Select the **ColourNote** target in the project navigator
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability** and add **Push Notifications**
5. Xcode will update the entitlements file. Verify that `ColourNote/eFrt.entitlements` contains:

```xml
<key>aps-environment</key>
<string>development</string>
```

6. For App Store / TestFlight builds, change the value to `production`:

```xml
<key>aps-environment</key>
<string>production</string>
```

> **Note:** The `aps-environment` value must match the APNs gateway the server connects to. Sandbox tokens only work with the sandbox gateway; production tokens only work with the production gateway. The server reads this from `APNS_PRODUCTION` (see below).

---

## Part 3: Local Development Setup

### 3.1 — Place the Auth Key

In the `Irids_Web/` directory, create an `apns/` folder and copy your `.p8` file into it:

```bash
mkdir -p Irids_Web/apns
cp ~/Downloads/AuthKey_ABC1234567.p8 Irids_Web/apns/
```

The `apns/` directory is already listed in `.gitignore` — do not commit the key file.

### 3.2 — Install the APNs Library

In the `Irids_Web/` directory, install the required package:

```bash
cd Irids_Web
npm install @parse/node-apn
```

### 3.3 — Set Environment Variables

Add the following to `Irids_Web/.env`:

```env
# APNs Push Notifications
APNS_KEY_PATH=./apns/AuthKey_ABC1234567.p8
APNS_KEY_ID=ABC1234567
APNS_TEAM_ID=XYZ9876543
APNS_BUNDLE_ID=com.paulwilliams.colornote
APNS_PRODUCTION=false
```

Replace `ABC1234567` with your actual Key ID and `XYZ9876543` with your Team ID.

- `APNS_PRODUCTION=false` — connects to the APNs **sandbox** gateway (required for development builds installed directly from Xcode)
- The server will start normally even if these variables are absent — push notifications are silently disabled in that case

### 3.4 — Run Database Migration

Restart the Node server. On startup it will run migration 15, which creates the `device_tokens` table:

```
Migrating to version 15 (device_tokens table)...
Successfully migrated to version 15
```

> You should not restart the server yourself — ask Paul to do this.

### 3.5 — Test on a Physical Device

Push notifications do not work on the iOS Simulator. You must run the app on a physical iPhone or iPad connected to Xcode.

1. Build and run the ColourNote app on your device
2. Log in or use the Cloud Sync / Cloud Restore flow
3. The app will request notification permission on first launch after login
4. Grant permission — the device token is automatically registered with the server
5. Check the server logs for:

```
[DEVICE] Token registered for user X
```

---

## Part 4: Production Server (Irids) Setup

### 4.1 — Copy the Auth Key to the Server

Copy the `.p8` key file to the server securely:

```bash
scp AuthKey_ABC1234567.p8 user@irids.co.uk:/path/to/Irids_Web/apns/
```

Or create the directory and file manually via SSH:

```bash
ssh user@irids.co.uk
mkdir -p /path/to/Irids_Web/apns
# then copy the file contents in
```

Ensure the file is readable by the Node process but not world-readable:

```bash
chmod 600 /path/to/Irids_Web/apns/AuthKey_ABC1234567.p8
```

### 4.2 — Set Environment Variables on the Server

Add the following to the server's environment configuration. The method depends on how the server is managed:

**If using a `.env` file:**

```env
APNS_KEY_PATH=./apns/AuthKey_ABC1234567.p8
APNS_KEY_ID=ABC1234567
APNS_TEAM_ID=XYZ9876543
APNS_BUNDLE_ID=com.paulwilliams.colornote
APNS_PRODUCTION=true
```

**If using PM2** (`ecosystem.config.js`):

```javascript
env: {
  APNS_KEY_PATH: './apns/AuthKey_ABC1234567.p8',
  APNS_KEY_ID: 'ABC1234567',
  APNS_TEAM_ID: 'XYZ9876543',
  APNS_BUNDLE_ID: 'com.paulwilliams.colornote',
  APNS_PRODUCTION: 'true',
}
```

**If using systemd** (add to the `[Service]` block of the unit file):

```ini
Environment=APNS_KEY_PATH=./apns/AuthKey_ABC1234567.p8
Environment=APNS_KEY_ID=ABC1234567
Environment=APNS_TEAM_ID=XYZ9876543
Environment=APNS_BUNDLE_ID=com.paulwilliams.colornote
Environment=APNS_PRODUCTION=true
```

> **Important:** `APNS_PRODUCTION=true` on the production server connects to the APNs **production** gateway, which is required for App Store and TestFlight builds. Sandbox tokens will not work against the production gateway.

### 4.3 — Install the APNs Package on the Server

```bash
cd /path/to/Irids_Web
npm install @parse/node-apn
```

### 4.4 — Restart the Server and Verify

After restarting, check the logs for the migration and that the server started cleanly:

```
Migrating to version 15 (device_tokens table)...
Successfully migrated to version 15
```

Verify pushes are working by having a user share a note with another logged-in user on a physical device. The server logs should show:

```
[APNS] Sent: 1, failed: 0
```

---

## Summary of Environment Variables

| Variable | Description | Local (dev) | Production |
|---|---|---|---|
| `APNS_KEY_PATH` | Path to the `.p8` auth key file | `./apns/AuthKey_XXX.p8` | `./apns/AuthKey_XXX.p8` |
| `APNS_KEY_ID` | 10-character Key ID from Developer Portal | Your Key ID | Your Key ID |
| `APNS_TEAM_ID` | 10-character Team ID from Developer Portal | Your Team ID | Your Team ID |
| `APNS_BUNDLE_ID` | App bundle identifier | `com.paulwilliams.colornote` | `com.paulwilliams.colornote` |
| `APNS_PRODUCTION` | APNs gateway (`true` = production, `false` = sandbox) | `false` | `true` |

---

## Troubleshooting

**No push received, server logs show `[APNS] Missing config — push disabled`**
The env vars are not being picked up. Check spelling, restart the server, and verify with `console.log(process.env.APNS_KEY_ID)` in a test script.

**Server logs show `[APNS] Failed: <token> — ...BadDeviceToken`**
The device token is for the wrong environment (sandbox token sent to production gateway or vice versa). Check that `APNS_PRODUCTION` matches the `aps-environment` entitlement in the app build.

**Server logs show `[APNS] Failed: <token> — ...Unregistered`**
The app has been deleted from the device or the token has been rotated. The stale token in `device_tokens` will be replaced automatically next time the app registers.

**No permission prompt appears on the device**
The user may have previously denied permission. Go to iOS Settings → Notifications → ColourNote and re-enable notifications.

**`[DEVICE] Token registered` never appears in server logs**
The app is running on a Simulator (push not supported), or the `POST /auth/device-token` call is failing. Check the Xcode console for `AppDelegate: Device token upload failed:`.
