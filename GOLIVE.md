# Go-Live Checklist

Pre-release checklist for TestFlight submissions and App Store production releases.
Covers both the iOS app (`ColourNote/`) and the Node.js backend (`Irids_Web/`).

---

## iOS App

### Version Numbers
- [ ] **Info.plist `CFBundleShortVersionString`** — set to the correct marketing version (e.g. `1.3.0`)
  - Currently shows `1.2.3` which is out of sync with CLAUDE.md
- [ ] **Info.plist `CFBundleVersion`** (build number) — increment by 1 for every TestFlight or App Store upload
  - Currently shows `11`; CLAUDE.md says current is build `12`
- [ ] Version and build number match what is set in Xcode → Target → General → Identity

### App Transport Security
- [ ] **`NSAllowsArbitraryLoads` in Info.plist is `true`** — this permits plain HTTP connections
  - Acceptable during development (to reach `localhost:3002`)
  - For production: set to `false` and ensure all traffic goes to `https://irids.co.uk`
  - If you need an exception only for localhost during dev, use `NSExceptionDomains` instead of a global allow

### API Base URL
- [ ] `API_BASE_URL` launch environment variable in `ColourNote.xcscheme` is **disabled** (`isEnabled = "NO"`) — confirm this before archiving
  - When disabled, `APIConfig.baseURL` falls back to `productionURL` (`https://irids.co.uk`) ✓
  - If it is accidentally enabled at archive time, the app will point at `localhost` in production

### Build Configuration
- [ ] Archive uses the **Release** build configuration, not Debug
  - In Xcode: Product → Archive always builds Release; double-check scheme is not set to Debug for Archive action

### Push Notifications
- [ ] **`aps-environment` entitlement** is set correctly:
  - `development` — for Xcode direct-install (Debug) builds
  - `production` — for TestFlight and App Store builds
  - Check: Xcode → Target → Signing & Capabilities → Push Notifications
- [ ] **APNS Auth Key** (`.p8`) is uploaded to App Store Connect under your App ID
- [ ] App ID `com.pangtuwi.ColorNote` has **Push Notifications** capability enabled in the Apple Developer Portal
- [ ] Test push on a real device after TestFlight upload (simulator cannot receive pushes)

### Signing & Capabilities
- [ ] Correct **provisioning profile** selected for the target (Distribution profile for TestFlight/App Store)
- [ ] **Team** is set to the correct Apple Developer account
- [ ] **Bundle identifier** in Xcode build settings matches `com.pangtuwi.ColorNote`

### Storyboard / URL Schemes
- [ ] Dropbox URL scheme `db-t3rygg2sue2w8yj` in Info.plist — confirm whether Dropbox integration is still in use; remove if not, as unused URL schemes can cause App Review queries

### App Store Connect
- [ ] Screenshots uploaded for all required device sizes
- [ ] App description, keywords, and support URL are current
- [ ] Privacy policy URL is set (required if app collects any user data; cloud sync/account creation counts)
- [ ] Export Compliance: `ITSAppUsesNonExemptEncryption = false` is already set ✓

---

## Backend (Irids_Web)

### Environment Variables
Set these in the `.env` file on the **production server** (not just locally).

| Variable | Development | TestFlight | Production |
|---|---|---|---|
| `NODE_ENV` | `development` | `production` | `production` |
| `APNS_PRODUCTION` | `false` | `true` | `true` |
| `BASE_URL` | `http://localhost:3002` | `https://irids.co.uk` | `https://irids.co.uk` |
| `GOOGLE_CALLBACK_URL` | `http://localhost:3002/oauth/google/callback` | `https://irids.co.uk/oauth/google/callback` | `https://irids.co.uk/oauth/google/callback` |
| `SESSION_SECRET` | any string | **strong random secret** | **strong random secret** |
| `JWT_SECRET` | any string | **strong random secret** | **strong random secret** |
| `APNS_BUNDLE_ID` | `com.pangtuwi.ColorNote` | `com.pangtuwi.ColorNote` | `com.pangtuwi.ColorNote` |
| `APNS_KEY_ID` | key ID from Developer Portal | same | same |
| `APNS_TEAM_ID` | team ID from Developer Portal | same | same |
| `APNS_KEY_PATH` | path to `.p8` file | path on server | path on server |

- [ ] `NODE_ENV=production` — enables secure session cookies (HTTPS only)
- [ ] `APNS_PRODUCTION=true` — sends pushes via the production APNs endpoint; TestFlight and App Store builds require this
- [ ] `SESSION_SECRET` is a long, random, unique string — **not** the placeholder from `.env.example`
- [ ] `JWT_SECRET` is a long, random, unique string — **not** the default `your_jwt_secret_key_here`
- [ ] `BASE_URL=https://irids.co.uk` — used in share link URLs returned to the iOS app
- [ ] `GOOGLE_CALLBACK_URL` points to the production domain

### Security
- [ ] **`.env` is not committed to the repository** — confirmed: `.env` is listed in `.gitignore` and is not tracked ✓
- [ ] Server is behind HTTPS — session cookies use `secure: true` only when `NODE_ENV=production`, so HTTPS must be terminating traffic
- [ ] Production server is not exposing any debug endpoints publicly

### Database
- [ ] Run `node scripts/migrations.js` (or start the server once) to apply all schema migrations on the production database before the new app version goes live
- [ ] Current target schema version is **15** — verify `PRAGMA user_version` on the production DB matches
- [ ] Take a database backup before deploying a migration

### Process Management
- [ ] App is running under **PM2** (`pm2 start ecosystem.config.js`) so it restarts on crash and survives server reboots
- [ ] `pm2 startup` has been run to enable auto-start on system boot
- [ ] After deploying: `./restart.sh` (runs `npm ci --omit=dev` then `pm2 restart all`)

### APNs `.p8` Key
- [ ] The `.p8` key file exists on the production server at the path specified by `APNS_KEY_PATH`
- [ ] The key has **Apple Push Notifications service (APNs)** listed under its services in the Apple Developer Portal
- [ ] The key belongs to the same team as the app (`APNS_TEAM_ID`)

---

## End-to-End Smoke Tests (After Deployment)

Run these on a real device using the TestFlight or production build:

- [ ] Register a new account and verify JWT is stored
- [ ] Create a note and confirm it syncs to the server
- [ ] Share a note with a second account — confirm push notification is received on the recipient's device
- [ ] Accept the share — confirm the note appears in the "Shared" category without a manual sync
- [ ] Edit a shared note on one device — confirm the change propagates to the other
- [ ] Log out and log back in — confirm all notes re-download correctly

---

## Quick Reference: Generating Strong Secrets

```bash
# Generate a 64-character random secret suitable for SESSION_SECRET or JWT_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```
