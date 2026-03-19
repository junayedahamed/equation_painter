# 📈 eq_visualization Example
Open Sourced by GitHub user **junayedahamed**

A powerful example demonstrating how to use the `eq_visulaization` package for visualizing multiple mathematical equations interactively.

---

### Language Switch / ভাষা পরিবর্তন
**[English](#english) | [বাংলা](#bangla)**

---

<details open id="english">
<summary><b>🇬🇧 English Documentation (Click to Expand/Collapse)</b></summary>

<br>

<div align="center">
  <img src="https://raw.githubusercontent.com/junayedahamed/eq_visualization/main/assets/preview.png" alt="Preview" width="700">
</div>

### ✨ Features Shown
- ✅ **Interactive Panning**: Drag to pan around the graph.
- ✅ **Live Equation Parsing**: Type equations and see them instantly rendered (e.g., `x^2 + y^2 - 100`).
- ✅ **Dynamic Coordinates**: Axis numbers and grids that scale dynamically.
- ✅ **High Performance**: Smooth 60fps rendering even during active pan/zoom gestures.

### 🚀 Running the Example

1. Navigate to the `example` directory:
   ```bash
   cd example
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

### 💡 Example Code Extract

```dart
EquationPainterWidget(
  width: double.infinity,
  height: double.infinity,
  interactive: true,
  unitsPerSquare: 50.0,
  alignment: Alignment.center,
  equations: [
    EquationConfig(
      function: EquationParser.parse('sin(x) - y'),
      color: Colors.cyanAccent,
      strokeWidth: 3,
      animationType: AnimationType.radial,
    ),
  ],
)
```

</details>


<details id="bangla">
<summary><b>🇧🇩 বাংলা উদাহরণ (বিস্তারিত দেখতে ক্লিক করুন)</b></summary>

<br>

### এখানে যা দেখানো হয়েছে
- ✅ **ইন্টারেক্টিভ প্যানিং**: গ্রাফে ড্র্যাগ করে চারপাশে প্যান করুন।
- ✅ **লাইভ ইকুয়েশন পার্সিং**: সমীকরণ টাইপ করুন এবং সাথে সাথে রেন্ডার হতে দেখুন (যেমন: `x^2 + y^2 - 100`)।
- ✅ **ডায়নামিক স্থানাঙ্ক**: অক্ষের সংখ্যাগুলি জুম করার সাথে সাথে পরিবর্তন হয়।
- ✅ **উচ্চ পারফরম্যান্স**: প্যান/জুম করার সময়ও স্মুথ ফ্রেম রেট বজায় থাকে।

### 🚀 রান করার নিয়ম

১. `example` ডিরেক্টরিতে যান:
   ```bash
   cd example
   ```
২. ডিপেন্ডেন্সি নিয়ে আসুন:
   ```bash
   flutter pub get
   ```
৩. অ্যাপটি রান করুন:
   ```bash
   flutter run
   ```

</details>
