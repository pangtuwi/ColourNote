# ColourNote iOS App

## Repository Layout

This project spans two directories:

- `/Users/paulwilliams/Documents/Programming/ColourNote/` — iOS Swift frontend (this repo)
- `/Users/paulwilliams/Documents/Programming/Irids_Web/` — Node.js backend

## Project Overview
ColourNote is a feature-rich iOS note-taking application with color-coded organization, category management, and security features. The app is built in Swift using UIKit and uses SQLite for local data persistence.

**Current Version**: 1.3.0 (Build 12)

**Current Status**: The app has comprehensive note-taking functionality including category management, passcode protection, soft delete with trash, backup/restore capabilities, and cloud sync. The codebase has been fully cleaned of legacy fitness tracking code and is now 100% focused on note-taking.

## Architecture

### Tech Stack
- **Language**: Swift 5
- **UI Framework**: UIKit (Storyboard-based)
- **Database**: SQLite via SQLite.swift library
- **Dependency Manager**: CocoaPods
- **Minimum iOS Version**: 15.0+
- **Security**: SHA-256 hashing for passcode protection
- **Architecture Pattern**: MVC (Model-View-Controller)

### Key Features
- ✍️ **Quick Note Taking** - Create and edit notes with auto-save functionality
- 🎨 **Color-Coded Organization** - Notes inherit color from their assigned category
- 📁 **Category Management** - Organize notes into custom categories with personalized colors
- 🔒 **Passcode Protection** - Protect sensitive categories with 4-digit PIN (SHA-256 encrypted)
- 🗑️ **Soft Delete & Trash** - Deleted notes move to trash with restore capability
- 📤 **Backup & Export** - Export all notes and categories to JSON format
- 📥 **Import Notes** - Import notes from JSON backup files
- 🔍 **Search & Filter** - Search by title and filter by category
- 💾 **Local Storage** - All data stored securely on-device using SQLite
- ✂️ **Copy & Paste** - Full text editing with copy, cut, paste support
- 📱 **Pull-to-Refresh** - Manual refresh of notes list
- 🔓 **Session-based Unlocking** - Protected categories remain unlocked during app session
- ☁️ **Cloud Sync** - Sync notes and categories across devices with JWT authentication

### Core Components

#### Data Layer
**Location**: `Shared/Note/`, `Shared/NoteList/`, and `Shared/Category/`

1. **Note.swift** (`Shared/Note/Note.swift`)
   - Model class representing a single note
   - Properties: `noteId`, `uuid`, `noteName`, `editedTime`, `noteText`, `categoryId`, `isDeleted`, `deletedDate`, `contentFormat`
   - UUID generated automatically on creation for cloud sync identification
   - Note color is determined by the associated category

2. **Category.swift** (`Shared/Category/Category.swift`)
   - Model class representing a note category
   - Properties: `categoryId`, `uuid`, `categoryName`, `colorHex`, `sortOrder`, `isProtected`, `modifiedAt`
   - UUID generated automatically on creation for cloud sync identification
   - `modifiedAt` timestamp for delta sync and conflict resolution (v1.2+)
   - Helper methods:
     - `getColor()` - converts hex string to UIColor
     - `getDefaultCategories()` - returns default category set
   - UIColor extension for hex string conversion

3. **NoteRecords.swift** (`Shared/NoteList/NoteRecords.swift:19`)
   - Singleton database manager: `NoteRecords.instance`
   - Handles all SQLite operations for notes and categories
   - Database file: `colornote.db` (created in Documents directory on first launch)
   - Includes automatic database migration system
   - Key methods for Notes:
     - `getNotes()` - fetch all active notes
     - `getNote(searchNoteId:)` - fetch specific note
     - `getNotesForCategory(categoryId:)` - fetch notes by category
     - `updateNoteText(changedNoteId:newText:)` - save note changes
     - `updateNoteCategory(noteId:categoryId:)` - change note category
     - `softDeleteNote(noteId:)` - move note to trash
     - `undeleteNote(noteId:)` - restore note from trash
     - `getDeletedNotes()` - fetch trashed notes
     - `insertNote(note:)` - create new note
   - Key methods for Categories:
     - `getCategories()` - fetch all categories
     - `getCategory(categoryId:)` - fetch specific category
     - `addCategory(name:colorHex:)` - create new category
     - `updateCategory(categoryId:name:colorHex:sortOrder:)` - update category
     - `deleteCategory(categoryId:)` - delete category
     - `getCategoryPasscode(categoryId:)` - get hashed passcode
     - `setCategoryPasscode(categoryId:passcode:)` - set SHA-256 hashed passcode
     - `verifyCategoryPasscode(categoryId:passcode:)` - verify passcode

4. **Database Schema**

   **Table: `notes`** (Schema Version 10)
   - `_id` (INTEGER, PRIMARY KEY) - Unique note identifier
   - `uuid` (TEXT) - UUID for cloud sync and cross-device identification
   - `title` (TEXT) - Note title
   - `created_date` (INTEGER) - Creation timestamp in milliseconds since epoch
   - `modified_date` (INTEGER) - Last modification timestamp in milliseconds since epoch
   - `note` (TEXT) - Note content
   - `category_id` (INTEGER) - Foreign key to categories table (note color comes from category)
   - `active_state` (INTEGER) - 0 = active, 1 = deleted (soft delete)
   - `deleted_date` (INTEGER, nullable) - Deletion timestamp in milliseconds since epoch
   - `content_format` (TEXT) - Content format (default: "markdown")
   - Note: `color_index` column deprecated and no longer used - notes use category color

   **Table: `categories`** (Schema Version 3)
   - `category_id` (INTEGER, PRIMARY KEY) - Unique category identifier
   - `uuid` (TEXT) - UUID for cloud sync and cross-device identification
   - `category_name` (TEXT) - Category display name
   - `color_hex` (TEXT) - Category color in #RRGGBB format
   - `sort_order` (INTEGER) - Display order for categories
   - `is_protected` (INTEGER) - 0 = unprotected, 1 = protected with passcode
   - `passcode_hash` (TEXT, nullable) - SHA-256 hash of 4-digit PIN
   - `modified_at` (INTEGER, nullable) - Last modification timestamp for delta sync (v3+)
   - Index: `idx_categories_uuid` on uuid column (v3+)

   **Table: `sync_mappings`** (Schema Version 10)
   - `id` (INTEGER, PRIMARY KEY AUTOINCREMENT) - Unique mapping identifier
   - `local_id` (INTEGER) - Local entity ID
   - `cloud_id` (TEXT) - Cloud server ID
   - `entity_type` (TEXT) - "note" or "category"
   - `last_synced` (INTEGER, nullable) - Last sync timestamp in milliseconds since epoch
   - `sync_status` (TEXT) - "synced", "pending_upload", "pending_download", "conflict"
   - `created_at` (INTEGER) - Record creation timestamp
   - `modified_at` (INTEGER) - Record modification timestamp
   - `etag` (TEXT, nullable) - ETag for optimistic concurrency control (v10+)
   - Index: `idx_notes_uuid` on notes.uuid column (v10+)

#### Cloud Sync Layer
**Location**: `Shared/CloudSync/`

1. **APIConfig.swift** - API configuration constants
   - Base URL: `https://irids.co.uk`
   - Endpoint paths for auth, notes, categories, sharing, and inbox
   - Sharing endpoints (v1.3+): `registerDeviceToken`, `sharesInbox`, `shareAccept(token:)`, `shareDecline(token:)`
   - Keychain keys for JWT token storage
   - Request timeout settings

2. **NetworkManager.swift** - HTTP client singleton
   - Generic request methods (GET, POST, PUT, DELETE)
   - JWT token management in iOS Keychain
   - Automatic Authorization header injection
   - Response parsing with Codable
   - WAL mode enabled for concurrent database access
   - **Automatic re-authentication**: 401 and 403 responses trigger `attemptReauthentication`, which re-logs in with stored Keychain credentials and retries the original request. Applies to all request paths including ETag-based PUT requests.
   - **Delta Sync Support (v1.2+)**:
     - GET with query parameters for `since` timestamp filtering
     - 304 Not Modified handling for unchanged data
   - **ETag Support (v1.2+)**:
     - PUT with If-Match header for optimistic concurrency
     - 412 Precondition Failed handling for conflicts
     - ETag extraction from response headers

3. **CloudModels.swift** - API data models
   - `CloudNote` - Server note structure with integer IDs and timestamps
   - `CloudCategory` - Server category structure
   - `AuthResponse` - Login/register response with JWT
   - `CreateNoteRequest` / `CreateCategoryRequest` - Request bodies
   - `SuccessMessageResponse` - For update operations
   - `ShareNoteRequest` / `ShareNoteResponse` - Request/response for note sharing
   - `DeviceTokenRequest` - APNs device token registration body (v1.3+)
   - `InboxShare` - Single share entry with `isExpired` computed property (v1.3+)
   - `InboxResponse` - Inbox response with `receivedPending`, `receivedAccepted`, `sent` arrays (v1.3+)
   - `AcceptShareResponse` - Accept response containing recipient note UUID (v1.3+)
   - `EmptyBody` - Encodable stub for POST endpoints with no request body (v1.3+)
   - Timestamp conversion utilities

4. **AuthManager.swift** - Authentication management
   - `register(email:password:)` - New user registration
   - `login(email:password:)` - Authenticate and store JWT
   - `logout()` - Clear stored credentials
   - `isLoggedIn` - Check authentication status

5. **SyncMapping.swift** - ID mapping between local and cloud
   - Maps local integer IDs to cloud string IDs
   - Tracks sync status per entity
   - Stores mappings in SQLite `sync_mappings` table
   - **Sync Status Values**:
     - `synced` - Entity is in sync with cloud
     - `pendingUpload` - Entity needs to be uploaded
     - `pendingDownload` - Entity needs to be downloaded
     - `conflict` - Conflict detected, needs resolution
     - `pendingPermanentDelete` - Entity awaiting permanent deletion on cloud (v1.3+)
   - **UUID-based lookup methods**:
     - `findLocalNoteByUUID(_:)` - Find note by UUID
     - `findLocalCategoryByUUID(_:)` - Find category by UUID
     - `noteExistsLocally(uuid:)` - Check if note exists by UUID
     - `categoryExistsLocally(uuid:)` - Check if category exists by UUID
   - ID mapping methods: `getCloudId()`, `getLocalId()`, `createMapping()`, `updateStatus()`
   - **ETag methods (v1.2+)**:
     - `getEtag(localId:entityType:)` - Get stored ETag for entity
     - `updateEtag(localId:entityType:newEtag:)` - Update stored ETag
   - **`resetConnection()`** — closes the current SQLite connection and reopens it. Used by Cloud Restore after deleting and recreating the database file, since the singleton may have been initialized at launch with a stale connection to the old (now-deleted) file.

6. **CategorySyncService.swift** - Category synchronization
   - `uploadAllCategories()` - Push local categories to cloud
     - **Pending-upload filter**: Only uploads categories with no cloud mapping (new) or `pendingUpload` sync status. Previously-synced unmodified categories are skipped.
     - `markForUpload(categoryId:)` - Mark a category as needing upload (called from `CategoriesViewController` after any mutation)
   - `downloadAllCategories(since:)` - Pull cloud categories locally (delta sync v1.2+)
   - **UUID-first matching** (priority order):
     1. PRIMARY: Match by UUID (cross-device identification)
     2. SECONDARY: Match by cloud ID mapping
     3. TERTIARY: Match by category name (backwards compatibility)
   - Updates existing categories with cloud data including UUID
   - **ETag conflict handling (v1.2+)**:
     - Sends If-Match header with stored ETag on updates
     - `handleCategoryConflict()` - Resolves 412 conflicts using timestamp comparison

7. **NoteSyncService.swift** - Note synchronization
   - `uploadAllNotes()` - Push local notes to cloud
     - **Pending-upload filter**: Only uploads notes with no cloud mapping (new) or `pendingUpload` sync status. Previously-synced unmodified notes are skipped.
     - `markForUpload(noteId:)` - Mark a note as needing upload (called from `NoteDetailViewController.saveNote()` after every save)
   - `downloadAllNotes(since:)` - Pull cloud notes locally (delta sync v1.2+)
   - Skips empty notes during upload
   - Conflict resolution: most recent wins
   - **UUID-first matching** (priority order):
     1. PRIMARY: Match by UUID (cross-device identification)
     2. SECONDARY: Match by cloud ID mapping
     3. TERTIARY: Match by note title (backwards compatibility)
   - Maps category IDs between local and cloud
   - **ETag conflict handling (v1.2+)**:
     - Sends If-Match header with stored ETag on updates
     - `handleNoteConflict()` - Resolves 412 conflicts using timestamp comparison
   - **Permanent deletion sync (v1.3+)**:
     - `permanentlyDeleteCloudNote(localId:)` - Delete single note permanently
     - `permanentlyDeleteCloudNotes(localIds:)` - Batch permanent delete
     - `processPendingPermanentDeletes()` - Process queued deletions
     - `markForPermanentDelete(localId:)` - Queue note for cloud deletion
     - `handleServerSideDeletions(cloudNoteIds:)` - Handle server-deleted notes
     - `downloadAllNotesWithDeletionHandling(since:)` - Download with deletion detection

8. **SharingService.swift** - Note sharing and inbox API calls
   - Singleton: `SharingService.shared`
   - Dependency-injected `NetworkManaging` for testability (same pattern as other services)
   - `createShare(noteUUID:recipientEmail:completion:)` — POST `/notes/{uuid}/share` → returns share URL string
   - `registerDeviceToken(_:completion:)` — POST `/auth/device-token` → registers APNs token with server (hex-encoded)
   - `fetchInbox(completion:)` — GET `/shares/inbox` → returns `InboxResponse` (received pending, received accepted, sent sub-arrays)
   - `acceptShare(token:completion:)` — POST `/share/{token}/accept` → returns `AcceptShareResponse` with recipient note UUID
   - `declineShare(token:completion:)` — POST `/share/{token}/decline` → marks share as declined
   - Used by `NotesListViewController.showShareAccessFlow` to obtain a shareable link
   - See `SHAREDNOTESSPEC.md` for the full backend implementation spec

9. **SyncEngine.swift** - Orchestrates full sync
   - `syncAll()` - Full bidirectional sync
   - `uploadLocalChanges()` - Upload only
   - `downloadCloudChanges()` - Download only
   - Progress callbacks for UI updates
   - `syncIfNeeded()` - Guards on `isAutoSyncEnabled`, `isLoggedIn`, and `!isSyncing`; logs reason if skipped
   - Auto-sync on app launch/foreground (if enabled); also triggered after note save, note delete, and swipe-to-delete
   - Auto-sync is enabled automatically when the user logs in or registers
   - **Per-entity sync timestamps (v1.2+)**:
     - `getLastCategorySyncTime()` / `saveLastCategorySyncTime()` - Track category sync
     - `getLastNoteSyncTime()` / `saveLastNoteSyncTime()` - Track note sync
     - Passes `since` parameter to download methods for delta sync
   - **Sync phases** (v1.3+):
     - `starting` → `uploadingCategories` → `downloadingCategories` → `uploadingNotes` → `downloadingNotes` → `processingPermanentDeletes` → `complete`
   - **Permanent deletion processing (v1.3+)**:
     - `processPendingPermanentDeletes()` - Processes queued permanent deletes after note sync
     - Full sync detects and handles server-side deletions

#### View Controllers
**Location**: `ColourNote/`

1. **NotesListViewController.swift** (`ColourNote/NotesListViewController.swift:17`)
   - Main list view showing all active (non-deleted) notes
   - Features:
     - Pull-to-refresh functionality
     - Search/filter by title
     - Category filtering dropdown
     - Sorts notes by most recently edited
     - Color-coded cells based on category
     - Swipe-to-delete (soft delete to trash)
     - Long-press menu for copy, paste, delete
     - Tap to open note in full screen
     - Passcode protection check for protected categories
     - Share swipe action presents an action sheet: "Send note contents" (plain text via UIActivityViewController) or "Share access with another user" (calls `showShareAccessFlow`)
     - Hamburger menu includes "Shared Notes" item → `showSharedInbox()` → pushes `SharedInboxViewController`
   - `showShareAccessFlow(note:sourceView:sourceRect:)` — guards on login, prompts for recipient email, calls `SharingService.createShare`, then shows a toast "Note shared with [email]" on success (push notification handles delivery; no share sheet presented)
   - `showSharedInbox()` — pushes `SharedInboxViewController` onto the navigation stack
   - Outlets: `StatusLabel`, `SearchTextEditor`, `CategoryFilter`
   - Shows locked icon for protected category notes

2. **NoteDetailViewController.swift** (`ColourNote/NoteDetailViewController.swift:15`)
   - Full-screen note editing and viewing
   - Features:
     - Text editing with comprehensive auto-save
     - Title editing
     - Category assignment/changing
     - **Inline category creation** - Create new categories without leaving note editor
     - Copy/paste functionality
     - Delete button (soft delete to trash)
     - Keyboard handling with content inset adjustment
     - Color-coded background based on category
     - Note creation (when opened with no noteId)
   - Auto-saves when:
     - View is about to disappear
     - App enters background or becomes inactive
     - User taps back/list button
     - User taps outside text area (keyboard dismissal)
     - Category is changed
   - Category Creation Methods:
     - `showCreateCategoryFlow()` - Presents name entry alert with validation
     - `showColorPickerForNewCategory(categoryName:)` - Shows color picker
     - `saveNewCategoryAndSelect(categoryName:color:)` - Creates and assigns category
     - `showAlert(title:message:)` - Displays error messages
     - `showSuccessToast(message:)` - Shows success feedback
   - Implements UIColorPickerViewControllerDelegate for color selection

3. **CategoriesViewController.swift** (`ColourNote/CategoriesViewController.swift`)
   - Category management interface
   - Features:
     - List all categories with color swatches
     - Add new categories with custom name and color
     - Edit existing categories
     - Delete categories (with note reassignment)
     - Toggle passcode protection per category
     - Set/change/remove passcode for categories
     - Reorder categories (sort order)
     - Color picker integration
   - Validates category names and handles conflicts

4. **TrashViewController.swift** (`ColourNote/TrashViewController.swift`)
   - Trash bin for soft-deleted notes
   - Features:
     - List all deleted notes with deletion date
     - Restore individual notes (undelete)
     - Permanently delete notes
     - Empty trash (delete all)
     - Search deleted notes
     - Shows time since deletion
   - Notes can be restored to their original category

5. **PasscodeViewController.swift** (`ColourNote/PasscodeViewController.swift`)
   - Passcode entry interface
   - Features:
     - 4-digit PIN entry
     - Visual feedback (dots filling)
     - Shake animation on incorrect passcode
     - Different modes: set, verify, change, remove
     - SHA-256 hashing of passcodes
     - Session-based unlocking (stays unlocked during app session)
   - Used for both setting and verifying category passcodes

6. **SharedInboxViewController.swift** (`ColourNote/SharedInboxViewController.swift`)
   - In-app inbox for shared notes (v1.3+)
   - Three-section `UITableViewController`: **Received** (pending/declined), **Accepted**, **Sent by Me**
   - Section headers hidden when their data array is empty
   - `viewWillAppear`: clears app badge (`applicationIconBadgeNumber = 0`) and calls `loadInbox()`
   - `loadInbox()`: guards on `AuthManager.shared.isLoggedIn`, calls `SharingService.shared.fetchInbox`, reloads table
   - Pull-to-refresh via `UIRefreshControl`
   - Empty state label when no shares exist or user is not logged in
   - **Received section**: pending non-expired rows have `.disclosureIndicator`; tap shows accept/decline alert; trailing swipe shows green Accept + red Decline actions
   - **`acceptShare(share:indexPath:)`**: calls `SharingService.shared.acceptShare(token:)`, shows toast, triggers `SyncEngine.shared.syncIfNeeded()`, reloads inbox
   - **`declineShare(share:indexPath:)`**: calls `SharingService.shared.declineShare(token:)`, reloads inbox
   - Accessible via hamburger menu → "Shared Notes", or via notification tap → `AppDelegate.navigateToInbox()`

7. **LoginViewController.swift** (`ColourNote/LoginViewController.swift`)
   - Initial registration screen shown on first app launch
   - **Glass UI design** (fully programmatic — storyboard elements hidden at runtime):
     - `CAGradientLayer` background: deep purple → indigo → azure diagonal gradient
     - Two semi-transparent decorative orbs (purple top-left, cyan bottom-right)
     - `UIVisualEffectView(.systemUltraThinMaterial)` frosted glass card centered on screen
     - App icon (`irids_bg` asset or `note.text` SF Symbol fallback) displayed as a 72×72 `UIImageView` with `cornerRadius = 18`, `clipsToBounds = true`, and `scaleAspectFill` — no container view or gradient layer
     - "ColourNote" title + "Your notes, beautifully organised" subtitle
     - Glass buttons with SF Symbol icon, two-line label, trailing chevron, and press animations (scale + alpha)
     - `gradientLayer` resized in `viewDidLayoutSubviews()` to handle rotation correctly
     - Storyboard IBOutlets set to `isHidden = true` AND `isUserInteractionEnabled = false` as belt-and-suspenders
   - Four startup options (as glass buttons):
     - **Start Fresh** (`doc.badge.plus`, blue) — creates a blank local database
     - **Import Backup** (`arrow.down.doc.fill`, amber) — imports notes/categories from a JSON file
     - **Cloud Sync** (`arrow.triangle.2.circlepath.icloud`, indigo/purple) *(always visible)* — presents `CloudLoginViewController` for login/register, then downloads all data from the cloud server; `performCloudSyncRestore()` handles the post-auth DB setup and download
     - **Cloud Restore** (`icloud.and.arrow.down.fill`, green) *(shown only when Keychain credentials exist from a previous install)* — silently re-authenticates and downloads all data from the cloud server
   - Cloud Sync flow: present `CloudLoginViewController` → `onLoginSuccess` callback → `performCloudSyncRestore()`: creates blank DB → initialises singletons → `resetConnection()` → `registerForPushAfterLogin()` → `SyncEngine.downloadCloudChanges` → navigates home
   - Cloud Restore flow: creates blank DB → initialises singletons → calls `SyncMapping.shared.resetConnection()` to fix any stale connection → logs in → `registerForPushAfterLogin()` → calls `SyncEngine.downloadCloudChanges` → navigates home
   - Spinner overlay with status message ("Restoring from cloud...") during restore


#### UI Components

1. **RoundUIView.swift**
   - Reusable rounded corner view component

#### Configuration & Utilities

1. **Globals.swift** (`Shared/Globals.swift:14`)
   - Singleton for shared data: `Globals.sharedInstance`
   - Color palettes: `CN_COLORS` and `CN_LIGHT_COLORS` (10 colors each)
   - Temporary state variables:
     - `noteIDToDisplay` - ID of note to open in detail view
     - `unlockedCategories` - Set of category IDs unlocked in current session
   - Session management for passcode-protected categories

2. **NotesNotification.swift** (`Shared/NotesNotification.swift`)
   - Notification system for content updates
   - `NotesNotification.contentUpdated` - Posted when notes or categories change
   - Used by view controllers to refresh content

3. **AppDelegate.swift** (`ColourNote/AppDelegate.swift:19`)
   - App lifecycle management
   - Launches to `ColorNoteHomeID` (navigation controller) if registered, else `loginViewControllerID`
   - Pre-initializes database on background thread for faster startup
   - Handles app termination and passcode session cleanup
   - **Push Notifications (v1.3+)**:
     - Conforms to `UNUserNotificationCenterDelegate`
     - `requestPushPermissionsIfNeeded()` — requests `.alert .sound .badge` permission if not yet determined; calls `registerForRemoteNotifications()` if already authorised
     - `registerForPushAfterLogin()` — public entry point called by `LoginViewController` and `CloudLoginViewController` immediately after successful auth
     - `didRegisterForRemoteNotificationsWithDeviceToken` — uploads token to server via `SharingService.shared.registerDeviceToken(_:)`; silently logs on failure
     - `didFailToRegisterForRemoteNotificationsWithError` — logs error to console
     - `willPresent(_:withCompletionHandler:)` — shows banner + sound + badge when notification arrives in foreground
     - `didReceive(_:withCompletionHandler:)` — tapping a `type == "note_share"` notification calls `navigateToInbox()`
     - `navigateToInbox()` — pushes `SharedInboxViewController` onto the root navigation controller; deduplicates if already on stack

4. **Info.plist**
   - Bundle identifier: `$(PRODUCT_BUNDLE_IDENTIFIER)`
   - Display name: "ColourNote"
   - Version: 1.02 (Build 3)
   - Custom fonts: Bai Jamjuree, Audiowide
   - Minimum iOS: 15.0
   - Dropbox URL scheme configured

## Navigation Flow

```
AppDelegate (launch)
    └─> LoginViewController (if not registered)
    └─> Navigation Controller → NotesListViewController (if registered)
        ├─> Present Modal: NoteDetailViewController
        │   └─> Present Modal: PasscodeViewController (if category protected)
        ├─> Present Modal: PasscodeViewController (for viewing protected notes)
        └─> Category Filter (inline)

Note: CategoriesViewController, TrashViewController, and SettingsViewController are accessible from the
NotesListViewController via navigation/presentation (exact implementation depends on storyboard setup).

Passcode Flow:
- Access protected category notes → PasscodeViewController (verify)
- Change note to protected category → PasscodeViewController (verify)
- Set category passcode → PasscodeViewController (set/confirm)
- Change category passcode → PasscodeViewController (verify old, set new)
- Remove category passcode → PasscodeViewController (verify)
- Export with protected categories → PasscodeViewController (verify each)
```

## Data Flow

1. **App Launch**:
   - `NoteRecords.init()` opens database from Documents directory
   - Runs `migrateDatabaseIfNeeded()` to apply any schema updates
   - Initializes `Globals.sharedInstance.unlockedCategories` as empty set
   - If no database exists, LoginViewController prompts user to create blank database or import backup

2. **Viewing Notes**:
   - `NotesListViewController.updateNotesList()` → `NoteRecords.instance.getNotes()`
   - Optionally filter by category: `getNotesForCategory(categoryId:)`
   - Sorts by `editedTime` descending (most recent first)
   - Filters by search text if provided
   - Checks if note's category is protected and locked
   - Shows lock icon for locked protected notes

3. **Creating Notes**:
   - User taps "New Note" button
   - `NoteDetailViewController` opened with `noteIDToDisplay = 0`
   - User enters title and text
   - On save: `NoteRecords.addNote()` creates new note with current timestamp
   - Note assigned to selected category or default category
   - Returns to notes list with new note visible

4. **Editing Notes**:
   - Tap note in list → Check if category is protected
   - If protected and locked → Present `PasscodeViewController` for verification
   - On passcode success → Add category to `Globals.unlockedCategories`
   - `NoteDetailViewController` presented modally
   - `Globals.sharedInstance.noteIDToDisplay` set to selected note ID
   - `viewDidAppear` loads note data via `NoteRecords.getNote()`
   - Text changes tracked via `textViewDidChange`
   - Title changes tracked via title field delegate
   - Category changes trigger `updateNoteCategory()`
   - Auto-save on dismiss via `viewWillDisappear`

5. **Saving**:
   - `NoteRecords.updateNoteText()` updates text and `modified_date` timestamp
   - Uses concurrent dispatch queue for thread safety
   - Timestamps stored as milliseconds since epoch
   - All saves are automatic, no explicit save button needed

6. **Deleting Notes (Soft Delete)**:
   - User swipes note or taps delete button
   - `NoteRecords.softDeleteNote()` sets `active_state = 1` and `deleted_date = now`
   - Note removed from main list, appears in trash
   - Original category and all data preserved

7. **Restoring from Trash**:
   - User taps restore in `TrashViewController`
   - `NoteRecords.undeleteNote()` sets `active_state = 0` and clears `deleted_date`
   - Note returns to original category in main list

8. **Category Management**:
   - `CategoriesViewController` displays all categories
   - Add: `NoteRecords.addCategory()` creates new category
   - Edit: `NoteRecords.updateCategory()` modifies properties
   - Delete: Reassigns notes to default category, then deletes
   - Toggle protection: Shows passcode UI to set/remove passcode

9. **Passcode Protection**:
   - Set passcode: User enters 4-digit PIN twice
   - PIN hashed with SHA-256 before storage
   - Verification: Hash entered PIN and compare to stored hash
   - Session unlock: Verified categories added to `Globals.unlockedCategories`
   - Session expires: On app termination, `unlockedCategories` cleared

10. **Backup/Export**:
    - Export creates JSON with notes array and categories array
    - Protected categories require passcode verification before export
    - Timestamps and all metadata included
    - File saved to Files app or shared via share sheet

11. **Import**:
    - User selects JSON file
    - Parser validates format
    - Notes and categories imported with conflict resolution
    - Protected categories maintain their protection status


## Known Issues & Technical Debt

1. **Error Handling**: Some database operations have limited error handling
   - Most operations use try-catch but don't always provide user feedback
   - Could improve error messages shown to users

2. **Thread Safety**: Concurrent queue usage but inconsistent return patterns
   - Some methods return on main thread, others don't
   - Generally safe but could be more consistent

3. **Category Model Duplication**: Category.swift exists in two locations
   - Root directory: `Category.swift`
   - Shared directory: `Shared/Category/Category.swift`
   - Both must be kept in sync when making changes

4. **Passcode Storage**: Uses in-memory storage for session unlock tracking
   - Hashed passcodes stored securely in database
   - Session unlock state could use more secure storage mechanism

5. **Testing**: See **[TESTS.md](TESTS.md)** for full test documentation.
   - 47 unit tests across 8 suites using Swift Testing framework (`ColourNoteXCTests/`)
   - 13 UI tests across 4 suites using XCUITest (`ColourNoteXCUITests/`)
   - `NoteRecords` / `CategoryRecords` singletons are out of scope for unit tests (hard-coded SQLite path)

## File Structure

```
ColourNote/
├── ColourNote/                    # Main app target
│   ├── ViewControllers
│   │   ├── NotesListViewController.swift      # Main notes list
│   │   ├── NoteDetailViewController.swift     # Note editing/viewing
│   │   ├── CategoriesViewController.swift     # Category management
│   │   ├── TrashViewController.swift          # Deleted notes
│   │   ├── PasscodeViewController.swift       # Passcode UI
│   │   ├── SharedInboxViewController.swift    # Shared notes inbox (v1.3+)
│   │   ├── SettingsViewController.swift       # Settings & backup
│   │   ├── LoginViewController.swift          # Initial registration
│   │   ├── CloudLoginViewController.swift     # Cloud sync login/register
│   │   ├── SyncSettingsViewController.swift   # Cloud sync settings
│   │   └── SyncProgressView.swift             # Sync progress overlay
│   ├── UI Components
│   │   └── RoundUIView.swift                 # Rounded corner view
│   ├── Storyboards/
│   │   └── Base.lproj/Main.storyboard
│   ├── AppDelegate.swift
│   └── Info.plist
├── Shared/                        # Shared models and utilities
│   ├── Note/
│   │   └── Note.swift            # Note model
│   ├── Category/
│   │   └── Category.swift        # Category model
│   ├── NoteList/
│   │   ├── NoteRecords.swift     # Database manager (singleton)
│   │   └── NoteListing.swift
│   ├── CloudSync/               # Cloud synchronization
│   │   ├── APIConfig.swift      # Server configuration
│   │   ├── NetworkManager.swift # HTTP client
│   │   ├── CloudModels.swift    # API data models
│   │   ├── AuthManager.swift    # Authentication
│   │   ├── SyncMapping.swift    # ID mapping
│   │   ├── CategorySyncService.swift
│   │   ├── NoteSyncService.swift
│   │   ├── SharingService.swift # Note sharing API calls
│   │   └── SyncEngine.swift     # Sync orchestration
│   ├── Globals.swift             # App-wide constants & state
│   ├── NotesNotification.swift   # Notification system
│   └── SpinnerViewController.swift
├── ColourNoteXCTests/             # Unit test target (Swift Testing, 47 tests across 8 suites)
│   ├── Helpers/
│   │   ├── MockURLProtocol.swift  # URLProtocol subclass for HTTP-level tests
│   │   ├── MockNetworkManager.swift # NetworkManaging stub (offline, configurable)
│   │   └── TestFixtures.swift    # Factory methods for model instances
│   ├── NoteModelTests.swift       # 7 tests: Note model
│   ├── CategoryModelTests.swift   # 11 tests: Category model + UIColor hex extension
│   ├── CloudModelsTests.swift     # 12 tests: Codable, conversions, sharing models
│   ├── NetworkManagerTests.swift  # 6 tests: Keychain + HTTP via URLProtocol
│   ├── AuthManagerTests.swift     # 7 tests: offline via MockNetworkManager
│   ├── NoteSyncServiceTests.swift # 5 tests: download paths + permanent delete
│   ├── CategorySyncServiceTests.swift # 4 tests: download paths + markForUpload
│   └── SharingServiceTests.swift  # 5 tests: createShare success, error, endpoint, body, HTTP error
├── ColourNoteXCUITests/           # UI test target (XCUITest, 13 tests across 4 suites)
│   ├── Helpers/
│   │   └── UITestCase.swift      # Base class: fresh-install reset, tapStartFresh()
│   ├── LaunchTests.swift          # 2 tests: login screen, Start Fresh navigation
│   ├── NotesListTests.swift       # 4 tests: nav bar, search field, add button, editor open
│   ├── NoteDetailTests.swift      # 4 tests: title edit, content edit, back button, list update
│   └── SharingUITests.swift       # 3 tests: swipe share button, action sheet options, sign-in guard
├── Category.swift                 # Category model (duplicate - keep in sync)
├── Bai_Jamjuree Font/            # Custom font files
├── Podfile                        # CocoaPods dependencies
├── README.md                      # User-facing documentation
├── CLAUDE.md                      # Technical documentation (this file)
├── SHAREDNOTESSPEC.md             # Backend spec for Shared Notes feature (Irids_Web)
├── NOTIFICATION_SETUP.md          # APNs setup guide: Developer Portal, Xcode, env vars, server
└── .gitignore
```

## Dependencies

**CocoaPods** (via Podfile):
- `SQLite.swift` - Type-safe SQLite database wrapper for all database operations


## Build Configuration

- **Platform**: iOS 15.0+
- **Language**: Swift 5
- **Xcode**: 13.0 or later required
- **Database Location**: Documents directory at runtime (`/Documents/colornote.db`)
- **Database Creation**: Created on first launch or imported from backup
- **Bundle Identifier**: Configurable via PRODUCT_BUNDLE_IDENTIFIER
- **Deployment**: Configured for App Store distribution

## Version History

### 1.3.0 (Build 12) - Current Release
- **APNs Push Notifications** — recipient receives a push notification the moment a note is shared with them
  - `AppDelegate` conforms to `UNUserNotificationCenterDelegate`; requests permission and registers for remote notifications after login
  - `AppDelegate.registerForPushAfterLogin()` called by both `LoginViewController` and `CloudLoginViewController` immediately after successful auth, ensuring token is uploaded on first login regardless of app state
  - `didRegisterForRemoteNotificationsWithDeviceToken` uploads hex-encoded token via `SharingService.registerDeviceToken(_:)` → `POST /auth/device-token`
  - Tapping a `type == "note_share"` notification opens the app directly to `SharedInboxViewController` via `AppDelegate.navigateToInbox()`
  - Foreground notifications display as banner + sound + badge
  - Token upload failure is silent (logged to console); token is automatically re-uploaded on next cold launch since `requestPushPermissionsIfNeeded()` runs every launch when registered
- **In-App Shared Notes Inbox** (`SharedInboxViewController`) — three-section table view accessible from the hamburger menu → "Shared Notes"
  - **Received** section: pending and declined shares from other users; pending non-expired rows can be accepted (green swipe / alert) or declined (red swipe / alert)
  - **Accepted** section: previously accepted shares (read-only)
  - **Sent by Me** section: outgoing shares with current status
  - Badge clears to 0 on `viewWillAppear`; pull-to-refresh supported
  - Accept triggers `SyncEngine.shared.syncIfNeeded()` so the shared note appears immediately after accepting
- **Backend: APNs service** (`Irids_Web/utils/apnsService.js`) — lazy-initialised `@parse/node-apn` provider; silently disabled when env vars absent; `POST /share/{uuid}/share` triggers fire-and-forget push to all of recipient's registered devices
- **Backend: device token endpoint** (`POST /auth/device-token`) — upserts token with `ON CONFLICT(user_id, token) DO UPDATE SET updated_at`; supports multiple devices per user
- **Backend: inbox endpoint** (`GET /shares/inbox`) — returns enriched `received_pending`, `received_accepted`, `sent` sub-arrays with note titles and owner/recipient emails
- **Backend: decline endpoint** (`POST /share/:token/decline`) — recipient marks a pending share as declined; validated against `recipient_email`
- **Backend: migration 15** — `device_tokens` table with `UNIQUE(user_id, token)` index
- **New models** (`CloudModels.swift`): `DeviceTokenRequest`, `InboxShare` (with `isExpired`), `InboxResponse`, `AcceptShareResponse`, `EmptyBody`
- **New endpoint constants** (`APIConfig.swift`): `registerDeviceToken`, `sharesInbox`, `shareAccept(token:)`, `shareDecline(token:)`
- **New `SharingService` methods**: `registerDeviceToken(_:)`, `fetchInbox()`, `acceptShare(token:)`, `declineShare(token:)`
- **`NOTIFICATION_SETUP.md`** — step-by-step guide: Apple Developer Portal key generation, Xcode capability, local env vars, production server setup, troubleshooting

### Post-1.3.0 Bug Fixes (Backend + iOS)
- **Bug fix (backend)**: `POST /share/:token/accept` — recipient's note copy now uses `modified_date = Date.now()` instead of copying the owner's `modified_date`; the old value was older than the recipient's `lastNoteSyncTime`, causing delta sync to silently skip the note
- **Bug fix (backend)**: `POST /share/:token/accept` — accepted notes are now automatically placed in a "Shared" category (created with `color_hex = '#4A86E8'` if it doesn't exist for the recipient); previously `category_id` was NULL and the note appeared uncategorised
- **Bug fix (backend)**: `POST /notes/:uuid/share` — duplicate shares are now prevented; if a non-expired pending share already exists for the same note + recipient, the existing token/URL is returned instead of creating a new row and sending a duplicate push notification
- **Bug fix (iOS)**: `showShareAccessFlow` — removed erroneous `UIActivityViewController` presentation after successful share creation; the share sheet (meant for "Send note contents") was incorrectly appearing after "Share access with another user" completed; replaced with a toast message
- **Bug fix (backend)**: APNS `[APNS] Failed` log now includes `f.response` alongside `f.error` so rejection reasons (e.g. `TopicDisallowed`) are visible in logs

### 1.2.3 (Build 11) — Merged (Shared_Notes branch)
- **Shared Note Access** — users can share collaborative access to a note with another ColourNote user
  - Share swipe action presents an action sheet: "Send note contents" (existing plain-text share) or "Share access with another user"
  - New `SharingService.swift` singleton: `POST /notes/{uuid}/share` → returns a shareable URL
  - New `ShareNoteRequest` / `ShareNoteResponse` models in `CloudModels.swift`
  - `NotesListViewController.showShareAccessFlow` — prompts for recipient email, spins while creating the share, then shows a toast on success (push notification handles delivery)
  - `SHAREDNOTESSPEC.md` — full backend spec for the Irids_Web Node.js implementation (migration v14, `note_shares` table, 5 new endpoints, server-side propagation)
- **Bug fix**: `LoginViewController` `initializeAppWithDatabase()` and `cloudRestoreButtonTapped()` now set `"DatabaseSchemaVersion" = 10` and `"CategoryDatabaseSchemaVersion" = 3` after `createBlankDatabase()` — previously used the wrong key `"DatabaseVersion"`, causing NoteRecords/CategoryRecords to run migrations against an already-complete schema and leaving `CategoryDatabaseSchemaVersion = 3` without the actual columns in place on subsequent runs
- **Bug fix**: `CategoryRecords.ensureRequiredCategoryColumns()` — new defensive repair called at the end of `migrateCategorySchemaIfNeeded()` every time; uses `PRAGMA table_info(categories)` to detect missing columns (`is_protected`, `uuid`, `modified_at`) and adds them regardless of stored schema version, preventing the `Fatal error: No such column "uuid"` crash
- **Bug fix**: Notes downloaded from cloud showing "No Category" after a fresh Start Fresh install — `initializeAppWithDatabase()` now calls `SyncMapping.shared.resetConnection()` after `createBlankDatabase()`
- **Bug fix**: `createBlankDatabase()` now creates the complete v10 `notes` schema and `sync_mappings` table inline
- **Bug fix**: `initializeAppWithDatabase()` and `cloudRestoreButtonTapped()` now clear `lastNoteSyncTime` and `lastCategorySyncTime` from UserDefaults to force full download on fresh install
- **Bug fix**: `SyncEngine.syncCategories()` — on first sync downloads categories before uploading to prevent mapping collisions
- **AppDelegate `UI_TESTING_FRESH_INSTALL`**: Now also clears `lastNoteSyncTime` and `lastCategorySyncTime` from UserDefaults
- **Tests**: `SharingServiceTests.swift` (5 tests) + 2 Codable tests in `CloudModelsTests.swift` + `SharingUITests.swift` (3 XCUITests) — total 47 unit tests, 13 UI tests across 4 suites
- **Bug fix**: `NoteDetailViewController` — removed erroneous `canPerformAction(_:withSender:)` override that caused a crash when cutting text in preview mode
- **Bug fix**: `NoteRecords.updateNoteText` and `NoteRecords.updateNoteTitle` — both now use `DispatchSemaphore` to wait for the barrier write before returning, fixing a race condition where sync-downloaded edits were not visible after a single sync cycle

## Security Considerations

### Passcode Protection
- **Hashing**: All passcodes are hashed using SHA-256 before storage
- **Storage**: Hashed passcodes stored in SQLite database (categories table)
- **Session Management**: Unlocked categories tracked in memory only (`Globals.unlockedCategories`)
- **Session Expiry**: All sessions cleared on app termination
- **No Plain Text**: Passcodes never stored or logged in plain text
- **4-Digit PIN**: Balance between security and usability

### Data Storage
- **Local Primary**: All data stored locally on device with optional cloud sync
- **SQLite Database**: Located in app's Documents directory
- **WAL Mode**: Write-Ahead Logging enabled for better concurrent access
- **Backup Considerations**: Database included in iTunes/iCloud backups
- **File Protection**: Uses default iOS file protection (protected until first unlock)

### Cloud Sync Security
- **JWT Authentication**: Tokens stored securely in iOS Keychain
- **HTTPS**: All server communication uses HTTPS encryption
- **Token Expiry**: Expired tokens require re-authentication
- **No Password Storage**: Only JWT tokens stored, not user passwords
- **Protected Categories**: `is_protected` flag synced but NOT passcode hashes

### Potential Security Improvements
1. Add biometric authentication (Face ID/Touch ID) as alternative to PIN
2. Implement automatic session timeout (e.g., after 5 minutes of inactivity)
3. Add app-level passcode/biometric lock
4. Enhance file protection level to `completeUnlessOpen`
5. Implement data encryption at rest
6. Add password strength requirements (longer PINs or alphanumeric)
7. Implement failed attempt tracking and lockout
8. Add secure enclave storage for passcode hashes
9. Clear clipboard after timeout for copy/paste operations
10. Add option to exclude database from device backups

### Export Security
- Protected categories require passcode verification before export
- Exported JSON files are unencrypted (user should secure the files)
- Consider adding encryption option for exported JSON files

## Important Notes

### For Developers
1. **Category Model Sync**: When editing `Category.swift`, update BOTH copies (root and `Shared/Category/`)
2. **Database Migrations**: Always test migrations on databases with old schemas before release
3. **Thread Safety**: All database operations use concurrent queue, but UI updates must be on main thread
4. **Passcode Security**: Never log, print, or display passcodes in plain text
5. **Session State**: Always clear `Globals.unlockedCategories` on app termination
6. **Notifications**: Use `NotesNotification.contentUpdated` to notify views when data changes

### For Users
1. All data is stored locally on the device by default
2. Cloud sync is optional and requires account registration
3. Passcode-protected categories are session-based (re-enter passcode after app restart)
4. Deleted notes are moved to trash and can be restored
5. Export creates unencrypted JSON files - keep them secure
6. Forgotten passcodes cannot be recovered (data will remain locked)
7. Cloud sync preserves note content but NOT category passcodes

---

**Last Updated**: June 3, 2026
**Maintainer**: Paul Williams
**Current Project**: ColourNote (Note-Taking App)
**Sync Engine Version**: 1.4
