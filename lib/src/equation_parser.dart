import 'dart:math';

/// A utility class to parse string mathematical equations into executable functions.
/// Supports basic operators (+, -, *, /, ^), variables (x, y), functions (sin, cos, tan, sqrt, log, exp),
/// and parentheses.
class EquationParser {
  /// Parses a string [equation] and returns a [MathFunction] (double Function(double, double)).
  /// The equation should be an implicit expression like 'x^2 + y^2 - 100'.
  static double Function(double x, double y) parse(String equation) {
    try {
      final tokens = _tokenize(equation);
      final node = _Parser(tokens).parse();
      return (double x, double y) => node.evaluate(x, y).toDouble();
    } catch (e) {
      // In case of error, return a function that always returns 0 (or some error indicator)
      return (double x, double y) => 0.0;
    }
  }

  static List<_Token> _tokenize(String equation) {
    List<_Token> tokens = [];
    String buffer = '';

    for (int i = 0; i < equation.length; i++) {
      var char = equation[i];

      if (char.trim().isEmpty) continue;

      if (RegExp(r'[0-9.]').hasMatch(char)) {
        buffer += char;
        if (i + 1 == equation.length ||
            !RegExp(r'[0-9.]').hasMatch(equation[i + 1])) {
          tokens.add(_ConstantToken(double.parse(buffer)));
          buffer = '';
        }
      } else if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        buffer += char;
        if (i + 1 == equation.length ||
            !RegExp(r'[a-zA-Z]').hasMatch(equation[i + 1])) {
          if (buffer == 'x' || buffer == 'y') {
            tokens.add(_VariableToken(buffer));
          } else {
            tokens.add(_FunctionToken(buffer));
          }
          buffer = '';
        }
      } else if ('+-*/^()'.contains(char)) {
        tokens.add(_OperatorToken(char));
      }
    }
    return tokens;
  }
}

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

abstract class _Node {
  num evaluate(double x, double y);
}

class _NumberNode extends _Node {
  final double value;
  _NumberNode(this.value);
  @override
  num evaluate(double x, double y) => value;
}

class _VariableNode extends _Node {
  final String variable;
  _VariableNode(this.variable);
  @override
  num evaluate(double x, double y) => variable == 'x' ? x : y;
}

class _UnaryOperatorNode extends _Node {
  final String operator;
  final _Node operand;
  _UnaryOperatorNode(this.operator, this.operand);
  @override
  num evaluate(double x, double y) {
    if (operator == '-') return -operand.evaluate(x, y);
    return operand.evaluate(x, y);
  }
}

class _BinaryOperatorNode extends _Node {
  final String operator;
  final _Node left;
  final _Node right;
  _BinaryOperatorNode(this.operator, this.left, this.right);
  @override
  num evaluate(double x, double y) {
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
        return l / r;
      case '^':
        return pow(l, r);
      default:
        return 0;
    }
  }
}

class _FunctionNode extends _Node {
  final String function;
  final _Node argument;
  _FunctionNode(this.function, this.argument);
  @override
  num evaluate(double x, double y) {
    final arg = argument.evaluate(x, y).toDouble();
    switch (function.toLowerCase()) {
      case 'sin':
        return sin(arg);
      case 'cos':
        return cos(arg);
      case 'tan':
        return tan(arg);
      case 'sqrt':
        return sqrt(arg);
      case 'log':
        return log(arg);
      case 'exp':
        return exp(arg);
      case 'abs':
        return arg.abs();
      default:
        return 0;
    }
  }
}

class _Parser {
  final List<_Token> tokens;
  int _pos = 0;

  _Parser(this.tokens);

  _Token? get _current => _pos < tokens.length ? tokens[_pos] : null;

  void _consume() => _pos++;

  _Node parse() {
    return _parseExpression();
  }

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

  _Node _parsePower() {
    _Node node = _parsePrimary();
    while (_current is _OperatorToken &&
        (_current as _OperatorToken).operator == '^') {
      _consume();
      node = _BinaryOperatorNode('^', node, _parsePower());
    }
    return node;
  }

  _Node _parsePrimary() {
    final token = _current;
    if (token is _ConstantToken) {
      _consume();
      return _NumberNode(token.value);
    }
    if (token is _VariableToken) {
      _consume();
      return _VariableNode(token.name);
    }
    if (token is _FunctionToken) {
      final func = token.function;
      _consume();
      if (_current is _OperatorToken &&
          (_current as _OperatorToken).operator == '(') {
        _consume();
        final arg = _parseExpression();
        if (_current is _OperatorToken &&
            (_current as _OperatorToken).operator == ')') {
          _consume();
        }
        return _FunctionNode(func, arg);
      }
      throw Exception('Expected ( after function name');
    }
    if (token is _OperatorToken) {
      if (token.operator == '(') {
        _consume();
        final node = _parseExpression();
        if (_current is _OperatorToken &&
            (_current as _OperatorToken).operator == ')') {
          _consume();
        }
        return node;
      }
      if (token.operator == '-') {
        _consume();
        return _UnaryOperatorNode('-', _parsePrimary());
      }
    }
    throw Exception('Unexpected token: $token');
  }
}
