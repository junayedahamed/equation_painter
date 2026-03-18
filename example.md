# Example: Basic Visualization

### 🌐 Select Language / ভাষা নির্বাচন
**[English](#english) | [বাংলা](#bangla)**

---

<details open id="english">
<summary><b>🇬🇧 English Examples (Click to Expand)</b></summary>
<br>

This file provides a quick, standalone code example for the `eq_visulaization` package.

### Simple Equation (Sine Wave)

Use the following code to render a basic sine wave with a linear animation from left to right.

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:eq_visulaization/eq_visulaization.dart';

void main() => runApp(const MaterialApp(home: SimpleDemo()));

class SimpleDemo extends StatelessWidget {
  const SimpleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: EquationPainterWidget(
          width: 400,
          height: 400,
          alignment: Alignment.center,
          unitsPerSquare: 60.0,
          equations: [
            EquationConfig(
              function: (x, y) => y - 60 * sin(x / 30), // y = 60 * sin(x/30)
              color: Colors.cyanAccent,
              strokeWidth: 3,
              animationType: AnimationType.linearX,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Multiple Equations (Circle & Wave)

You can stack multiple equations by passing them to the `equations` list.

```dart
EquationPainterWidget(
  width: 400,
  height: 400,
  equations: [
    EquationConfig(
      function: (x, y) => x * x + y * y - pow(100, 2), // x^2 + y^2 = 100^2
      color: Colors.amberAccent,
      animationType: AnimationType.radial,
    ),
    EquationConfig(
      function: (x, y) => y - 50 * sin(x / 20),
      color: Colors.pinkAccent,
      animationType: AnimationType.linearX,
    ),
  ],
)
```

For more advanced examples, please check the [example/lib/main.dart](example/lib/main.dart) file.
</details>

<br>

<details id="bangla">
<summary><b>🇧🇩 টেক্সট উদাহরণ (বিস্তারিত দেখতে ক্লিক করুন)</b></summary>
<br>

এই ফাইলটি `eq_visulaization` প্যাকেজের জন্য একটি দ্রুত এবং স্ট্যান্ডঅ্যালোন কোড উদাহরণ প্রদান করে।

### সহজ সমীকরণ (Sine Wave)

বাম থেকে ডানে লিনিয়ার অ্যানিমেশন সহ একটি বেসিক সাইন ওয়েভ রেন্ডার করতে নিচের কোডটি ব্যবহার করুন।

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:eq_visulaization/eq_visulaization.dart';

void main() => runApp(const MaterialApp(home: SimpleDemo()));

class SimpleDemo extends StatelessWidget {
  const SimpleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: EquationPainterWidget(
          width: 400,
          height: 400,
          alignment: Alignment.center,
          unitsPerSquare: 60.0,
          equations: [
            EquationConfig(
              function: (x, y) => y - 60 * sin(x / 30), // y = 60 * sin(x/30)
              color: Colors.cyanAccent,
              strokeWidth: 3,
              animationType: AnimationType.linearX,
            ),
          ],
        ),
      ),
    );
  }
}
```

### একাধিক সমীকরণ (বৃত্ত এবং তরঙ্গ)

আপনি `equations` লিস্টে পাঠিয়ে একাধিক সমীকরণ একসাথে দেখাতে পারেন।

```dart
EquationPainterWidget(
  width: 400,
  height: 400,
  equations: [
    EquationConfig(
      function: (x, y) => x * x + y * y - pow(100, 2), // x² + y² = 100²
      color: Colors.amberAccent,
      animationType: AnimationType.radial,
    ),
    EquationConfig(
      function: (x, y) => y - 50 * sin(x / 20),
      color: Colors.pinkAccent,
      animationType: AnimationType.linearX,
    ),
  ],
)
```

আরও উন্নত উদাহরণের জন্য, অনুগ্রহ করে [example/lib/main.dart](example/lib/main.dart) ফাইলটি দেখুন।
</details>

