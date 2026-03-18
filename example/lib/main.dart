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
  String _selectedEquation = 'Triple Circle';
  Alignment _alignment = Alignment.center;

  // double _circle(double x, double y, double r) {
  //   return x * x + y * y - (r * r);
  // }

  double _heart(double x, double y) {
    double xx = x / 40;
    double yy = y / 40;
    return pow(xx * xx + yy * yy - 1, 3) - xx * xx * pow(yy, 3);
  }

  // double _sine(double x, double y) {
  //   return y - 50 * sin(x / 20);
  // }

  // double _butterfly(double x, double y) {
  //   double xx = x / 60;
  //   double yy = y / 60;
  //   return pow(xx * xx + yy * yy, 2) - 0.8 * (xx * xx - yy * yy);
  // }

  // List<EquationConfig> get _currentEquations {
  //   switch (_selectedEquation) {
  //     case 'Triple Circle':
  //       return [
  //         EquationConfig(
  //           function: (x, y) => _circle(x, y, 60),
  //           color: Colors.blueAccent,
  //           strokeWidth: 2,
  //         ),
  //         EquationConfig(
  //           function: (x, y) => _circle(x, y, 100),
  //           color: Colors.cyanAccent,
  //           strokeWidth: 3,
  //         ),
  //         EquationConfig(
  //           function: (x, y) => _circle(x, y, 140),
  //           color: Colors.tealAccent,
  //           strokeWidth: 4,
  //         ),
  //       ];
  //     case 'Heart & Sine':
  //       return [
  //         EquationConfig(
  //           function: _heart,
  //           color: Colors.pinkAccent,
  //           strokeWidth: 4,
  //           animationType: AnimationType.sequential,
  //         ),
  //         EquationConfig(
  //           function: _sine,
  //           color: Colors.yellowAccent,
  //           strokeWidth: 2,
  //           animationType: AnimationType.linearX,
  //         ),
  //       ];
  //     case 'Butterfly Garden':
  //       return [
  //         EquationConfig(
  //           function: (x, y) => _butterfly(x - 100, y - 100),
  //           color: Colors.purpleAccent,
  //         ),
  //         EquationConfig(
  //           function: (x, y) => _butterfly(x + 100, y + 100),
  //           color: Colors.orangeAccent,
  //         ),
  //         EquationConfig(
  //           function: (x, y) => _butterfly(x, y),
  //           color: Colors.white70,
  //           strokeWidth: 1,
  //         ),
  //       ];
  //     default:
  //       return [
  //         EquationConfig(
  //           function: (x, y) => _circle(x, y, 80),
  //           color: Colors.blue,
  //         ),
  //       ];
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equation Stack Demo'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(" y - 50 * sin(x / 50)", style: TextStyle(fontSize: 25)),
              SizedBox(height: 15),
              Card(
                elevation: 15,
                shadowColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                color: Colors.white.withAlpha(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: EquationPainterWidget(
                    equations: [
                      // EquationConfig(
                      //   maxX: 250,
                      //   maxY: 250,
                      //   minX: -250,
                      //   minY: -250,
                      //   function: (double a, double b) =>
                      //       tan(a / 10) + tan(b / 10) - sin(a / b) + cos(a / b),
                      //   animationType: AnimationType.linearX,
                      //   color: Colors.green,
                      //   strokeWidth: 2,
                      // ),
                      // EquationConfig(
                      //   maxX: 250,
                      //   maxY: 250,
                      //   minX: -250,
                      //   minY: -250,
                      //   function: (double a, double b) =>
                      //       tan(a / 10) - tan(b / 10) + sin(a / b) + cos(a / b),
                      //   animationType: AnimationType.linearX,
                      //   color: Colors.blue,
                      //   strokeWidth: 2,
                      // ),
                      EquationConfig(
                        // maxX: 40,
                        // maxY: 200,
                        // minY: -100,
                        // minX: -50,
                        strokeWidth: 5,
                        animationType: AnimationType.sequential,
                        function: (x, y) => y - 50 * sin(x / 15),
                      ),
                    ],
                    width: 700,
                    height: 700,
                    alignment: _alignment,
                    gridColor: Colors.white12,
                    animationDuration: const Duration(seconds: 2),
                  ),
                ),
              ),
              // const SizedBox(height: 40),
              // Wrap(
              //   spacing: 20,
              //   runSpacing: 20,
              //   alignment: WrapAlignment.center,
              //   children: [
              //     _buildControlPanel(
              //       title: 'Equations',
              //       child: DropdownButton<String>(
              //         value: _selectedEquation,
              //         items:
              //             [
              //               'Triple Circle',
              //               'Heart & Sine',
              //               'Butterfly Garden',
              //             ].map((String value) {
              //               return DropdownMenuItem<String>(
              //                 value: value,
              //                 child: Text(value),
              //               );
              //             }).toList(),
              //         onChanged: (value) =>
              //             setState(() => _selectedEquation = value!),
              //       ),
              //     ),
              //     _buildControlPanel(
              //       title: 'View',
              //       child: DropdownButton<Alignment>(
              //         value: _alignment,
              //         items: const [
              //           DropdownMenuItem(
              //             value: Alignment.center,
              //             child: Text('Center (All)'),
              //           ),
              //           DropdownMenuItem(
              //             value: Alignment.bottomLeft,
              //             child: Text('1st Quadrant'),
              //           ),
              //           DropdownMenuItem(
              //             value: Alignment.bottomRight,
              //             child: Text('2nd Quadrant'),
              //           ),
              //           DropdownMenuItem(
              //             value: Alignment.topRight,
              //             child: Text('3rd Quadrant'),
              //           ),
              //           DropdownMenuItem(
              //             value: Alignment.topLeft,
              //             child: Text('4th Quadrant'),
              //           ),
              //         ],
              //         onChanged: (value) => setState(() => _alignment = value!),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildControlPanel({required String title, required Widget child}) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withAlpha(15),
  //       borderRadius: BorderRadius.circular(25),
  //       border: Border.all(color: Colors.white10),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  //         const SizedBox(width: 15),
  //         DropdownButtonHideUnderline(child: child),
  //       ],
  //     ),
  //   );
  // }
}
