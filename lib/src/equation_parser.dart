import 'dart:math';

/// Typedef for a two-variable mathematical function returning a double.
/// Used as the return type of [EquationParser.parseOrNull].
typedef MathFn = double Function(double x, double y);

/// A utility class to parse string mathematical equations into executable functions.
///
/// **Supported syntax:**
/// - Operators: `+`, `-`, `*`, `/`, `^` (power)
/// - Implicit multiplication: `2x`, `3(x+y)`, `x(y-1)`
/// - Variables: `x`, `y`
/// - Constants: `pi`, `e`
/// - Functions: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `sqrt`, `abs`,
///   `log` (natural), `log2`, `log10`, `exp`, `ceil`, `floor`, `round`, `sign`
/// - Multi-arg functions: `pow(base, exp)`, `atan2(y, x)`, `min(a,b)`, `max(a,b)`
/// - Scientific notation: `1e5`, `2.5e-3`
/// - Parentheses for grouping
///
/// All parsing errors are surfaced via [parseOrNull]; [parse] maintains
/// backward compatibility by returning `(x,y) => 0.0` on failure.
class EquationParser {
  /// Parses [equation] and returns a math function `(x, y) → double`.
  ///
  /// Returns `(x, y) => 0.0` if parsing fails (backward-compatible).
  /// Prefer [parseOrNull] when you need error feedback.
  static MathFn parse(String equation) {
    return parseOrNull(equation) ?? (double x, double y) => 0.0;
  }

  /// Parses [equation] and returns a [MathFn], or `null` if the
  /// equation is empty or syntactically/semantically invalid.
  static MathFn? parseOrNull(String equation) {
    final trimmed = equation.trim();
    if (trimmed.isEmpty) return null;
    try {
      final tokens = _tokenize(trimmed);
      if (tokens.isEmpty) return null;
      final node = _Parser(tokens).parse();
      return (double x, double y) {
        final result = node.evaluate(x, y);
        return result;
      };
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Tokenizer
  // ---------------------------------------------------------------------------

  static List<_Token> _tokenize(String equation) {
    final List<_Token> tokens = [];
    final int len = equation.length;
    int i = 0;

    while (i < len) {
      final char = equation[i];

      // Skip whitespace
      if (char.trim().isEmpty) {
        i++;
        continue;
      }

      // Number (including scientific notation: 1e5, 2.5e-3)
      if (_isDigit(char) || (char == '.' && i + 1 < len && _isDigit(equation[i + 1]))) {
        final start = i;
        while (i < len && (_isDigit(equation[i]) || equation[i] == '.')) {
          i++;
        }
        // Handle scientific notation suffix: e/E optionally followed by +/-
        if (i < len && (equation[i] == 'e' || equation[i] == 'E')) {
          i++; // consume 'e'/'E'
          if (i < len && (equation[i] == '+' || equation[i] == '-')) {
            i++; // consume sign
          }
          while (i < len && _isDigit(equation[i])) {
            i++;
          }
        }
        final numStr = equation.substring(start, i);
        tokens.add(_ConstantToken(double.parse(numStr)));

        // Insert implicit multiplication if followed by variable/function/(
        if (i < len) {
          final next = equation[i];
          if (_isAlpha(next) || next == '(') {
            tokens.add(_OperatorToken('*'));
          }
        }
        continue;
      }

      // Identifier: variable, constant, or function name
      if (_isAlpha(char)) {
        final start = i;
        while (i < len && (_isAlpha(equation[i]) || _isDigit(equation[i]))) {
          i++;
        }
        final name = equation.substring(start, i);

        // Check for closing paren/open paren to decide literal vs function
        final bool nextIsParen = i < len && equation[i] == '(';

        if (name == 'x' || name == 'y') {
          tokens.add(_VariableToken(name));
        } else if (name == 'pi') {
          tokens.add(_ConstantToken(pi));
        } else if (name == 'e' && !nextIsParen) {
          // 'e' as Euler's constant only when NOT followed by '('
          tokens.add(_ConstantToken(e));
        } else {
          tokens.add(_FunctionToken(name));
        }

        // Insert implicit multiplication if identifier is followed by ( or var
        // but NOT for recognized functions (they expect their own '(')
        if (i < len && !nextIsParen) {
          final next = equation[i];
          if (_isAlpha(next)) {
            tokens.add(_OperatorToken('*'));
          }
        }
        continue;
      }

      // Operators and punctuation
      if ('+-*/^(),'.contains(char)) {
        tokens.add(char == ',' ? _CommaToken() : _OperatorToken(char));
        i++;

        // Insert implicit multiplication after ')' if followed by '(' or identifier/number
        if (char == ')' && i < len) {
          final next = equation[i];
          if (next == '(' || _isAlpha(next) || _isDigit(next)) {
            tokens.add(_OperatorToken('*'));
          }
        }
        continue;
      }

      // Unknown character — skip gracefully (could raise if strict mode wanted)
      i++;
    }

    return tokens;
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  static bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122) || c == '_';
  }
}

// =============================================================================
// Token types
// =============================================================================

abstract class _Token {}

class _VariableToken extends _Token {
  final String name;
  _VariableToken(this.name);
}

class _ConstantToken extends _Token {
  final double value;
  _ConstantToken(this.value);
}

class _OperatorToken extends _Token {
  final String operator;
  _OperatorToken(this.operator);
}

class _FunctionToken extends _Token {
  final String function;
  _FunctionToken(this.function);
}

class _CommaToken extends _Token {}

// =============================================================================
// AST Nodes
// =============================================================================

abstract class _Node {
  double evaluate(double x, double y);
}

class _NumberNode extends _Node {
  final double value;
  _NumberNode(this.value);
  @override
  double evaluate(double x, double y) => value;
}

class _VariableNode extends _Node {
  final String variable;
  _VariableNode(this.variable);
  @override
  double evaluate(double x, double y) => variable == 'x' ? x : y;
}

class _UnaryOperatorNode extends _Node {
  final String operator;
  final _Node operand;
  _UnaryOperatorNode(this.operator, this.operand);
  @override
  double evaluate(double x, double y) {
    final v = operand.evaluate(x, y);
    return operator == '-' ? -v : v; // handles both '-' and '+'
  }
}

class _BinaryOperatorNode extends _Node {
  final String operator;
  final _Node left;
  final _Node right;
  _BinaryOperatorNode(this.operator, this.left, this.right);
  @override
  double evaluate(double x, double y) {
    final l = left.evaluate(x, y);
    final r = right.evaluate(x, y);
    switch (operator) {
      case '+':
        return l + r;
      case '-':
        return l - r;
      case '*':
        return l * r;
      case '/':
        if (r == 0) return double.nan;
        return l / r;
      case '^':
        return pow(l, r).toDouble();
      default:
        return 0;
    }
  }
}

/// Node for single-argument built-in functions (sin, cos, etc.)
class _FunctionNode extends _Node {
  final String function;
  final _Node argument;
  _FunctionNode(this.function, this.argument);

  @override
  double evaluate(double x, double y) {
    final arg = argument.evaluate(x, y);
    switch (function.toLowerCase()) {
      case 'sin':
        return sin(arg);
      case 'cos':
        return cos(arg);
      case 'tan':
        return tan(arg);
      case 'asin':
        return asin(arg);
      case 'acos':
        return acos(arg);
      case 'atan':
        return atan(arg);
      case 'sqrt':
        return sqrt(arg);
      case 'cbrt':
        // Cube root: preserves sign for negative inputs
        return arg < 0 ? -pow(-arg, 1.0 / 3.0).toDouble() : pow(arg, 1.0 / 3.0).toDouble();
      case 'abs':
        return arg.abs();
      case 'log':
      case 'ln':
        return log(arg);
      case 'log2':
        return log(arg) / ln2;
      case 'log10':
        return log(arg) / ln10;
      case 'exp':
        return exp(arg);
      case 'ceil':
        return arg.ceilToDouble();
      case 'floor':
        return arg.floorToDouble();
      case 'round':
        return arg.roundToDouble();
      case 'sign':
        return arg.sign;
      default:
        throw Exception('Unknown function: $function');
    }
  }
}

/// Node for two-argument built-in functions (pow, atan2, min, max)
class _BinaryFunctionNode extends _Node {
  final String function;
  final _Node arg1;
  final _Node arg2;
  _BinaryFunctionNode(this.function, this.arg1, this.arg2);

  @override
  double evaluate(double x, double y) {
    final a = arg1.evaluate(x, y);
    final b = arg2.evaluate(x, y);
    switch (function.toLowerCase()) {
      case 'pow':
        return pow(a, b).toDouble();
      case 'atan2':
        return atan2(a, b);
      case 'min':
        return min(a, b).toDouble();
      case 'max':
        return max(a, b).toDouble();
      case 'hypot':
        return sqrt(a * a + b * b);
      default:
        throw Exception('Unknown binary function: $function');
    }
  }
}

// =============================================================================
// Recursive-descent parser
// =============================================================================

/// Two-argument function names recognized by the parser.
const _binaryFunctions = {'pow', 'atan2', 'min', 'max', 'hypot'};

/// Single-argument function names recognized by the parser.
const _unaryFunctions = {
  'sin', 'cos', 'tan',
  'asin', 'acos', 'atan',
  'sqrt', 'cbrt', 'abs',
  'log', 'ln', 'log2', 'log10', 'exp',
  'ceil', 'floor', 'round', 'sign',
};

class _Parser {
  final List<_Token> tokens;
  int _pos = 0;

  _Parser(this.tokens);

  _Token? get _current => _pos < tokens.length ? tokens[_pos] : null;
  void _consume() => _pos++;

  _Node parse() {
    final node = _parseExpression();
    if (_current != null) {
      throw Exception('Unexpected token at position $_pos: ${_current.runtimeType}');
    }
    return node;
  }

  // Expression: handles + and - at lowest precedence
  _Node _parseExpression() {
    _Node node = _parseTerm();
    while (_current is _OperatorToken) {
      final op = (_current as _OperatorToken).operator;
      if (op == '+' || op == '-') {
        _consume();
        node = _BinaryOperatorNode(op, node, _parseTerm());
      } else {
        break;
      }
    }
    return node;
  }

  // Term: handles * and /
  _Node _parseTerm() {
    _Node node = _parsePower();
    while (_current is _OperatorToken) {
      final op = (_current as _OperatorToken).operator;
      if (op == '*' || op == '/') {
        _consume();
        node = _BinaryOperatorNode(op, node, _parsePower());
      } else {
        break;
      }
    }
    return node;
  }

  // Power: handles ^ (right-associative)
  _Node _parsePower() {
    _Node node = _parsePrimary();
    if (_current is _OperatorToken && (_current as _OperatorToken).operator == '^') {
      _consume();
      // Right-associative: recurse into _parsePower (not _parsePrimary)
      node = _BinaryOperatorNode('^', node, _parsePower());
    }
    return node;
  }

  // Primary: handles literals, variables, unary operators, functions, parentheses
  _Node _parsePrimary() {
    final token = _current;

    // Numeric literal
    if (token is _ConstantToken) {
      _consume();
      return _NumberNode(token.value);
    }

    // Variable (x or y)
    if (token is _VariableToken) {
      _consume();
      return _VariableNode(token.name);
    }

    // Named function call
    if (token is _FunctionToken) {
      final funcName = token.function.toLowerCase();
      _consume();

      // Validate at parse time — unknown names cause parseOrNull to return null
      if (!_unaryFunctions.contains(funcName) && !_binaryFunctions.contains(funcName)) {
        throw Exception("Unknown function: '$funcName'");
      }

      if (_current is! _OperatorToken ||
          (_current as _OperatorToken).operator != '(') {
        throw Exception("Expected '(' after function name '$funcName'");
      }
      _consume(); // consume '('

      final arg1 = _parseExpression();

      // Check for binary functions (two arguments separated by comma)
      if (_binaryFunctions.contains(funcName)) {
        if (_current is! _CommaToken) {
          throw Exception("Expected ',' in binary function '$funcName'");
        }
        _consume(); // consume ','
        final arg2 = _parseExpression();
        _expectCloseParen(funcName);
        return _BinaryFunctionNode(funcName, arg1, arg2);
      }

      _expectCloseParen(funcName);
      return _FunctionNode(funcName, arg1);
    }

    // Parenthesised expression
    if (token is _OperatorToken && token.operator == '(') {
      _consume(); // consume '('
      final node = _parseExpression();
      if (_current is _OperatorToken && (_current as _OperatorToken).operator == ')') {
        _consume(); // consume ')'
      } else {
        throw Exception("Mismatched parentheses: expected ')'");
      }
      return node;
    }

    // Unary minus or plus
    if (token is _OperatorToken &&
        (token.operator == '-' || token.operator == '+')) {
      _consume();
      return _UnaryOperatorNode(token.operator, _parsePower());
    }

    throw Exception('Unexpected token: ${token?.runtimeType ?? "end of input"}');
  }

  void _expectCloseParen(String context) {
    if (_current is _OperatorToken &&
        (_current as _OperatorToken).operator == ')') {
      _consume();
    } else {
      throw Exception("Expected ')' to close '$context' call");
    }
  }
}
