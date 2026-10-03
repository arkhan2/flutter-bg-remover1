# Background Remover

A Flutter web utility for removing flat image backgrounds on-device and replacing them with transparency, a solid color, a gradient, or blur.

Photos stay on this device. The in-app gallery lasts for the current session only.

## Features

- **On-device background removal** - Color-based local removal (best on solid studio backgrounds)
- **Solid Color Backgrounds** - Replace backgrounds with any solid color
- **Gradient Backgrounds** - Vertical gradient backgrounds with customizable colors
- **Blur Effect** - Apply blur to the original background
- **Undo/Redo** - Edit history for the current image (capped)
- **Session Gallery** - Save and reopen edits until you close the app
- **Export & Share** - Download or share PNG (transparency) or JPEG

## Getting Started

### Prerequisites

- Flutter SDK 3.38.0 or higher
- Dart SDK 3.0.0 or higher

### Installation

```bash
git clone https://github.com/arkhan2/flutter-bg-remover1.git
cd flutter-bg-remover1
flutter pub get
flutter run -d chrome
```

### Building for Web

```bash
flutter build web --release
```

## How It Works

The app uses a local color-based background removal algorithm:

1. Samples colors from the image edges
2. Finds the dominant edge color
3. Makes matching pixels transparent
4. Softens the cutout edge slightly

This is not a machine-learning subject segmenter. Complex scenes, hair, and busy backgrounds will not cut out cleanly.

## License

This project is licensed under the MIT License.
