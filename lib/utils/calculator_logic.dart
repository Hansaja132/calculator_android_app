class EvalResult {
  final bool isValid;
  final bool isError;
  final String? text;

  const EvalResult._({
    required this.isValid,
    required this.isError,
    required this.text,
  });

  const EvalResult.invalid() : this._(isValid: false, isError: false, text: null);

  const EvalResult.error(String message)
      : this._(isValid: true, isError: true, text: message);

  const EvalResult.value(String value)
      : this._(isValid: true, isError: false, text: value);
}

class CalculatorLogic {
  static const _operators = ['+', '-', '*', '/'];

  EvalResult evaluate(String expression) {
    if (expression.trim().isEmpty) {
      return const EvalResult.invalid();
    }

    final tokens = _tokenize(expression);
    if (tokens == null || tokens.isEmpty) {
      return const EvalResult.invalid();
    }

    final rpn = _toRpn(tokens);
    if (rpn is EvalResult) {
      return rpn;
    }

    final result = _evalRpn(rpn as List<Object>);
    if (result is EvalResult) {
      return result;
    }

    return EvalResult.value(_formatNumber(result as double));
  }

  List<Object>? _tokenize(String expression) {
    final tokens = <Object>[];
    final buffer = StringBuffer();
    bool expectingNumber = true;

    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      if (char == ' ') {
        continue;
      }

      if (_isDigit(char) || char == '.') {
        buffer.write(char);
        expectingNumber = false;
        continue;
      }

      if (char == '(') {
        if (!expectingNumber) {
          return null;
        }
        if (buffer.isNotEmpty) {
          return null;
        }
        tokens.add(char);
        expectingNumber = true;
        continue;
      }

      if (char == ')') {
        if (buffer.isNotEmpty) {
          final number = _parseBuffer(buffer.toString());
          if (number == null) {
            return null;
          }
          tokens.add(number);
          buffer.clear();
        }
        tokens.add(char);
        expectingNumber = false;
        continue;
      }

      if (_operators.contains(char)) {
        if (char == '-' && expectingNumber) {
          final next = _nextNonSpace(expression, i + 1);
          if (next == '(') {
            tokens.add(0.0);
            tokens.add('-');
            expectingNumber = true;
            continue;
          }
          buffer.write(char);
          expectingNumber = false;
          continue;
        }

        if (buffer.isNotEmpty) {
          final number = _parseBuffer(buffer.toString());
          if (number == null) {
            return null;
          }
          tokens.add(number);
        } else if (tokens.isNotEmpty && tokens.last == ')') {
          // Allow operators directly after closing parentheses.
        } else {
          return null;
        }
        tokens.add(char);
        buffer.clear();
        expectingNumber = true;
        continue;
      }

      return null;
    }

    if (buffer.isNotEmpty) {
      final number = _parseBuffer(buffer.toString());
      if (number == null) {
        return null;
      }
      tokens.add(number);
    }

    if (tokens.isNotEmpty && tokens.last is String) {
      final last = tokens.last as String;
      if (last != ')') {
        return null;
      }
    }

    return tokens;
  }

  Object _toRpn(List<Object> tokens) {
    final output = <Object>[];
    final operators = <String>[];

    for (final token in tokens) {
      if (token is double) {
        output.add(token);
        continue;
      }

      if (token is! String) {
        return const EvalResult.invalid();
      }

      if (token == '(') {
        operators.add(token);
        continue;
      }

      if (token == ')') {
        bool foundParen = false;
        while (operators.isNotEmpty) {
          final op = operators.removeLast();
          if (op == '(') {
            foundParen = true;
            break;
          }
          output.add(op);
        }
        if (!foundParen) {
          return const EvalResult.invalid();
        }
        continue;
      }

      if (_isOperator(token)) {
        while (operators.isNotEmpty &&
            _isOperator(operators.last) &&
            _precedence(operators.last) >= _precedence(token)) {
          output.add(operators.removeLast());
        }
        operators.add(token);
        continue;
      }

      return const EvalResult.invalid();
    }

    while (operators.isNotEmpty) {
      final op = operators.removeLast();
      if (op == '(' || op == ')') {
        return const EvalResult.invalid();
      }
      output.add(op);
    }

    return output;
  }

  Object _evalRpn(List<Object> tokens) {
    final stack = <double>[];

    for (final token in tokens) {
      if (token is double) {
        stack.add(token);
        continue;
      }

      if (token is! String || !_isOperator(token)) {
        return const EvalResult.invalid();
      }

      if (stack.length < 2) {
        return const EvalResult.invalid();
      }

      final right = stack.removeLast();
      final left = stack.removeLast();
      if (token == '/' && right == 0) {
        return const EvalResult.error('Error');
      }
      final value = _applyOperator(left, right, token);
      stack.add(value);
    }

    if (stack.length != 1) {
      return const EvalResult.invalid();
    }

    return stack.single;
  }

  double _applyOperator(double left, double right, String op) {
    switch (op) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case '*':
        return left * right;
      case '/':
        return left / right;
      default:
        return 0;
    }
  }

  bool _isOperator(String token) {
    return _operators.contains(token);
  }

  int _precedence(String op) {
    if (op == '*' || op == '/') {
      return 2;
    }
    if (op == '+' || op == '-') {
      return 1;
    }
    return 0;
  }

  double? _parseBuffer(String buffer) {
    if (buffer.isEmpty || buffer == '-' || buffer == '-.') {
      return null;
    }
    if (buffer.endsWith('.')) {
      return null;
    }
    return double.tryParse(buffer);
  }

  bool _isDigit(String char) {
    return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
  }

  String? _nextNonSpace(String expression, int start) {
    for (int i = start; i < expression.length; i++) {
      final char = expression[i];
      if (char != ' ') {
        return char;
      }
    }
    return null;
  }

  String _formatNumber(double value) {
    final fixed = value.toStringAsFixed(12);
    final trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    if (trimmed == '-0') {
      return '0';
    }
    return trimmed;
  }
}
