import 'package:equation_painter/equation_painter.dart';
import 'package:flutter/material.dart';

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
  late double Function(double, double) function;

  @override
  void initState() {
    super.initState();
    function = (x, y) => 0;
  }

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _controllerMaxX = TextEditingController();
  final TextEditingController _controllerMinX = TextEditingController();
  final TextEditingController _controllerMaxY = TextEditingController();
  final TextEditingController _controllerMinY = TextEditingController();

  bool isInequality = false;
  InequalityType _inequalityType = InequalityType.none;
  double? maxX, minX, maxY, minY;

  void addLimitValues() {
    maxX = double.tryParse(_controllerMaxX.text);
    minX = double.tryParse(_controllerMinX.text);
    maxY = double.tryParse(_controllerMaxY.text);
    minY = double.tryParse(_controllerMinY.text);
    setState(() {});
  }

  void parseAndShow(String value) {
    final eq = EquationParser.parseOrNull(value);
    addLimitValues();
    if (eq != null) {
      function = eq;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Equation Visualizer'),
        actions: [
          Checkbox(
            value: isInequality,
            onChanged: (value) {
              setState(() {
                isInequality = !isInequality;
                if (!isInequality) {
                  _inequalityType = InequalityType.none;
                }
              });
            },
          ),

          isInequality
              ? DropdownButton(
                  value: _inequalityType,
                  items: InequalityType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _inequalityType = value!;
                    });
                  },
                )
              : SizedBox(),
        ],
      ),

      body: Column(
        children: [
          Column(
            children: [
              TextFormField(
                controller: _controller,
                onChanged: (value) {
                  parseAndShow(value);
                },
                decoration: const InputDecoration(
                  labelText: 'Enter equation (e.g. y = sin(x))',
                  border: OutlineInputBorder(),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllerMinX,
                      onChanged: (value) => addLimitValues(),
                      decoration: const InputDecoration(
                        hint: Text('minX'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => addLimitValues(),
                      controller: _controllerMaxX,
                      decoration: const InputDecoration(
                        hint: Text('maxX'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => addLimitValues(),
                      controller: _controllerMinY,
                      decoration: const InputDecoration(
                        hint: Text('minY'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => addLimitValues(),
                      controller: _controllerMaxY,

                      decoration: const InputDecoration(
                        hint: Text('maxY'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => parseAndShow(_controller.text),
            child: Text("Show"),
          ),

          Expanded(
            child: EquationPainter(
              equations: [
                EquationConfig(
                  maxX: maxX,
                  minX: minX,
                  maxY: maxY,
                  minY: minY,
                  inequality: _inequalityType,
                  function: function,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
