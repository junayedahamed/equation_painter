# Equation Visualization Example

### 🌐 Select Language / ভাষা নির্বাচন
**[English](#english) | [বাংলা](#bangla)**

---

<details open id="english">
<summary><b>🇬🇧 English Details (Click to Expand)</b></summary>
<br>

This example demonstrates how to use the `eq_visulaization` package to render various mathematical equations, including trigonometric functions, circles, and complex implicit equations like hearts and foliums.

### Features Shown
- **Dynamic Equation Switching**: Easily swap between different mathematical functions.
- **Customizable Alignment**: Change the origin (0,0) position in real-time.
- **Animation Styles**: See `radial`, `sequential`, and `linearX` animations in action.
- **Coordinate System**: Visual representation of axes and grid with numeric labels.

### Code Snippet

```dart
import 'package:eq_visulaization/eq_visulaization.dart';

// Inside your widget tree:
EquationPainterWidget(
  width: 400,
  height: 400,
  alignment: Alignment.center,
  unitsPerSquare: 50.0,
  equations: [
    EquationConfig(
      function: (x, y) => x * x + y * y - pow(100, 2), // Circle equation
      color: Colors.cyanAccent,
      strokeWidth: 3,
      animationType: AnimationType.radial,
    ),
  ],
)
```

### Running the Example

1. Navigate to the `example` directory:
   ```bash
   cd example
   ```
2. Ensure dependencies are fetched:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```
</details>

<br>

<details id="bangla">
<summary><b>🇧🇩 বাংলা উদাহরণ (বিস্তারিত দেখতে ক্লিক করুন)</b></summary>
<br>

এই উদাহরণটি দেখায় কিভাবে `eq_visulaization` প্যাকেজ ব্যবহার করে বিভিন্ন গাণিতিক সমীকরণ যেমন ত্রিকোণমিতিক ফাংশন, বৃত্ত এবং জটিল ইমপ্লিসিট ইকুয়েশন (যেমন হার্ট এবং ফোলিয়াম) রেন্ডার করা যায়।

### এখানে যা দেখানো হয়েছে:
- **ডায়নামিক সমীকরণ পরিবর্তন**: সহজেই বিভিন্ন ফাংশনের মধ্যে পরিবর্তন করুন।
- **কাস্টমাইজেবল অরিজিন**: অরিজিনের (০,০) অবস্থান রিয়েল-টাইমে পরিবর্তন করে দেখুন।
- **অ্যানিমেশন স্টাইলসমূহ**: `radial`, `sequential`, এবং `linearX` অ্যানিমেশনগুলোর কার্যকারিতা দেখুন।
- **স্থানাঙ্ক ব্যবস্থা (Coordinate System)**: সংখ্যাসহ অক্ষ এবং গ্রিডের দৃশ্যমান রিপ্রেজেন্টেশন।

### রান করার নিয়ম:
১. `example` ডিরেক্টরিতে যান: `cd example`
২. ডিপেন্ডেন্সি নিয়ে আসুন: `flutter pub get`
৩. অ্যাপটি রান করুন: `flutter run`
</details>

