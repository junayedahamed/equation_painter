import 'package:flutter_test/flutter_test.dart';
import 'package:eq_visulaization/eq_visulaization.dart';

void main() {
  test('EquationPainterWidget can be instantiated', () {
    final widget = EquationPainterWidget(function: (x, y) => x + y);
    expect(widget.function, isNotNull);
  });
}
