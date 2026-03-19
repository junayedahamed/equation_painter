import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:eq_visulaization/eq_visulaization.dart';

void main() {
  group('EquationPainterWidget basics', () {
    test('can be instantiated', () {
      final widget = EquationPainterWidget(
        equations: [EquationConfig(function: (x, y) => x + y)],
      );
      expect(widget.equations.length, 1);
    });

    test('accepts multiple equations', () {
      final widget = EquationPainterWidget(
        equations: [
          EquationConfig(function: (x, y) => x),
          EquationConfig(function: (x, y) => y),
        ],
      );
      expect(widget.equations.length, 2);
    });
  });

  group('EquationParser — basic arithmetic', () {
    test('simple constant', () {
      final fn = EquationParser.parse('42');
      expect(fn(0, 0), closeTo(42.0, 1e-9));
    });

    test('addition', () {
      final fn = EquationParser.parse('x + y');
      expect(fn(3, 4), closeTo(7.0, 1e-9));
    });

    test('subtraction', () {
      final fn = EquationParser.parse('x - y');
      expect(fn(10, 3), closeTo(7.0, 1e-9));
    });

    test('multiplication', () {
      final fn = EquationParser.parse('x * y');
      expect(fn(3, 4), closeTo(12.0, 1e-9));
    });

    test('division', () {
      final fn = EquationParser.parse('x / y');
      expect(fn(10, 4), closeTo(2.5, 1e-9));
    });

    test('power operator ^', () {
      final fn = EquationParser.parse('x^2');
      expect(fn(3, 0), closeTo(9.0, 1e-9));
    });

    test('grouped parentheses', () {
      final fn = EquationParser.parse('(x + y) * 2');
      expect(fn(3, 4), closeTo(14.0, 1e-9));
    });

    test('right-associative power', () {
      // 2^3^2 = 2^(3^2) = 2^9 = 512
      final fn = EquationParser.parse('2^3^2');
      expect(fn(0, 0), closeTo(512.0, 1e-6));
    });
  });

  group('EquationParser — unary operators', () {
    test('unary minus', () {
      final fn = EquationParser.parse('-x');
      expect(fn(5, 0), closeTo(-5.0, 1e-9));
    });

    test('unary plus', () {
      final fn = EquationParser.parse('+x');
      expect(fn(5, 0), closeTo(5.0, 1e-9));
    });

    test('unary minus in expression', () {
      final fn = EquationParser.parse('x + -y');
      expect(fn(5, 3), closeTo(2.0, 1e-9));
    });
  });

  group('EquationParser — implicit multiplication', () {
    test('number × variable: 2x', () {
      final fn = EquationParser.parse('2x');
      expect(fn(3, 0), closeTo(6.0, 1e-9));
    });

    test('number × variable: 3y', () {
      final fn = EquationParser.parse('3y');
      expect(fn(0, 7), closeTo(21.0, 1e-9));
    });

    test('number × parentheses: 2(x + y)', () {
      final fn = EquationParser.parse('2(x + y)');
      expect(fn(3, 4), closeTo(14.0, 1e-9));
    });

    test('complex: x^2 + y^2 - 100 (circle)', () {
      // On the circle (x=6, y=8): 36+64-100 = 0
      final fn = EquationParser.parse('x^2 + y^2 - 100');
      expect(fn(6, 8), closeTo(0.0, 1e-6));
      // Inside the circle: negative
      expect(fn(0, 0), closeTo(-100.0, 1e-6));
    });
  });

  group('EquationParser — constants', () {
    test('pi constant', () {
      final fn = EquationParser.parse('pi');
      expect(fn(0, 0), closeTo(pi, 1e-12));
    });

    test('e (Euler) constant', () {
      final fn = EquationParser.parse('e');
      expect(fn(0, 0), closeTo(e, 1e-12));
    });

    test('pi in expression', () {
      final fn = EquationParser.parse('2*pi*x');
      expect(fn(1, 0), closeTo(2 * pi, 1e-9));
    });
  });

  group('EquationParser — scientific notation', () {
    test('1e3 = 1000', () {
      final fn = EquationParser.parse('1e3');
      expect(fn(0, 0), closeTo(1000.0, 1e-9));
    });

    test('2.5e-1 = 0.25', () {
      final fn = EquationParser.parse('2.5e-1');
      expect(fn(0, 0), closeTo(0.25, 1e-9));
    });

    test('x * 1e2 = 100x', () {
      final fn = EquationParser.parse('x * 1e2');
      expect(fn(3, 0), closeTo(300.0, 1e-6));
    });
  });

  group('EquationParser — single-arg functions', () {
    test('sin', () {
      final fn = EquationParser.parse('sin(x)');
      expect(fn(pi / 2, 0), closeTo(1.0, 1e-9));
    });

    test('cos', () {
      final fn = EquationParser.parse('cos(x)');
      expect(fn(0, 0), closeTo(1.0, 1e-9));
    });

    test('tan', () {
      final fn = EquationParser.parse('tan(x)');
      expect(fn(pi / 4, 0), closeTo(1.0, 1e-9));
    });

    test('asin', () {
      final fn = EquationParser.parse('asin(x)');
      expect(fn(1.0, 0), closeTo(pi / 2, 1e-9));
    });

    test('acos', () {
      final fn = EquationParser.parse('acos(x)');
      expect(fn(1.0, 0), closeTo(0.0, 1e-9));
    });

    test('atan', () {
      final fn = EquationParser.parse('atan(x)');
      expect(fn(1.0, 0), closeTo(pi / 4, 1e-9));
    });

    test('sqrt', () {
      final fn = EquationParser.parse('sqrt(x)');
      expect(fn(9, 0), closeTo(3.0, 1e-9));
    });

    test('abs', () {
      final fn = EquationParser.parse('abs(x)');
      expect(fn(-7, 0), closeTo(7.0, 1e-9));
    });

    test('log (natural log)', () {
      final fn = EquationParser.parse('log(x)');
      expect(fn(e, 0), closeTo(1.0, 1e-9));
    });

    test('log2', () {
      final fn = EquationParser.parse('log2(x)');
      expect(fn(8, 0), closeTo(3.0, 1e-9));
    });

    test('log10', () {
      final fn = EquationParser.parse('log10(x)');
      expect(fn(100, 0), closeTo(2.0, 1e-9));
    });

    test('exp', () {
      final fn = EquationParser.parse('exp(x)');
      expect(fn(1, 0), closeTo(e, 1e-9));
    });

    test('ceil', () {
      final fn = EquationParser.parse('ceil(x)');
      expect(fn(1.3, 0), closeTo(2.0, 1e-9));
    });

    test('floor', () {
      final fn = EquationParser.parse('floor(x)');
      expect(fn(1.9, 0), closeTo(1.0, 1e-9));
    });

    test('round', () {
      final fn = EquationParser.parse('round(x)');
      expect(fn(1.5, 0), closeTo(2.0, 1e-9));
    });

    test('sign positive', () {
      final fn = EquationParser.parse('sign(x)');
      expect(fn(5, 0), closeTo(1.0, 1e-9));
    });

    test('sign negative', () {
      final fn = EquationParser.parse('sign(x)');
      expect(fn(-3, 0), closeTo(-1.0, 1e-9));
    });
  });

  group('EquationParser — two-arg functions', () {
    test('pow(x, 3)', () {
      final fn = EquationParser.parse('pow(x, 3)');
      expect(fn(2, 0), closeTo(8.0, 1e-9));
    });

    test('atan2(y, x)', () {
      final fn = EquationParser.parse('atan2(y, x)');
      expect(fn(1, 1), closeTo(pi / 4, 1e-9));
    });

    test('min(x, y)', () {
      final fn = EquationParser.parse('min(x, y)');
      expect(fn(3, 7), closeTo(3.0, 1e-9));
    });

    test('max(x, y)', () {
      final fn = EquationParser.parse('max(x, y)');
      expect(fn(3, 7), closeTo(7.0, 1e-9));
    });
  });

  group('EquationParser — edge cases & error handling', () {
    test('division by zero returns NaN (not crash)', () {
      final fn = EquationParser.parse('x / 0');
      final result = fn(5, 0);
      expect(result.isNaN, isTrue);
    });

    test('empty equation → parseOrNull returns null', () {
      expect(EquationParser.parseOrNull(''), isNull);
      expect(EquationParser.parseOrNull('   '), isNull);
    });

    test('invalid equation → parseOrNull returns null', () {
      expect(EquationParser.parseOrNull('???'), isNull);
      expect(EquationParser.parseOrNull('++--'), isNull);
    });

    test('invalid equation → parse returns 0.0 function (backward compat)', () {
      final fn = EquationParser.parse('???');
      expect(fn(1, 1), closeTo(0.0, 1e-9));
    });

    test('unknown function → parseOrNull returns null', () {
      expect(EquationParser.parseOrNull('foobar(x)'), isNull);
    });

    test('whitespace is ignored', () {
      final fn = EquationParser.parse('  x  +  y  ');
      expect(fn(2, 3), closeTo(5.0, 1e-9));
    });

    test('deeply nested parentheses', () {
      final fn = EquationParser.parse('((((x))))');
      expect(fn(42, 0), closeTo(42.0, 1e-9));
    });

    test('complex trig equation', () {
      final fn = EquationParser.parse('sin(x)^2 + cos(x)^2 - 1');
      // Pythagorean identity → should be ≈ 0 for all x
      expect(fn(1.0, 0), closeTo(0.0, 1e-9));
      expect(fn(2.5, 0), closeTo(0.0, 1e-9));
    });
  });
}
