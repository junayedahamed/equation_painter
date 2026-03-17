# eq_visulaization

A Flutter package for visualizing mathematical equations on a coordinate system using a Marching Squares inspired approach.

## Features

- Visualize any mathematical function of the form `f(x, y) = 0`.
- Customizable coordinate system with grid and axes.
- Support for custom colors and stroke widths.
- Smooth drawing with anti-aliasing.

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  eq_visulaization:
    git: https://github.com/yourusername/eq_visulaization.git
```

## Usage

```dart
import 'package:eq_visulaization/eq_visulaization.dart';

// Define your function
double circle(double x, double y) {
  return x * x + y * y - (100 * 100); // x^2 + y^2 = 100^2
}

// Use the widget
EquationPainterWidget(
  function: circle,
  width: 300,
  height: 300,
  graphLineColor: Colors.blue,
  showGrid: true,
)
```

## Example

Check the `example` folder for a comprehensive demo showcasing different mathematical curves.

## Additional information

This package uses a grid-based approach (Marching Squares) to approximate the curves from the given mathematical function. You can adjust the `steps` constant in the source code if you need higher or lower precision.
