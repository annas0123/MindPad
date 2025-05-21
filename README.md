# MindPad

MindPad is a feature-rich note-taking application built with Flutter that helps you organize your thoughts, ideas, and information efficiently.

## Features

### Rich Text Editing
- **Advanced Text Formatting**: Create beautifully formatted notes using the integrated Flutter Quill rich text editor
### Note Management
- **Create, Edit, Delete**: Easily create, edit, and delete notes
- **Note History**: Track changes with timestamps

### Folder Management
- **Create, Edit, Delete**: Easily create, edit, and delete folders

### Search Functionality
- **Quick Note Access**: Quickly find notes with the built-in search feature

### Note Customization
- **Note Color**: Customize the color of your notes for better organization
- **Note Lock**: Lock notes to prevent accidental modifications



### Powerful Organization
- **Folders**: Organize notes in a hierarchical folder structure
- **Tags**: Categorize notes with custom tags for easy filtering
- **Starred Notes**: Mark important notes as favorites for quick access

### User Experience
- **Multiple Themes**: Choose between light, dark, and custom themes
- **System Theme Integration**: Automatically adapts to your device's theme settings
- **Search Functionality**: Quickly find notes with the built-in search feature

### Data Management
- **Local Storage**: All notes are stored locally on your device using SQLite
- **Note History**: Track changes with timestamps

## Technical Details

### Architecture
- **Flutter Framework**: Cross-platform UI toolkit
- **Provider Pattern**: State management for reactive updates

- **SQLite Database**: Local data persistence

### Key Dependencies
- `flutter_quill`: Rich text editor implementation
- `sqflite`: SQLite database plugin for Flutter
- `provider`: State management solution
- `shared_preferences`: Local storage for app settings
- `path_provider`: File system access

## Getting Started

### Prerequisites
- Flutter SDK (version ^3.7.2)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
   ```
   git clone https://github.com/yourusername/MindPad.git
   ```

2. Navigate to the project directory
   ```
   cd MindPad
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Run the app
   ```
   flutter run
   ```

## Project Structure

- `lib/`
  - `main.dart`: Application entry point
  - `models/`: Data models (Note, Tag, Folder)
  - `screens/`: UI screens
  - `services/`: Business logic and data services
  - `theme/`: Theme configuration
  - `widgets/`: Reusable UI components

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All the package authors that made this project possible
