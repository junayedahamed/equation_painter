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

class EquationExample {
  final String name;
  final String formula;
  final MathFunction function;
  final Color color;
  final AnimationType animationType;
  final double unitsPerSquare;

  EquationExample({
    required this.name,
    required this.formula,
    required this.function,
    required this.color,
    this.animationType = AnimationType.radial,
    this.unitsPerSquare = 50.0,
  });
}

class EquationDemoPage extends StatefulWidget {
  const EquationDemoPage({super.key});

  @override
  State<EquationDemoPage> createState() => _EquationDemoPageState();
}

class _EquationDemoPageState extends State<EquationDemoPage> {
  Alignment _alignment = Alignment.center;
  late List<EquationExample> _examples;
  late EquationExample _selectedExample;

  @override
  void initState() {
    super.initState();
    _examples = [
      EquationExample(
        name: 'Classical Sine Wave',
        formula: 'y - 60 * sin(x / 30) = 0',
        function: (x, y) => y - 60 * sin(x / 30),
        color: Colors.cyanAccent,
        animationType: AnimationType.linearX,
        unitsPerSquare: 60,
      ),
      EquationExample(
        name: 'Perfect Circle',
        formula: 'x² + y² - 100² = 0',
        function: (x, y) => x * x + y * y - 100 * 100,
        color: Colors.amberAccent,
        animationType: AnimationType.radial,
        unitsPerSquare: 50,
      ),
      EquationExample(
        name: 'Mathematical Heart',
        formula: '(x²+y²-1)³ - x²y³ = 0',
        function: (x, y) {
          final nx = x / 80;
          final ny = y / 80;
          return pow(nx * nx + ny * ny - 1, 3) - (nx * nx * ny * ny * ny);
        },
        color: Colors.redAccent,
        animationType: AnimationType.sequential,
        unitsPerSquare: 40,
      ),
      EquationExample(
        name: 'Folium of Descartes',
        formula: 'x³ + y³ - 3axy = 0',
        function: (x, y) {
          const a = 100.0;
          return x * x * x + y * y * y - 3 * a * x * y;
        },
        color: Colors.lightGreenAccent,
        animationType: AnimationType.sequential,
        unitsPerSquare: 80,
      ),
      EquationExample(
        name: 'Complex Interference',
        formula: 'tan(20x) - tan(15y) + sin(xy) + cos(y/x) + ...',
        function: (x, y) =>
            tan(20 * x) -
            tan(15 * y) +
            sin(x * y) +
            cos(y / x) +
            log(1 + x * x + y * y) +
            (x * x * x - y * y * y) / (x * x + y * y) -
            10,
        color: Colors.pinkAccent,
        animationType: AnimationType.linearX,
        unitsPerSquare: 50,
      ),
    ];
    _selectedExample = _examples[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equation Painter'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          PopupMenuButton<Alignment>(
            tooltip: 'Change Origin Alignment',
            icon: const Icon(Icons.grid_view_rounded),
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
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Selection Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EquationExample>(
                      value: _selectedExample,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF203A43),
                      borderRadius: BorderRadius.circular(16),
                      items: _examples
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedExample = val);
                        }
                      },
                    ),
                  ),
                ),
              ),

              // Formula Display
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _selectedExample.formula,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _selectedExample.color.withAlpha(204),
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(127),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // The Visualization Widget
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(76),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: EquationPainterWidget(
                        key: ValueKey('${_selectedExample.name}_$_alignment'),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width,
                        alignment: _alignment,
                        showNumbers: true,
                        labelColor: Colors.white,
                        unitsPerSquare: _selectedExample.unitsPerSquare,
                        animationDuration: const Duration(milliseconds: 2000),
                        equations: [
                          EquationConfig(
                            function: _selectedExample.function,
                            color: _selectedExample.color,
                            strokeWidth: 3.0,
                            animationType: _selectedExample.animationType,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 24, left: 40, right: 40),
                child: Text(
                  "Interactive implicit equation rendering in real-time.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
