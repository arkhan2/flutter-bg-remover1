# Background Remover

A Flutter application for removing and replacing image backgrounds with ease.

## Features

- **Auto Background Removal** - AI-powered local background removal using the image package
- **Solid Color Backgrounds** - Replace backgrounds with any solid color
- **Gradient Backgrounds** - Beautiful gradient backgrounds with customizable colors
- **Blur Effect** - Apply blur effect to the original background
- **Undo/Redo** - Unlimited edit history
- **Export & Share** - Save as PNG (with transparency), JPEG, or WebP

## Screenshots

Coming soon...

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/background_remover.git
cd background_remover
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

#### Web
```bash
flutter build web --release
```

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 theme configuration
│   └── services/
│       ├── background_removal_service.dart  # Background removal logic
│       ├── image_processing_service.dart    # Image processing utilities
│       └── storage_service.dart             # Local storage management
├── models/
│   ├── edited_image.dart              # Edited image model
│   └── project.dart                   # Project model
├── providers/
│   ├── editor_provider.dart           # Editor state management
│   └── gallery_provider.dart          # Gallery state management
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   │   └── home_screen.dart       # Home screen
│   │   └── widgets/
│   │       └── feature_card.dart      # Feature card widget
│   ├── editor/
│   │   ├── presentation/
│   │   │   └── editor_screen.dart     # Editor screen
│   │   └── widgets/
│   │       ├── editor_toolbar.dart         # Editor toolbar
│   │       ├── background_options_sheet.dart # Background options
│   │       └── export_sheet.dart           # Export options
│   └── gallery/
│       └── presentation/
│           └── gallery_screen.dart    # Gallery screen
└── widgets/
    └── common/
        └── checkered_background.dart  # Transparency pattern widget
```

## Dependencies

- **flutter_riverpod** - State management
- **image_picker** - Image selection from gallery/camera
- **image** - Image processing and manipulation
- **flutter_colorpicker** - Color picker widget
- **photo_view** - Zoomable image view
- **path_provider** - File system access
- **share_plus** - Share functionality
- **dio** - HTTP client (for future API integrations)
- **permission_handler** - Runtime permissions
- **flutter_svg** - SVG support
- **uuid** - Unique ID generation

## How It Works

### Background Removal

The app uses a local color-based background removal algorithm:

1. **Edge Detection** - Samples colors from the image edges to identify the background
2. **Dominant Color** - Finds the most common color among edge samples
3. **Color Matching** - Compares each pixel to the dominant color using a tolerance threshold
4. **Edge Refinement** - Smooths edges by adjusting alpha values based on neighboring pixels

### Image Processing

After background removal, users can:
- Keep the transparent background
- Apply a solid color
- Add a gradient (vertical)
- Blur the original background

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All package authors for their contributions
