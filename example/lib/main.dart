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
  final TextEditingController _equationController = TextEditingController();

  // FIX BUG-14: _activeConfig starts null — graph shows "enter equation" hint initially
  EquationConfig? _activeConfig;

  // Track last successfully parsed equation string to avoid redundant rebuilds
  String _lastParsedEquation = '';

  @override
  void dispose() {
    _equationController.dispose();
    super.dispose();
  }

  void _updateGraph() {
    final equation = _equationController.text.trim();

    // FIX BUG-14: Clear graph when the field is empty
    if (equation.isEmpty) {
      setState(() {
        _activeConfig = null;
        _lastParsedEquation = '';
      });
      return;
    }

    // Skip redundant re-parses for the same equation text
    if (equation == _lastParsedEquation) return;

    // FIX BUG-13: Use parseOrNull to detect parse failures and show feedback
    final fn = EquationParser.parseOrNull(equation);
    if (fn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid equation: "$equation"\nCheck syntax (e.g. x^2 + y^2 - 100)',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _lastParsedEquation = equation;
      _activeConfig = EquationConfig(
        function: fn,
        color: const Color(0xFF6366F1),
        strokeWidth: 3.0,
        animationType: AnimationType.radial,
      );
    });
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
              // Header
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
                          ),
                        ),
                        Text(
                          'Visualizer',
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
                        'Equation  f(x, y) = 0',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Example hint
                      const Text(
                        'e.g.  x^2 + y^2 - 2500  •  sin(x) - y  •  2x + y - 10',
                        style: TextStyle(fontSize: 10, color: Colors.white24),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _equationController,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter equation, e.g.  x^2 + y^2 - 2500',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.black.withAlpha(50),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          // Clear button
                          suffixIcon: _equationController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white38),
                                  onPressed: () {
                                    _equationController.clear();
                                    _updateGraph();
                                  },
                                )
                              : null,
                        ),
                        // FIX: also rebuild suffix icon on text change
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _updateGraph(),
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
                        ),
                        child: const Text(
                          'Show Graph',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Graph
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
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.functions_rounded,
                                      size: 48,
                                      color: Colors.white10,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Enter an equation above and tap "Show Graph"',
                                      style: TextStyle(color: Colors.white24),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            // FIX BUG-12: Use 0 (fills constraints) instead of MediaQuery
                            // so the LayoutBuilder inside EquationPainterWidget correctly
                            // receives the available space from Expanded.
                            : EquationPainterWidget(
                                width: 0, // 0 → fills LayoutBuilder constraint
                                height: 0, // 0 → fills LayoutBuilder constraint
                                unitsPerSquare: 50.0,
                                alignment: Alignment.center,
                                showNumbers: true,
                                // FIX BUG-11: Use a visible color on dark background
                                labelColor: Colors.white38,
                                xAxisColor: Colors.white24,
                                yAxisColor: Colors.white24,
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
            ],
          ),
        ),
      ),
    );
  }
}
