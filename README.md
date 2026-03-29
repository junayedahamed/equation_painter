<div align="center">
  <a href="https://github.com/junayedahamed/equation_painter" target="_blank">
    <img src="assets/logo/logo_eq_painter.png" alt="logo" width="100%" 
   height="200"
   style="mix-blend-mode: screen;">
  </a>
</div>

# 📈 equation_painter
Open Source Flutter Package by **[junayedahamed](https://github.com/junayedahamed)**

A powerful, interactive, and performant Flutter package for visualizing multiple mathematical equations simultaneously with beautiful animations and a fully customizable coordinate system.

---

<div align="center">
  <img src="assets/preview.png" alt="Preview" width="700">
</div>

### ✨ Features
- ✅ **New: Interactive Panning & Zooming**: Drag to pan and pinch to zoom around the coordinate system!
- ✅ **New: Polar Coordinate Support**: Visualize equations in polar form `r = f(theta)`.
- ✅ **New: Inequality Visualization**: Shading for regions like `y >= x` or `x^2 + y^2 <= 25`.
- ✅ **New: Tap & Hover to Inspect**: Tap or hover on any curve to see the exact (x, y) or (r, theta) coordinates.
- ✅ **Robust Equation Parsing**: Type equations like `x^2 + y^2 - 100`, `sin(2x) - y`, `pow(x,2) * atan2(y,x)` directly. It supports implicit multiplication (`2x`), constants (`pi`, `e`), unit +/- and ~20 built-in math functions.
- ✅ **Coordinate Labels**: Show dynamic numbers along the axis to measure your functions.
- ✅ **Customizable Unit Scale**: By default, each grid square represents 100 units, but you can adjust this to your specific needs.
- ✅ **Configurable Units**: Define how many units each grid square represents.
- ✅ **Dynamic Animations**: Beautiful `radial`, `sequential`, `linearX`, or `linearY` draw mechanics.
- ✅ **High Performance**: Highly optimized utilizing `Float32List`, `drawRawPoints` and Marching Squares evaluation to preserve silky smooth 60fps framerates.

### 📸 Screenshots


<div style="display: flex; flex-wrap: wrap; gap: 20px; justify-content: start;">

  ## Multiple Curves with Custom Styles and Complex Functions

  <img src="assets/screenshots/Screenshot%20from%202026-03-19%2001-31-47.png" height="200">


  ## Sin wave with radial animation
  <img src="assets/screenshots/Screenshot%20from%202026-03-19%2002-10-56.png" height="200">

 ### Heart curve

  <img src="assets/screenshots/Screenshot%20from%202026-03-19%2002-11-19.png" height="200">

  ### Cos wave with value inspection

  <img src="assets/screenshots/Screenshot%202026-03-30%20001953.png" height="200">

  ### Inequality Visualization 

  <img src="assets/screenshots/Screenshot%202026-03-27%20124744.png" height="200">
</div>

### 🚀 Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  equation_painter: ^0.0.1+2
```

### 💡 Usage

```dart
EquationPainter(
  equations: [
    EquationConfig(
      function: (x, y) => x * x + y * y - 25,
      color: Colors.indigoAccent,
      strokeWidth: 4,
    ),
  ],
  unitsPerSquare: 10,
  interactive: true,
  showGrid: true,
  onPointTapped: (x, y, config) {
    print("Tapped at ($x, $y)");
  },
)
```

### 🧮 Enhanced Equation Parsing

You can parse string-based equations directly using `EquationParser`. It's highly tolerant!

#### Supported Syntax
- **Variables**: `x`, `y`
- **Constants**: `pi` (pi), `e` (e)
- **Operators**: `+`, `-`, `*`, `/`, `^` (power)
- **Implicit Multiplication**: `2x`, `3(x+y)`, `x(y-1)`
- **Functions**:
  - **Trigonometric**: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2(y, x)`
  - **Logarithmic & Exponential**: `log`/`ln` (natural), `log2`, `log10`, `exp`
  - **Rounding & Absolute**: `abs`, `ceil`, `floor`, `round`, `sign`
  - **Miscellaneous**: `sqrt`, `cbrt` (cube root), `hypot(a, b)`, `pow(base, exp)`, `min(a, b)`, `max(a, b)`

```dart
final userEquation = "tan(20x) - tan(15y) + sin(xy) - 10";
final mathFunction = EquationParser.parseOrNull(userEquation); // Returns null if invalid 

if (mathFunction != null) {
  EquationConfig(
    function: mathFunction,
    color: Colors.pinkAccent,
  )
}
```

### ❄️ Advanced Features
- **Customizable Grid Styles**: Support for logarithmic scales, dashed lines, and custom colors.
- **Export to Image/SVG**: Easily save your visualized equations as high-quality images or SVGs.

### 🔭 Future Upgrade Ideas
- 🚀 **3D Equation Visualization**: Support for plotting z = f(x, y) in a 3D coordinate system.
- 🚀 **Parametric Equation Support**: Plot curves defined by equations like x = f(t), y = g(t).
- 🚀 **Live Equation Editor**: A built-in UI component to type and preview equations in real-time.
- 🚀 **Data Series Plotting**: Ability to plot discrete data points (scatter plots) alongside continuous equations.
- 🚀 **Legend & Tooltips**: Add customizable legends and more detailed information tooltips for complex graphs.

### ⭐ Support the Project
If you like this project, please give it a ⭐ on GitHub and share it with your friends! It really helps me out and motivates me to keep improving it. Thank you for your support! 🙏

### 📄 License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/junayedahamed/equation_painter?tab=MIT-1-ov-file) file for details.

### 🤝 Contributing
Contributions are welcome! Feel free to open issues or submit pull requests.

---
**Crafted with ❤️ for Mathematicians and Developers.**
