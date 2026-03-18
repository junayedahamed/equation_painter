# Installing eq_visulaization

### 🌐 Select Language / ভাষা নির্বাচন
**[English](#english) | [বাংলা](#bangla)**

---

<details open id="english">
<summary><b>🇬🇧 English Installation (Click to Expand)</b></summary>
<br>

You can add the `eq_visulaization` package to your Flutter project using several methods.

### Method 1: Using the Flutter CLI (Recommended)

Run the following command in your terminal while in the root folder of your project:

```bash
flutter pub add eq_visulaization
```

### Method 2: Manually via `pubspec.yaml`

1. Open your project's `pubspec.yaml` file.
2. Add `eq_visulaization` under the `dependencies` section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  eq_visulaization: ^0.0.1+1 # Current version
```

3. Save the file and run:
```bash
flutter pub get
```

### Method 3: Using a Local Path (For Development)

If you have downloaded the source code and want to use it as a local package:

```yaml
dependencies:
  eq_visulaization:
    path: /path/to/eq_visulaization # Replace with your actual path
```

### Importing the Package

Once installed, you can import and use the package in your Dart code:

```dart
import 'package:eq_visulaization/eq_visulaization.dart';
```
</details>

<br>

<details id="bangla">
<summary><b>🇧🇩 ইন্সটল করার নিয়ম (বিস্তারিত দেখতে ক্লিক করুন)</b></summary>
<br>

আপনি নিচের সহজ ধাপগুলো অনুসরণ করে আপনার ফ্লাটার প্রজেক্টে `eq_visulaization` প্যাকেজটি যোগ করতে পারেন।

### ১. ফ্লাটার CLI ব্যবহার করে (সবচেয়ে সহজ):

আপনার প্রজেক্টের রুট ডিরেক্টরিতে নিচের কমান্ডটি রান করুন:
```bash
flutter pub add eq_visulaization
```

### ২. `pubspec.yaml` এর মাধ্যমে:

১. আপনার প্রজেক্টের `pubspec.yaml` ফাইলটি খুলুন।
২. `dependencies` সেকশনে `eq_visulaization: ^0.0.1+1` যোগ করুন।
৩. এরপর ফাইলটি সেভ করে `flutter pub get` কমান্ডটি রান করুন অথবা আপনার IDE-র টুল ব্যবহার করুন।

### ৩. প্যাকেজটি ডার্ট ফাইলে ইম্পোর্ট করা:

ইন্সটল হওয়ার পর নিচের লাইনটি দিয়ে আপনার কোডে প্যাকেজটি ব্যবহার করতে পারেন:
```dart
import 'package:eq_visulaization/eq_visulaization.dart';
```
</details>

