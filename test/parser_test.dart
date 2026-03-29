import 'package:flutter_test/flutter_test.dart';
import 'package:equation_painter/equation_painter.dart';

void main() {
  group('EquationParser Tests', () {
    test('Basic addition', () {
      final fn = EquationParser.parseOrNull('x + 1');
      expect(fn, isNotNull);
      expect(fn!(1, 0), equals(2));
    });

    test('Basic multiplication', () {
      final fn = EquationParser.parseOrNull('2 * x');
      expect(fn, isNotNull);
      expect(fn!(5, 0), equals(10));
    });

    test('Implicit multiplication', () {
      final fn = EquationParser.parseOrNull('2x');
      expect(fn, isNotNull);
      expect(fn!(5, 0), equals(10));
    });

    test('Power operator', () {
      final fn = EquationParser.parseOrNull('x^2');
      expect(fn, isNotNull);
      expect(fn!(3, 0), equals(9));
    });

    test('Trigonometric functions', () {
      final fn = EquationParser.parseOrNull('sin(x)');
      expect(fn, isNotNull);
      expect(fn!(0, 0), closeTo(0, 0.001));
    });

    test('Invalid equation returns null', () {
      final fn = EquationParser.parseOrNull('invalid + @');
      expect(fn, isNull);
    });
  });
}
