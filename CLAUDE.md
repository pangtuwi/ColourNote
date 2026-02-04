# ColourNote iOS App

## Project Overview
ColourNote is a feature-rich iOS note-taking application with color-coded organization, category management, and security features. The app is built in Swift using UIKit and uses SQLite for local data persistence.

**Current Version**: 1.1 (Build 4)

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
   - Base URL: `http://irids.co.uk`
   - Endpoint paths for auth, notes, and categories
   - Keychain keys for JWT token storage
   - Request timeout settings

2. **NetworkManager.swift** - HTTP client singleton
   - Generic request methods (GET, POST, PUT, DELETE)
   - JWT token management in iOS Keychain
   - Automatic Authorization header injection
   - Response parsing with Codable
   - WAL mode enabled for concurrent database access
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

6. **CategorySyncService.swift** - Category synchronization
   - `uploadAllCategories()` - Push local categories to cloud
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

8. **SyncEngine.swift** - Orchestrates full sync
   - `syncAll()` - Full bidirectional sync
   - `uploadLocalChanges()` - Upload only
   - `downloadCloudChanges()` - Download only
   - Progress callbacks for UI updates
   - Auto-sync on app launch/foreground (if enabled)
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

6. **LoginViewController.swift** (`ColourNote/LoginViewController.swift`)
   - Initial registration screen (legacy from fitness app)
   - Shows on first app launch


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

## Color System

**10-color palette** defined in Globals.swift:
- Index 0: White
- Index 1: Pink/Red
- Index 2: Orange
- Index 3: Yellow
- Index 4: Green
- Index 5: Blue
- Index 6: Purple
- Index 7: Dark Gray
- Index 8: Light Gray
- Index 9: Very Light Gray

Each color has a full-saturation and light-saturation variant.

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

5. **Testing**: Minimal test coverage
   - Test targets exist but contain minimal tests
   - Core functionality not comprehensively tested

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
│   │   └── SyncEngine.swift     # Sync orchestration
│   ├── Globals.swift             # App-wide constants & state
│   ├── NotesNotification.swift   # Notification system
│   └── SpinnerViewController.swift
├── Category.swift                 # Category model (duplicate - keep in sync)
├── Bai_Jamjuree Font/            # Custom font files
├── Podfile                        # CocoaPods dependencies
├── README.md                      # User-facing documentation
├── CLAUDE.md                      # Technical documentation (this file)
└── .gitignore
```

## Development Guidelines

### Adding a New Note
Fully implemented in NoteDetailViewController:
1. Open `NoteDetailViewController` with `Globals.noteIDToDisplay = 0`
2. User enters title and content
3. `NoteRecords.addNote()` generates unique ID automatically
4. Sets `created_date` and `modified_date` to current timestamp
5. Assigns to selected category (or default)
6. Saves to database and returns to list view

### Adding/Editing Categories
Fully implemented in CategoriesViewController:
1. Use `NoteRecords.addCategory(name:colorHex:)` to create
2. Use `NoteRecords.updateCategory()` to modify properties
3. Deletion requires reassigning notes to another category first
4. Passcode protection managed through PasscodeViewController
5. SHA-256 hashing handled automatically by NoteRecords

### Database Migrations
Implemented with version tracking:
1. Database schema versions tracked in database metadata
2. `migrateDatabaseIfNeeded()` runs on app launch
3. Migration code checks current schema version and applies updates incrementally
4. Current versions: Database schema v9 (Notes v7 UUID, Categories v8 UUID, Sync v6)
5. To add new migration:
   - Add version check in `migrateDatabaseIfNeeded()`
   - Apply schema changes with ALTER TABLE statements
   - Update version number in metadata
   - Test on database with old schema

### Implementing Passcode Protection
Pattern to follow when adding passcode-protected features:
1. Check if category is protected: `category.isProtected`
2. Check if category is unlocked: `Globals.unlockedCategories.contains(categoryId)`
3. If protected and not unlocked, present PasscodeViewController
4. On success, add to `Globals.unlockedCategories`
5. Session clears on app termination via AppDelegate
6. Always hash passcodes with SHA-256 before storage
7. Never store plain-text passcodes

### Adding New Database Tables
Follow existing pattern:
1. Define table and columns as `Table` and `Expression` in NoteRecords
2. Create table in `createTable()` or migration method
3. Add CRUD methods (Create, Read, Update, Delete)
4. Use concurrent queue for all database operations
5. Return results on main thread when needed for UI updates

### UI Customization
- **Colors**: Modify `Globals.CN_COLORS` and `Globals.CN_LIGHT_COLORS`
- **Fonts**:
  - Bai Jamjuree used for most UI elements
  - Audiowide for headers/titles
  - Change in Storyboard or programmatically in view controllers
- **Category colors**: Use hex color picker in CategoriesViewController

### Session Management Best Practices
1. Store unlocked categories in `Globals.unlockedCategories` (Set<Int>)
2. Clear session state in `AppDelegate.applicationWillTerminate()`
3. Never persist unlocked state beyond app session
4. Require re-authentication after app restart
5. Consider adding background/foreground state handling for additional security

## Dependencies

**CocoaPods** (via Podfile):
- `SQLite.swift` - Type-safe SQLite database wrapper for all database operations

## Testing

Test targets exist but have minimal coverage:
- `eFitTests/eFitTests.swift` - Unit tests (legacy names)
- `eFitUITests/eFitUITests.swift` - UI tests (legacy names)
- `FitFormTests/FitFormTests.swift` - Unit tests (legacy names)
- `FitFormUITests/FitFormUITests.swift` - UI tests (legacy names)

**Recommended Test Coverage:**
- NoteRecords database operations (CRUD)
- Category management and passcode verification
- Soft delete and restore functionality
- JSON import/export with various data scenarios
- Passcode hashing and session management

## Build Configuration

- **Platform**: iOS 15.0+
- **Language**: Swift 5
- **Xcode**: 13.0 or later required
- **Database Location**: Documents directory at runtime (`/Documents/colornote.db`)
- **Database Creation**: Created on first launch or imported from backup
- **Bundle Identifier**: Configurable via PRODUCT_BUNDLE_IDENTIFIER
- **Deployment**: Configured for App Store distribution

## Version History

### 1.02 (Build 3) - Current Release
- Added passcode protection for categories (SHA-256 hashing)
- Implemented session-based unlocking
- Enhanced export/backup with passcode validation
- Added copy/paste functionality in note editor
- Improved category management UI
- Toast notifications for note deletion

### 1.01 (Build 2)
- Implemented soft delete system with trash functionality
- Added category management with custom colors
- Created backup/export to JSON
- Implemented import from JSON
- Enhanced UI with category filtering
- Added note restoration from trash

### 1.0 (Build 1) - Initial Release
- Basic note creation and editing
- SQLite database integration
- Color-coded note organization
- Search and filter functionality
- Pull-to-refresh
- Auto-save on text changes

## Completed Features

- [x] Note creation and editing UI
- [x] Soft delete with trash functionality
- [x] Category management with custom colors
- [x] **Inline category creation** - Create categories from note editor
- [x] Passcode protection for categories (SHA-256)
- [x] Session-based unlocking
- [x] Backup/Export to JSON
- [x] Import from JSON
- [x] Copy/paste support
- [x] Search and filter by title
- [x] Filter by category
- [x] Database migration system
- [x] Lined text view for writing
- [x] Auto-save functionality
- [x] **Markdown support** - Edit/Preview toggle with native rendering
- [x] **Cloud sync** - JWT authentication with bidirectional sync
- [x] **UUID-based sync matching** - Cross-device identification with UUID priority

## Future Enhancements

Potential features to implement:

**High Priority:**
1. ~~Rich text formatting (bold, italic, lists)~~ → Implemented via Markdown
2. Note pinning/favorites
3. Dark mode support

**Medium Priority:**
4. Checklist/todo items within notes
5. Note sharing (export individual notes)
6. Export to PDF/Text formats
7. Improved search (search note content, not just titles)
8. Tags/labels in addition to categories
9. Note templates
10. Widgets for iOS home screen
11. Home/Dashboard screen with note statistics

**Low Priority/Future:**
12. ~~Cloud sync (iCloud)~~ → Implemented with custom server
13. Collaborative notes
14. Voice notes/audio recording
15. Image attachments
16. Siri shortcuts integration
17. Apple Watch companion app
18. iPad optimization with split view
19. Markdown support
20. Note linking/backlinks
21. Encryption for individual notes

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
- **HTTPS**: Server communication should use HTTPS in production
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

## Recent Changes

### February 4, 2026 - Backup System: Iridescence Format Support
- **New Backup Format (Iridescence v2)**
  - Exports now use Iridescence server-compatible format
  - Lowercase keys (`categories`, `notes` instead of `Categories`, `Notes`)
  - Added `summary` section with statistics (total_categories, total_notes, active_notes, trashed_notes, export_date)
  - Optional `user` section for cloud backups
  - Notes use `_id` (integer), `note` (content), `created_date`/`modified_date` (milliseconds)
  - Notes use `active_state` (0/1) instead of nested metadata
  - Categories include `is_protected` and `modified_at` fields
- **Backwards Compatible Import**
  - Auto-detects format based on JSON keys
  - Iridescence format: lowercase `categories`/`notes`
  - Legacy format: uppercase `Categories`/`Notes`
  - Both formats fully supported during import
- **New Data Models**
  - `BackupUser` - User info for cloud backups
  - `BackupSummary` - Export statistics
  - `IridescenceCategoryBackup` - Category in new format
  - `IridescenceNoteBackup` - Note in new format
  - `IridescenceBackupContainer` - Main container
  - Legacy models renamed with `Legacy` prefix
- **Import Enhancements**
  - `importNotesFromJSON()` auto-detects and routes to correct parser
  - `importIridescenceFormat()` - Handles new format
  - `importLegacyFormat()` - Handles old format
  - Better UUID handling during import

### February 3, 2026 - Sync Engine v1.3: Permanent Deletion Sync
- **Permanent Deletion Synchronization**
  - Notes permanently deleted from trash are now synced to the cloud
  - Uses `DELETE /notes/{cloud_id}/permanent` endpoint
  - Handles HTTP 200 OK (success) and 404 Not Found (already deleted)
  - Offline support with pending deletion queue
- **New Sync Status**
  - Added `pendingPermanentDelete` status to `SyncStatus` enum
  - Tracks notes awaiting permanent deletion on server
- **New API Endpoint**
  - Added `APIConfig.Endpoints.notePermanent(id:)` for permanent delete calls
- **New NoteSyncService Methods**
  - `permanentlyDeleteCloudNote(localId:)` - Delete single note permanently from cloud
  - `permanentlyDeleteCloudNotes(localIds:)` - Batch permanent delete
  - `getNotesPendingPermanentDelete()` - Get notes awaiting cloud deletion
  - `markForPermanentDelete(localId:)` - Mark note for pending permanent delete
  - `processPendingPermanentDeletes()` - Process queued permanent deletes
  - `handleServerSideDeletions(cloudNoteIds:)` - Detect and handle server-deleted notes
  - `downloadAllNotesWithDeletionHandling(since:)` - Download with server-side deletion detection
- **New NoteRecords Method**
  - `permanentlyDeleteNoteWithoutSync(noteId:)` - Delete locally without triggering sync
- **SyncEngine Updates**
  - Added `processingPermanentDeletes` sync phase
  - `syncAll()` now processes pending permanent deletes after note sync
  - `downloadCloudChanges()` now uses deletion-aware download
  - Full sync (no delta) detects notes permanently deleted on other devices
- **TrashViewController Updates**
  - `emptyTrashWithSync()` - Empty trash with cloud sync support
  - `permanentlyDeleteNoteWithSync(note:)` - Single note permanent delete with sync
  - Shows activity indicator during cloud deletion
  - Graceful offline handling with pending deletion queue
  - Warning alert when operating in offline mode
- **Offline Behavior**
  - When offline: marks sync mapping as `pendingPermanentDelete`, deletes locally
  - On next sync: `processPendingPermanentDeletes()` completes cloud deletion
  - 404 responses treated as success (note already deleted on server)
- **Server-Side Deletion Detection**
  - During full sync, compares local synced notes with server response
  - Notes missing from server (but have sync mapping) are deleted locally
  - Only runs during full sync (delta sync can't detect deletions)
- **Optimized 412 Conflict Resolution**
  - `NetworkError.preconditionFailed` now includes response body data
  - Conflict handlers parse `current_version` from 412 response body
  - Eliminates extra GET request when server returns current version
  - Falls back to GET request if response body parsing fails
  - New models: `NoteConflictResponse`, `CategoryConflictResponse`
  - Refactored: `handleNoteConflict()` and `handleCategoryConflict()` use response data
  - Added: `resolveNoteConflict()` and `resolveCategoryConflict()` helper methods

### February 3, 2026 - Sync Engine v1.2: Delta Sync & ETag Support
- **Delta Synchronization**
  - Downloads only entities modified since last sync using `since` query parameter
  - Per-entity sync timestamps tracked in UserDefaults:
    - `lastCategorySyncTime` - Last successful category download
    - `lastNoteSyncTime` - Last successful note download
  - Handles HTTP 304 Not Modified as success with 0 changes
  - Reduces bandwidth and improves sync performance
- **ETag Optimistic Concurrency Control**
  - Stores ETag in `sync_mappings.etag` column for each entity
  - Sends `If-Match` header with stored ETag on PUT requests
  - Server returns HTTP 412 Precondition Failed on ETag mismatch
  - Automatic conflict resolution using timestamp comparison:
    - Local newer → Force update (wins)
    - Cloud newer → Accept cloud version (cloud wins)
- **Database Schema Updates**
  - Notes schema v10: Added `idx_notes_uuid` index
  - Categories schema v3: Added `modified_at` column and `idx_categories_uuid` index
  - Sync mappings: Added `etag` column
- **Category Model Enhancement**
  - Added `modifiedAt: Int?` property to Category class
  - Auto-set on creation and update for conflict resolution
- **New NetworkManager Methods**
  - `get(endpoint:queryParams:)` - GET with query parameters
  - `put(endpoint:body:eTag:)` - PUT with ETag support
  - `performRequestWithETag()` - Extract ETag from response
- **New SyncMapping Methods**
  - `getEtag(localId:entityType:)` - Retrieve stored ETag
  - `updateEtag(localId:entityType:newEtag:)` - Store new ETag
- **New Sync Service Methods**
  - `downloadAllCategories(since:)` - Delta category download
  - `downloadAllNotes(since:)` - Delta note download
  - `handleCategoryConflict()` - 412 resolution for categories
  - `handleNoteConflict()` - 412 resolution for notes
- **CloudModels Updates**
  - Added `modifiedAt` to `CloudCategory` and `CreateCategoryRequest`
- **Documentation**
  - Updated `SYNC_DOCUMENTATION.md` to v1.2 with delta sync and ETag sections

### February 3, 2026 - UUID-Based Sync Matching
- **Enhanced Cloud Sync: UUID-First Matching**
  - UUID is now the PRIMARY means of comparison during synchronization
  - Enables reliable cross-device identification of notes and categories
  - Sync matching priority order:
    1. PRIMARY: Match by UUID (stable cross-device identifier)
    2. SECONDARY: Match by cloud ID mapping (existing sync relationship)
    3. TERTIARY: Match by name/title (backwards compatibility fallback)
- **New SyncMapping Methods**
  - `findLocalNoteByUUID(_:)` - Find a note by its UUID
  - `findLocalCategoryByUUID(_:)` - Find a category by its UUID
  - `noteExistsLocally(uuid:)` - Check if note exists by UUID
  - `categoryExistsLocally(uuid:)` - Check if category exists by UUID
- **NoteRecords Enhancement**
  - Added `updateNoteUUID(noteId:uuid:)` method for updating note UUIDs
- **CategoryRecords Enhancement**
  - `updateCategory()` now includes UUID in SQL update statement
- **CloudModels Updates**
  - Added `uuid` field to `CloudNote` and `CloudCategory` structs
  - Added `uuid` field to `CreateNoteRequest` and `CreateCategoryRequest`
  - Conversion methods now include UUID in both directions
- **Backup/Import Enhancement**
  - `NoteBackup.swift` now preserves UUIDs during import
  - Categories import with `category.uuid = backupCategory.uuid`
  - Notes import with `uuid: backupNote.uuid` parameter

### February 2, 2026 - Cloud Sync Feature
- **New Feature: Cloud Synchronization**
  - Bidirectional sync of notes and categories with cloud server
  - JWT-based authentication with secure Keychain storage
  - Login/Register UI (`CloudLoginViewController`)
  - Sync settings screen (`SyncSettingsViewController`)
  - Progress overlay during sync operations (`SyncProgressView`)
- **Cloud Sync Architecture** (`Shared/CloudSync/`)
  - `APIConfig.swift` - Server configuration and endpoints
  - `NetworkManager.swift` - HTTP client with JWT management
  - `CloudModels.swift` - API data models and conversion utilities
  - `AuthManager.swift` - User authentication
  - `SyncMapping.swift` - Local-to-cloud ID mapping
  - `CategorySyncService.swift` - Category sync logic
  - `NoteSyncService.swift` - Note sync logic
  - `SyncEngine.swift` - Sync orchestration
- **Database Schema Update**
  - Added `sync_mappings` table (migration to schema v6)
  - WAL mode enabled on all database connections for better concurrency
- **App Integration**
  - Cloud Sync option added to Settings menu
  - Auto-sync on app launch and foreground (when enabled)
  - Background sync when app enters background
  - NotesListViewController: Added "Cloud Sync" menu option
- **Sync Features**
  - Duplicate prevention: matches categories/notes by name before creating new
  - Conflict resolution: most recent modification wins
  - Empty notes skipped during upload
  - Category colors preserved during sync

### February 1, 2026 - Markdown Support
- **New Feature: Markdown Rendering**
  - Added Edit/Preview toggle in note editor (segmented control)
  - Native Markdown renderer without external dependencies (`Shared/Markdown/MarkdownRenderer.swift`)
  - Supports: headers (H1-H6), bold, italic, code blocks, inline code, lists, links, blockquotes, horizontal rules
  - Category color theming with contrasting text colors
  - Edit mode: raw markdown text editing
  - Preview mode: rendered formatted text (read-only)
- **Database Schema Update**
  - Added `content_format` column to notes table (migration to schema v5)
  - Default value: "markdown" for all notes
  - Backward compatible with existing notes
- **Model Updates**
  - `Note.swift`: added `contentFormat` property
  - `NoteBackup.swift`: exports/imports contentFormat field
- **UI Layout Reorganization**
  - NoteDetailViewController: Title on full-width line 1
  - Controls row (line 2): Edit/Preview toggle, Category button, Delete button
  - Cleaner separation between title and controls
- **Storyboard Cleanup**
  - Removed orphaned segmented control
  - Fixed LoginViewController button constraints
  - Removed stale `loadDefaultButton` outlet

### January 1, 2026 - Inline Category Creation & Bug Fixes
- **Bug Fix: Category Name Editing**
  - Added "Save" button to Edit Category dialog in CategoriesViewController
  - Users can now save category name changes without going through the color picker
  - Save button only appears when editing existing categories (not when creating new)
  - Includes validation for empty names and duplicate names
  - Posts notification to refresh other views after save
- **UI Improvements: Edit Category Dialog**
  - Save button positioned directly above Cancel button for better UX
  - Save button text colored green for positive action indication
  - Cancel button text colored red for dismissive action indication
  - Clear visual hierarchy for action buttons vs. confirmation buttons
- **New Feature: Create Categories On-the-Fly** (Issue #4)
  - Added "Create New Category..." option to category picker in NoteDetailViewController
  - Users can now create categories without leaving the note editing screen
  - Full validation: checks for empty names and duplicate names (case-insensitive)
  - New category is automatically assigned to the current note
  - Success toast notification provides feedback
  - Follows existing category creation patterns from CategoriesViewController
  - Added 7 new methods to NoteDetailViewController:
    - `showCreateCategoryFlow()` - Name entry with validation
    - `showColorPickerForNewCategory(categoryName:)` - Color selection
    - `saveNewCategoryAndSelect(categoryName:color:)` - Database insert and auto-assign
    - `showAlert(title:message:)` - Error alerts
    - `showSuccessToast(message:)` - Success feedback
  - Implemented UIColorPickerViewControllerDelegate for color picker handling
- **Closed GitHub Issues**: #4 (Create Category in category select UI)

### December 31, 2025 - Performance & UI Improvements
- **Optimized App Launch Performance**
  - Made notes loading asynchronous to prevent main thread blocking
  - Database initialization now happens synchronously to avoid race conditions
  - Added explicit window `makeKeyAndVisible()` call for faster UI display
  - Database loads in 0.003 seconds on average
- **Code Cleanup**
  - Removed unused LinedTextView.swift and updated documentation
  - Removed bundled sample database (colornote.db) and "Load Sample Notes" option
  - Removed `copyDatabaseIfNeeded()` function from NoteRecords
  - Fixed compiler warning in PasscodeViewController (unused `digit` variable)
  - Removed hardcoded grey background color for textView (now uses storyboard color)
- **UI Enhancements**
  - Implemented text placeholder for new note titles
  - Fixed title capitalization behavior
  - TextView background color now customizable via storyboard
  - Simplified LoginViewController to only show "Start Fresh" and "Import Backup" options
- **Closed GitHub Issues**: #2 (Sample database), #5 (Capitalization), #6 (Note heading text), #9 (Splash screen)

### December 2025 - Auto-Save Enhancement & UI Cleanup
- **Fixed GitHub Issue #7**: Implemented auto-save when app backgrounds
  - Added `UIApplication.willResignActiveNotification` observer in NoteDetailViewController
  - Notes now save automatically when switching apps, receiving calls, or app enters background
  - Prevents data loss when app is suspended
- **Removed Save Button**: Eliminated redundant Save button from note editing interface
  - Cleaner UI with fewer distractions
  - Relies entirely on comprehensive auto-save functionality
  - Auto-save triggers: view dismissal, backgrounding, keyboard dismissal, back button
- **Fixed Storyboard Identifier**: Corrected "NoteViewController" → "NoteDetailViewController"
  - Resolved crash when creating or opening notes
  - Fixed IBOutlet connections in storyboard

### December 2025 - Legacy Code Removal
- Removed all legacy fitness tracking code (~50-60 files, ~2 MB)
- Deleted unused view controllers (HomeViewController, NoteViewController, Note2ViewController)
- Deleted entire FitForm project and test directories
- Removed legacy icon folders and assets
- Simplified SettingsViewController to note-focused settings only
- Renamed DataLoaderNotification to NotesNotification for better semantics
- Cleaned up AppDelegate, removed push notification code
- Updated Globals.swift to remove EFRT colors
- App now launches directly to Notes list (no tab bar, no home screen)
- Codebase is now 100% focused on note-taking functionality

---

**Last Updated**: February 3, 2026
**Maintainer**: Paul Williams
**Original Project**: EFRT (Fitness Tracking App) - Legacy code fully removed December 2025
**Current Project**: ColourNote (Note-Taking App)
**Sync Engine Version**: 1.3
