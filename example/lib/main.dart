import 'dart:math';
import 'package:flutter/material.dart';
import 'package:eq_visulaization/eq_visulaization.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equation Visualization Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const EquationDemoPage(),
    );
  }
}

class EquationDemoPage extends StatefulWidget {
  const EquationDemoPage({super.key});

  @override
  State<EquationDemoPage> createState() => _EquationDemoPageState();
}

class _EquationDemoPageState extends State<EquationDemoPage> {
  String _selectedEquation = 'Circle';

  double _circle(double x, double y) {
    // x^2 + y^2 - r^2 = 0
    return x * x + y * y - (80 * 80);
  }

  double _heart(double x, double y) {
    // (x^2 + y^2 - 1)^3 - x^2 * y^3 = 0
    // Scaled for visualization
    double xx = x / 40;
    double yy = y / 40;
    return pow(xx * xx + yy * yy - 1, 3) - xx * xx * pow(yy, 3);
  }

  double _sine(double x, double y) {
    // y - sin(x) = 0
    return y - 50 * sin(x / 20);
  }

  double _cross(double x, double y) {
    return (x * x - 2500) * (y * y - 2500);
  }

  MathFunction get _currentFunction {
    switch (_selectedEquation) {
      case 'Circle':
        return _circle;
      case 'Heart':
        return _heart;
      case 'Sine Wave':
        return _sine;
      case 'Cross':
        return _cross;
      default:
        return _circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equation Visualization'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white.withAlpha(13), // 0.05 * 255
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: EquationPainterWidget(
                    function: _currentFunction,
                    width: 400,
                    height: 400,
                    graphLineColor: Colors.cyanAccent,
                    graphLineStrokeWidth: 3.0,
                    gridColor: Colors.white10,
                    showGrid: true,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26), // 0.1 * 255
                  borderRadius: BorderRadius.circular(30),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedEquation,
                    items: ['Circle', 'Heart', 'Sine Wave', 'Cross'].map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEquation = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Explore mathematical curves using Marching Squares',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
