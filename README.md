<a href="https://github.com/junayedahamed/equation_painter" target="_blank">
<div align="center">
  <img align="center" src="assets/logo/logo_eq_painter.png" alt="logo" width="400" 
  height="250",
  style="mix-blend-mode: screen;
 ">
</div></a>

# 📈 equation_painter
Open Sourced by GitHub user **[junayedahamed](https://github.com/junayedahamed)**

A powerful, interactive, and performant Flutter package for visualizing multiple mathematical equations simultaneously with beautiful animations and a fully customizable coordinate system.

---

### Language Switch / ভাষা পরিবর্তন
**[English](#english) | [বাংলা](#bangla)**

---

<details open id="english">
<summary><b>🇬🇧 English Documentation (Click to Expand/Collapse)</b></summary>

<br>

<div align="center">
  <img src="https://raw.githubusercontent.com/junayedahamed/equation_painter/main/assets/preview.png" alt="Preview" width="700">
</div>

### ✨ Features
- ✅ **New: Interactive Panning & Zooming**: Drag to pan and pinch to zoom around the coordinate system!
- ✅ **New: Polar Coordinate Support**: Visualize equations in polar form `r = f(theta)`.
- ✅ **New: Inequality Visualization**: Shading for regions like `y >= x` or `x^2 + y^2 <= 25`.
- ✅ **New: Tap & Hover to Inspect**: Tap or hover on any curve to see the exact (x, y) or (r, theta) coordinates.
- ✅ **Robust Equation Parsing**: Type equations like `x^2 + y^2 - 100`, `sin(2x) - y`, `pow(x,2) * atan2(y,x)` directly. It supports implicit multiplication (`2x`), constants (`pi`, `e`), unit +/- and ~20 built-in math functions.
- ✅ **Coordinate Labels**: Show dynamic numbers along the axis to measure your functions.
- ✅ **Configurable Units**: Define how many units each grid square represents.
- ✅ **Dynamic Animations**: Beautiful `radial`, `sequential`, `linearX`, or `linearY` draw mechanics.
- ✅ **High Performance**: Highly optimized utilizing `Float32List`, `drawRawPoints` and Marching Squares evaluation to preserve silky smooth 60fps framerates.

### 📸 Screenshots
<div style="display: flex; flex-wrap: wrap;">
  <img src="https://raw.githubusercontent.com/junayedahamed/equation_painter/main/assets/screenshots/Screenshot%20from%202026-03-19%2001-31-47.png" height="200">
  <img src="https://raw.githubusercontent.com/junayedahamed/equation_painter/main/assets/screenshots/Screenshot%20from%202026-03-19%2002-10-56.png" height="200">
  <img src="https://raw.githubusercontent.com/junayedahamed/equation_painter/main/assets/screenshots/Screenshot%20from%202026-03-19%2002-11-27.png" height="200">
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
- **Polar Coordinates**: Use `EquationType.polar` in `EquationConfig`.
- **Inequalities**: Set `inequality: InequalityType.greaterThanOrEqual` for region shading.
- **Hover Inspection**: Move your mouse over a curve to automatically see values.
- **Tap Support**: Implement `onPointTapped` to handle clicks on specific coordinates.

### 🔭 Licensing
This project is licensed under the MIT License.

<br>

### বৈশিষ্ট্যসমূহ
- ✅ **নতুন: ইন্টারেক্টিভ প্যানিং**: আপনি এখন গ্রাফে ড্র্যাগ করে চারপাশে প্যান করতে পারেন!
- ✅ **শক্তিশালী ইকুয়েশন পার্সার**: আপনি এখন সরাসরি `x^2 + y^2 - 100`, `sin(2x) - y` এর মতো সমীকরণ টাইপ করতে পারেন। এটি ಇমপ্লিসিট গুণ (`2x`), ধ্রুবক (`pi`, `e`), এবং ২০টিরও বেশি বিল্ট-ইন গাণিতিক ফাংশন সাপোর্ট করে।
- ✅ **স্থানাঙ্ক লেবেল**: ফাংশন পরিমাপ করার জন্য ডাইনামিক অক্ষে সংখ্যা প্রদর্শন।
- ✅ **ডায়নামিক অ্যানিমেশন**: `radial`, `sequential`, `linearX`, অথবা `linearY` অ্যানিমেশন স্টাইল।
- ✅ **উচ্চ পারফরম্যান্স**: মসৃণ ফ্রেম রেটের জন্য `Float32List` এবং `drawRawPoints` ব্যবহার করে অপ্টিমাইজ করা হয়েছে।

### 🚀 শুরু করা যাক

আপনার `pubspec.yaml`-এ প্যাকেজটি যোগ করুন:

```yaml
dependencies:
  equation_painter: ^0.0.1+2
```

### 💡 ব্যবহার পদ্ধতি

```dart
import 'package:equation_painter/equation_painter.dart';

// ... আপনার উইজেট ট্রির ভেতরে
EquationPainterWidget(
  width: double.infinity,
  height: 400,
  interactive: true, // ইন্টারেক্টিভ প্যানিং চালু
  unitsPerSquare: 50.0,
  alignment: Alignment.center,
  equations: [
    EquationConfig(
      function: EquationParser.parse('x^2 + y^2 - 2500'),
      color: Colors.cyanAccent,
      strokeWidth: 3,
      animationType: AnimationType.radial,
    ),
  ],
)
```

### 🔭 ভবিষ্যতের আপগ্রেড আইডিয়া
- পোলার স্থানাঙ্ক ব্যবস্থার (Polar Coordinate) সমর্থন।
- ইনইকুয়ালিটি শেডিং-এর সমর্থন (যেমন, `y >= x` এর রেন্ডারিং)।
- রেখায় ট্যাপ করে সঠিক স্থানাঙ্ক (X/Y) বের করার ব্যবস্থা।

</details>

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing
Contributions are welcome! Feel free to open issues or submit pull requests.

---
**Crafted with ❤️ for Mathematicians and Developers.**
