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
      debugShowCheckedModeBanner: false,
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
  Alignment _alignment = Alignment.center;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equation Visualization'),
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<Alignment>(
            icon: const Icon(Icons.grid_view),
            onSelected: (val) => setState(() => _alignment = val),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Alignment.center,
                child: Text('Center (All Quadrants)'),
              ),
              const PopupMenuItem(
                value: Alignment.bottomLeft,
                child: Text('1st Quadrant (Bottom Left)'),
              ),
              const PopupMenuItem(
                value: Alignment.bottomRight,
                child: Text('2nd Quadrant (Bottom Right)'),
              ),
              const PopupMenuItem(
                value: Alignment.topRight,
                child: Text('3rd Quadrant (Top Right)'),
              ),
              const PopupMenuItem(
                value: Alignment.topLeft,
                child: Text('4th Quadrant (Top Left)'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    '''tan(20 * x) - tan(15 * y) + sin(x * y) + cos(y / x) + log(1 + x^2 + y^2) + (x^3 - y^3) / (x^2 + y^2) - 10''',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(127),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: EquationPainterWidget(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      alignment: _alignment,
                      showNumbers: true,
                      unitsPerSquare: 50.0,
                      animationDuration: const Duration(milliseconds: 2500),
                      equations: [
                        // A complex interference pattern
                        EquationConfig(
                          function: (x, y) => cos(x * y) - sin(x * x - y * y),
                          color: Colors.greenAccent.withAlpha(153),
                          strokeWidth: 1.5,
                          animationType: AnimationType.linearX,
                        ),
                        // A mirrored interference pattern
                        // EquationConfig(
                        //   function: (x, y) =>
                        //       tan(x / 20) -
                        //       tan(y / 20) +
                        //       tan(x / y) +
                        //       sin(y) * tan(y / x),
                        //   color: Colors.blueAccent.withAlpha(153),
                        //   strokeWidth: 1.5,
                        //   animationType: AnimationType.linearX,
                        // ),
                        // A prominent sine wave
                        // EquationConfig(
                        //   function: (x, y) => y - 60 * sin(x / 60),
                        //   color: Colors.pinkAccent,
                        //   strokeWidth: 3.5,
                        //   animationType: AnimationType.sequential,
                        // ),
                        // // A circle
                        // EquationConfig(
                        //   maxX: 500,
                        //   maxY: 300,
                        //   minX: -500,
                        //   minY: -300,
                        //   function: (x, y) =>
                        //       sin(x * x + y * y) + cos(3 * x) * sin(3 * y),
                        //   color: Colors.yellowAccent,
                        //   strokeWidth: 2.0,
                        //   animationType: AnimationType.radial,
                        // ),
                        // a arrow dynamic things
                        EquationConfig(
                          function: (x, y) =>
                              tan(20 * x) -
                              tan(15 * y) +
                              sin(x * y) +
                              cos(y / x) +
                              log(1 + x * x + y * y) +
                              (x * x * x - y * y * y) / (x * x + y * y) -
                              10,
                          color: Colors.red,
                          strokeWidth: 2.0,
                          animationType: AnimationType.linearX,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Text(
                    "Try changing the origin alignment using the top-right menu!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(138),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
