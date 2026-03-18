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
      title: 'Equation Visualizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primaryColor: const Color(0xFF6366F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      home: const EquationVisualizerPage(),
    );
  }
}

class EquationVisualizerPage extends StatefulWidget {
  const EquationVisualizerPage({super.key});

  @override
  State<EquationVisualizerPage> createState() => _EquationVisualizerPageState();
}

class _EquationVisualizerPageState extends State<EquationVisualizerPage> {
  final TextEditingController _equationController = TextEditingController(
    text: 'y - x^2',
  );

  // Current active equation config
  EquationConfig? _activeConfig;

  @override
  void initState() {
    super.initState();
    // Initialize with the default equation
    _updateGraph();
  }

  void _updateGraph() {
    setState(() {
      final equation = _equationController.text.trim();
      if (equation.isEmpty) return;

      _activeConfig = EquationConfig(
        function: EquationParser.parse(equation),
        color: const Color(0xFF6366F1),
        strokeWidth: 3.0,
        animationType: AnimationType.radial,
      );
    });
  }

  @override
  void dispose() {
    _equationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header & Logo
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Color(0xFF818CF8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Implicit Equation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Real-time Visualizer',
                          style: TextStyle(fontSize: 14, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Control Panel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Equation f(x, y) = 0",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _equationController,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. y - x^2',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.black.withAlpha(50),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.functions,
                            color: Color(0xFF818CF8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _updateGraph,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF6366F1).withAlpha(100),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Show Graph',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.play_arrow_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Graph Visualizer
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        color: const Color(0xFF0F172A),
                        child: _activeConfig == null
                            ? const Center(
                                child: Text(
                                  'Enter an equation and click "Show"',
                                ),
                              )
                            : RepaintBoundary(
                                child: EquationPainterWidget(
                                  key: ValueKey(
                                    _activeConfig!.function.hashCode ^
                                        _equationController.text.hashCode,
                                  ),
                                  unitsPerSquare: 5.0,
                                  alignment: Alignment.center,
                                  showNumbers: true,
                                  labelColor: Colors.white54,
                                  xAxisColor: Colors.white12,
                                  yAxisColor: Colors.white12,
                                  gridColor: Colors.white.withAlpha(10),
                                  equations: [_activeConfig!],
                                  animationDuration: const Duration(
                                    milliseconds: 1500,
                                  ),
                                  animate: true,
                                ),
                              ),
                      ),
                    ),
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
