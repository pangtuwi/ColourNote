# ColourNote iOS App

## Project Overview
ColourNote is an iOS note-taking application that allows users to create, view, edit, and organize colored notes. The app is built in Swift using UIKit and uses SQLite for local data persistence.

**Current Status**: The app has basic note-taking functionality with a database backend. The codebase appears to be a fork/adaptation of a fitness tracking app (EFRT), with many unused fitness-related components still present.

## Architecture

### Tech Stack
- **Language**: Swift
- **UI Framework**: UIKit (Storyboard-based)
- **Database**: SQLite via SQLite.swift library
- **Dependency Manager**: CocoaPods (Charts, SQLite.swift)
- **Platform**: iOS

### Core Components

#### Data Layer
**Location**: `Shared/Note/` and `Shared/NoteList/`

1. **Note.swift** (`Shared/Note/Note.swift`)
   - Model class representing a single note
   - Properties: `noteId`, `noteName`, `editedTime`, `noteText`, `colorIndex`

2. **NoteRecords.swift** (`Shared/NoteList/NoteRecords.swift:19`)
   - Singleton database manager: `NoteRecords.instance`
   - Handles all SQLite operations
   - Database file: `colornote.db` (copied from bundle to Documents on first launch)
   - Key methods:
     - `getNotes()` - fetch all notes
     - `getNote(searchNoteId:)` - fetch specific note
     - `getLatestNote()` - get most recently edited note
     - `updateNoteText(changedNoteId:newText:)` - save note changes
     - `noteExists(searchId:)` - check if note exists

3. **Database Schema**
   - Table: `notes`
   - Columns: `_id`, `title`, `modified_date`, `note`, `color_index`

#### View Controllers
**Location**: `ColourNote/`

1. **NotesListViewController.swift** (`ColourNote/NotesListViewController.swift:17`)
   - Main list view showing all notes
   - Features:
     - Pull-to-refresh functionality
     - Search/filter by title (`ColourNote/NotesListViewController.swift:239`)
     - Sorts notes by most recently edited
     - Color-coded cells
     - Tap to open note in full screen
   - Outlets: `StatusLabel`, `SearchTextEditor`

2. **NoteDetailViewController.swift** (`ColourNote/NoteDetailViewController.swift:15`)
   - Full-screen note editing view
   - Features:
     - Text editing with auto-save on dismiss
     - Keyboard handling with content inset adjustment
     - Done button to dismiss keyboard
     - Color-coded background
   - Auto-saves when:
     - User taps outside text view
     - View is about to disappear
     - Text changes detected

3. **NoteViewController.swift** (`ColourNote/NoteViewController.swift:12`)
   - Simple container view (appears incomplete/unused)

4. **Note2ViewController.swift** (`ColourNote/Note2ViewController.swift:11`)
   - Stub for adding new notes (incomplete)

5. **HomeViewController.swift** (`ColourNote/HomeViewController.swift:17`)
   - Home screen (currently shows fitness stats - needs updating for notes)

#### UI Components

1. **LinedTextView.swift** (`ColourNote/LinedTextView.swift:13`)
   - Custom UITextView with lined paper effect
   - Draws horizontal lines for writing
   - IBDesignable with shadow, border, corner radius support

2. **RoundUIView.swift**
   - Reusable rounded corner view component

#### Configuration & Utilities

1. **Globals.swift** (`Shared/Globals.swift:14`)
   - Singleton for shared data
   - Color palettes: `CN_COLORS` and `CN_LIGHT_COLORS` (10 colors each)
   - Temporary state: `noteIDToDisplay`

2. **AppDelegate.swift** (`ColourNote/AppDelegate.swift:19`)
   - App lifecycle management
   - Launches to `ColorNoteHomeID` if registered, else `loginViewControllerID`
   - Default tab: Notes list (index 1)
   - Push notification setup (from fitness app heritage)

3. **Info.plist**
   - Bundle identifier: `$(PRODUCT_BUNDLE_IDENTIFIER)`
   - Display name: "ColourNote"
   - Custom font: audiowide-regular.ttf
   - Dropbox URL scheme configured

## Navigation Flow

```
AppDelegate (launch)
    └─> LoginViewController (if not registered)
    └─> Tab Bar Controller (if registered)
        ├─> Tab 0: HomeViewController
        ├─> Tab 1: NotesListViewController (default)
        │   └─> Present Modal: NoteDetailViewController
        ├─> Tab 2: NoteViewController (Activity tab - legacy)
        └─> Other tabs (fitness-related - legacy)
```

## Data Flow

1. **App Launch**:
   - `NoteRecords.init()` copies database from bundle if needed
   - Opens database from Documents directory

2. **Viewing Notes**:
   - `NotesListViewController.updateNotesList()` → `NoteRecords.instance.getNotes()`
   - Sorts by `editedTime` descending
   - Filters by search text if provided

3. **Editing Notes**:
   - Tap note in list → `NoteDetailViewController` presented modally
   - `Globals.sharedInstance.noteIDToDisplay` set to selected note ID
   - `viewDidAppear` loads note data
   - Text changes tracked via `textViewDidChange`
   - Auto-save on dismiss via `viewWillDisappear`

4. **Saving**:
   - `NoteRecords.updateNoteText()` updates both text and timestamp
   - Uses concurrent dispatch queue for thread safety
   - Timestamp stored as milliseconds since epoch

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

1. **Legacy Code**: Large amount of unused fitness tracking code (ActivityRecords, Sport, TrainingStress, etc.)
2. **Incomplete Features**:
   - Note creation UI (`Note2ViewController`) is stubbed but not functional
   - Delete button in `NoteDetailViewController` has no implementation
   - Home screen still shows fitness data instead of note statistics
3. **Error Handling**: Limited error handling in database operations
4. **Thread Safety**: Concurrent queue usage but inconsistent return values
5. **Search Filtering**: Real-time filter has off-by-one timing issue (uses old text value)
6. **README**: Still describes fitness app, not notes app

## File Structure

```
ColourNote/
├── ColourNote/                    # Main app target
│   ├── ViewControllers
│   │   ├── NotesListViewController.swift
│   │   ├── NoteDetailViewController.swift
│   │   ├── NoteViewController.swift
│   │   ├── Note2ViewController.swift
│   │   └── HomeViewController.swift
│   ├── UI Components
│   │   ├── LinedTextView.swift
│   │   └── RoundUIView.swift
│   ├── Storyboards/
│   │   └── Base.lproj/Main.storyboard
│   ├── AppDelegate.swift
│   ├── Info.plist
│   └── colornote.db              # Initial database
├── Shared/                        # Shared code
│   ├── Note/
│   │   └── Note.swift
│   ├── NoteList/
│   │   ├── NoteRecords.swift     # Database manager
│   │   └── NoteListing.swift
│   ├── Globals.swift
│   └── [Many legacy fitness files]
├── Bai_Jamjuree Font/            # Font files
├── Podfile                        # CocoaPods dependencies
└── README.md                      # Needs updating
```

## Development Guidelines

### Adding a New Note
Not yet implemented. Should:
1. Generate new unique `noteId`
2. Set default `colorIndex` (0 = white)
3. Capture current timestamp for `editedTime`
4. Insert into database
5. Refresh list view

### Editing Note Properties
Currently only text editing is implemented. To add title editing:
1. Make `noteTitle` outlet editable in NoteDetailViewController
2. Add delegate method to detect changes
3. Update database on save with new title

### Database Migrations
Database is copied from bundle on first launch. Schema changes require:
1. Update bundled `colornote.db`
2. Add migration code in `NoteRecords.init()` for existing installations
3. Update table schema in `createTable()` method

### UI Customization
- Colors: Modify `Globals.CN_COLORS` and `Globals.CN_LIGHT_COLORS`
- Fonts: Change in Storyboard or programmatically in view controllers
- Line height: Adjust `LinedTextView.lineHeight` property

## Dependencies

**CocoaPods** (via Podfile):
- `SQLite.swift` - SQLite database wrapper
- `Charts` - Charting library (legacy, not used for notes)

## Testing

- Test targets exist but appear minimal:
  - `eFitTests/eFitTests.swift`
  - `eFitUITests/eFitUITests.swift`
  - `FitFormTests/FitFormTests.swift`
  - `FitFormUITests/FitFormUITests.swift`

## Build Configuration

- Platform: iOS 9.0+
- Xcode project files removed from git (`.pkgf` files present)
- Database location: Documents directory at runtime
- Initial database: Bundled in app

## Future Enhancements

Potential features to implement:
1. Note creation UI
2. Note deletion
3. Color selection/changing
4. Rich text formatting
5. Note categories/folders
6. Search improvements
7. Cloud sync
8. Note sharing
9. Checklists
10. Voice notes
11. Image attachments
12. Clean up legacy fitness code
