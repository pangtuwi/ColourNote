# ColourNote

A beautiful and simple iOS note-taking app with color-coded organization. Create, edit, and manage your notes with an intuitive interface and persistent local storage.

![iOS](https://img.shields.io/badge/iOS-12.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## Features

- ✍️ **Quick Note Taking** - Create and edit notes with a clean, distraction-free interface
- 🎨 **Color-Coded Organization** - Choose from 10 beautiful colors to organize your notes
- 📝 **Lined Paper View** - Write on a familiar lined paper interface
- 🔍 **Search & Filter** - Quickly find notes by title
- 💾 **Local Storage** - All notes saved securely on-device using SQLite
- ⚡ **Auto-Save** - Changes saved automatically as you type
- 📱 **Pull-to-Refresh** - Easy sync and update interface

## Screenshots

<!-- Add screenshots here when available -->

## Technical Details

### Built With

- **Language**: Swift
- **UI Framework**: UIKit (Storyboard-based)
- **Database**: SQLite via [SQLite.swift](https://github.com/stephencelis/SQLite.swift)
- **Dependency Manager**: Swift Package Manager
- **Minimum iOS Version**: 12.0+

### Architecture

- **MVC Pattern** - Clean separation of model, view, and controller logic
- **Singleton Database Manager** - Thread-safe database operations
- **Custom UI Components** - LinedTextView with custom drawing
- **Responsive Design** - Adapts to different screen sizes and orientations

## Installation

### Prerequisites

- Xcode 12.0 or later
- iOS device or simulator running iOS 12.0+

### Setup

1. Clone the repository:
```bash
git clone https://github.com/pangtuwi/ColourNote.git
cd ColourNote
```

2. Open the workspace:
```bash
open ColourNoteProj.xcworkspace
```

3. Dependencies are managed via Swift Package Manager and will be automatically resolved by Xcode

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
- Tap "Done" to dismiss the keyboard
- Tap "List" to return to the notes list

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

The app uses SQLite with the following schema:

**Table: `notes`**
| Column | Type | Description |
|--------|------|-------------|
| _id | INTEGER | Primary key |
| title | TEXT | Note title |
| modified_date | INTEGER | Last edit timestamp (ms) |
| note | TEXT | Note content |
| color_index | INTEGER | Color category (0-9) |

## Color Palette

ColourNote uses a 10-color palette for note organization:

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

### Planned Features

- [ ] Note creation UI
- [ ] Note deletion functionality
- [ ] Color picker for notes
- [ ] Rich text formatting
- [ ] Note categories/folders
- [ ] Cloud sync support
- [ ] Note sharing
- [ ] Checklist support
- [ ] Voice notes
- [ ] Image attachments
- [ ] Export to PDF/Text
- [ ] Dark mode support

### Known Issues

See [CLAUDE.md](CLAUDE.md) for detailed technical documentation and known issues.

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive technical documentation
- **Code Comments** - Inline documentation throughout the codebase

## Dependencies

- [SQLite.swift](https://github.com/stephencelis/SQLite.swift) v0.15.4 - Type-safe SQLite database wrapper (via Swift Package Manager)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Original project evolved from a fitness tracking app (EFRT)
- Font: Bai Jamjuree (Google Fonts)
- Custom font: Audiowide

## Author

**Paul Williams**

## Version History

- **1.0** - Initial release
  - Basic note viewing and editing
  - SQLite database integration
  - Color-coded organization
  - Search functionality

---

**Note**: This app stores all data locally on your device. No data is transmitted to external servers.
