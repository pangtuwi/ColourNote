# ColourNote

A beautiful and simple iOS note-taking app with color-coded organization. Create, edit, and manage your notes with an intuitive interface and persistent local storage.

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![Version](https://img.shields.io/badge/version-1.1-brightgreen.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

- ✍️ **Quick Note Taking** - Create and edit notes with a clean, distraction-free interface
- 🎨 **Color-Coded Organization** - Notes are colored based on their assigned category
- 📁 **Category Management** - Organize notes into custom categories with personalized colors
- ⚡ **Inline Category Creation** - Create new categories on-the-fly without leaving the note editor
- 🔒 **Passcode Protection** - Protect sensitive categories with a 4-digit PIN (SHA-256 encrypted)
- 🗑️ **Soft Delete & Trash** - Deleted notes move to trash with restore capability
- 📤 **Backup & Export** - Export notes to JSON format with category information
- 📥 **Import Notes** - Import notes from JSON backup files
- 🔍 **Search & Filter** - Quickly find notes by title or filter by category
- 💾 **Local Storage** - All notes saved securely on-device using SQLite
- ⚡ **Auto-Save** - Changes saved automatically when navigating away, backgrounding app, or dismissing keyboard
- ✂️ **Copy & Paste** - Full text editing with copy, cut, paste support
- 📱 **Pull-to-Refresh** - Easy sync and update interface
- 📝 **Markdown Support** - Write in Markdown with Edit/Preview toggle for formatted text
- ☁️ **Cloud Sync** - Sync notes and categories across devices with secure JWT authentication

## Screenshots

<!-- Add screenshots here when available -->

## Technical Details

### Built With

- **Language**: Swift
- **UI Framework**: UIKit (Storyboard-based)
- **Database**: SQLite via [SQLite.swift](https://github.com/stephencelis/SQLite.swift)
- **Dependency Manager**: CocoaPods
- **Minimum iOS Version**: 15.0+
- **Security**: SHA-256 hashing for passcode protection

### Architecture

- **MVC Pattern** - Clean separation of model, view, and controller logic
- **Singleton Database Manager** - Thread-safe database operations
- **Custom UI Components** - RoundUIView with rounded corners and shadows
- **Responsive Design** - Adapts to different screen sizes and orientations

## Installation

### Prerequisites

- Xcode 13.0 or later
- iOS device or simulator running iOS 15.0+
- CocoaPods installed

### Setup

1. Clone the repository:
```bash
git clone https://github.com/pangtuwi/ColourNote.git
cd ColourNote
```

2. Install dependencies:
```bash
pod install
```

3. Open the workspace:
```bash
open ColourNoteProj.xcworkspace
```

4. Build and run the project (⌘+R)

## Usage

### Creating Notes
1. Tap on the Notes tab
2. Select a note or create a new one
3. Type your content in the lined text area
4. Notes auto-save when you navigate away

### Organizing Notes
- Notes are automatically color-coded based on their assigned color index
- Sort by most recently edited (automatic)
- Use the search bar to filter notes by title

### Editing Notes
- Tap any note from the list to open it
- Edit the text content
- Tap outside the text area to dismiss the keyboard
- Tap "< List" to return to the notes list
- Changes auto-save when you navigate away or background the app

## Project Structure

```
ColourNote/
├── ColourNote/              # Main app target
│   ├── ViewControllers/     # UI controllers
│   ├── UI Components/       # Custom UI elements
│   ├── Storyboards/         # Interface Builder files
│   └── Resources/           # Fonts, images, etc.
├── Shared/                  # Shared models and utilities
│   ├── Note/               # Note model
│   ├── NoteList/           # Database manager
│   └── Globals.swift       # App-wide constants
└── Pods/                   # CocoaPods dependencies
```

## Database Schema

The app uses SQLite with the following schema (current version: 9):

**Table: `notes`**
| Column | Type | Description |
|--------|------|-------------|
| _id | INTEGER | Primary key |
| uuid | TEXT | UUID for cloud sync |
| title | TEXT | Note title |
| created_date | INTEGER | Creation timestamp (ms since epoch) |
| modified_date | INTEGER | Last edit timestamp (ms since epoch) |
| note | TEXT | Note content |
| category_id | INTEGER | Category reference (color comes from category) |
| active_state | INTEGER | 0=active, 1=deleted |
| deleted_date | INTEGER | Deletion timestamp (ms since epoch) |
| content_format | TEXT | Content format (default: "markdown") |

**Table: `categories`**
| Column | Type | Description |
|--------|------|-------------|
| category_id | INTEGER | Primary key |
| uuid | TEXT | UUID for cloud sync |
| category_name | TEXT | Category display name |
| color_hex | TEXT | Category color (#RRGGBB) |
| sort_order | INTEGER | Display order |
| is_protected | INTEGER | 0=unprotected, 1=protected |

**Table: `sync_mappings`** (Cloud Sync)
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key (auto-increment) |
| local_id | INTEGER | Local entity ID |
| cloud_id | TEXT | Cloud server ID |
| entity_type | TEXT | "note" or "category" |
| last_synced | INTEGER | Last sync timestamp (ms since epoch) |
| sync_status | TEXT | "synced", "pending_upload", "pending_download", "conflict" |
| created_at | INTEGER | Record creation timestamp |
| modified_at | INTEGER | Record modification timestamp |

## Color Palette

ColourNote uses category colors for note organization. Categories can be assigned any color via the color picker. The following 10-color palette is available as preset options:

| Index | Color | Hex |
|-------|-------|-----|
| 0 | White | #FFFFFF |
| 1 | Pink/Red | #F58584 |
| 2 | Orange | #FEA853 |
| 3 | Yellow | #F5DA65 |
| 4 | Green | #96D467 |
| 5 | Blue | #83A5FF |
| 6 | Purple | #B387DE |
| 7 | Dark Gray | #333333 |
| 8 | Light Gray | #CCCCCC |
| 9 | Off White | #F0F0F0 |

## Development

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Completed Features

- [x] Note creation and editing UI
- [x] Soft delete with trash functionality
- [x] Category management
- [x] Inline category creation from note editor
- [x] Passcode protection for categories
- [x] Backup/Export to JSON
- [x] Import from JSON
- [x] Copy/paste support
- [x] Search and filter
- [x] Markdown support with Edit/Preview toggle
- [x] Cloud sync with JWT authentication

### Planned Features

- [x] ~~Rich text formatting~~ → Implemented via Markdown
- [x] Cloud sync support (in progress - basic sync working)
- [ ] Note sharing
- [ ] Checklist support
- [ ] Voice notes
- [ ] Image attachments
- [ ] Export to PDF/Text
- [ ] Dark mode support
- [ ] Widgets
- [ ] Siri shortcuts

### Known Issues

See [CLAUDE.md](CLAUDE.md) for detailed technical documentation and known issues.

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive technical documentation
- **Code Comments** - Inline documentation throughout the codebase

## Dependencies

- [SQLite.swift](https://github.com/stephencelis/SQLite.swift) - Type-safe SQLite database wrapper (via CocoaPods)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Original project evolved from a fitness tracking app (EFRT)
- Font: Bai Jamjuree (Google Fonts)
- Custom font: Audiowide

## Author

**Paul Williams**

## Version History

- **1.2 (Build 5)** - Current Release (February 3, 2026)
  - **New Feature**: Cloud Sync with JWT Authentication
  - Bidirectional sync of notes and categories with cloud server
  - Login/Register UI for cloud account management
  - UUID-based sync matching for reliable cross-device identification
  - Database schema v9 with UUID columns and sync_mappings table
  - Sync priority: UUID first, cloud ID second, name matching as fallback
  - Auto-sync on app launch/foreground (when enabled)

- **1.1 (Build 4)** - (February 1, 2026)
  - **New Feature**: Markdown Support
  - Edit/Preview toggle in note editor
  - Native Markdown renderer (headers, bold, italic, code, lists, links, blockquotes)
  - Category color theming with contrasting text
  - Database schema v5 with content_format column
  - Reorganized note editor UI layout (title on line 1, controls on line 2)
  - Fixed storyboard constraint issues

- **1.03 (Build 5)** - (January 1, 2026)
  - **New Feature**: Inline category creation from note editor (Issue #4)
  - Users can now create categories without leaving the note editing screen
  - Added "Create New Category..." option to category picker
  - Full validation with duplicate name checking
  - New categories automatically assigned to current note
  - Success toast notification for user feedback
  - **Bug Fix**: Added "Save" button to Edit Category dialog
  - Users can now save category name changes without requiring color selection
  - Closed GitHub Issues: #4

- **1.02 (Build 4)** - (December 31, 2025)
  - Optimized app launch performance with asynchronous notes loading
  - Fixed auto-save when app backgrounds (Issue #7)
  - Removed redundant Save button for cleaner UI
  - Enhanced auto-save reliability across all app states
  - Fixed storyboard identifier crashes
  - Removed unused LinedTextView code
  - Fixed compiler warnings
  - TextView background color now customizable
  - Implemented text placeholder for new notes
  - Fixed title capitalization
  - Closed GitHub Issues: #5, #6, #7, #9

- **1.02 (Build 3)**
  - Added passcode protection for categories
  - Implemented copy/paste functionality
  - Session-based unlocking
  - Enhanced export/backup with passcode validation

- **1.01**
  - Added soft delete with trash functionality
  - Category management with custom colors
  - Backup/Export to JSON
  - Import from JSON
  - Enhanced UI with category filtering

- **1.0** - Initial Release
  - Basic note viewing and editing
  - SQLite database integration
  - Color-coded organization
  - Search functionality

---

**Note**: This app stores all data locally on your device by default. Cloud sync is optional and requires user login. When enabled, notes and categories are synchronized with the cloud server using secure JWT authentication.
