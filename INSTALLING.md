# Installing equation_painter

You can add the `equation_painter` package to your Flutter project using several methods.

### Method 1: Using the Flutter CLI (Recommended)

Run the following command in your terminal while in the root folder of your project:

```bash
flutter pub add equation_painter
```

### Method 2: Manually via `pubspec.yaml`

1. Open your project's `pubspec.yaml` file.
2. Add `equation_painter` under the `dependencies` section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  equation_painter: ^0.1.0+7 # Current version
```

3. Save the file and run:
```bash
flutter pub get
```

### Method 3: Using a Local Path (For Development)

If you have downloaded the source code and want to use it as a local package:

```yaml
dependencies:
  equation_painter:
    path: /path/to/equation_painter # Replace with your actual path
```

### Importing the Package

Once installed, you can import and use the package in your Dart code:

```dart
import 'package:equation_painter/equation_painter.dart';
```


