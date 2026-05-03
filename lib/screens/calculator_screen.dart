import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';
import '../utils/calculator_logic.dart';
import '../widgets/button.dart';
import '../widgets/display.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'theme_screen.dart';

class CalculatorScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const CalculatorScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorLogic _logic = CalculatorLogic();
  final TextEditingController _expressionController = TextEditingController();
  final FocusNode _expressionFocusNode = FocusNode();
  final List<HistoryEntry> _history = [];
  bool _historyLoaded = false;

  String _result = '';
  bool _hasError = false;
  bool _justEvaluated = false;

  static const _operatorMap = {
    '÷': '/',
    '×': '*',
    '−': '-',
    '+': '+',
  };

  static const _menuText = {
    _MenuAction.history: 'History',
    _MenuAction.theme: 'Theme',
    _MenuAction.help: 'Help',
  };

  @override
  void initState() {
    super.initState();
    _expressionFocusNode.requestFocus();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('history') ?? [];
    final entries = <HistoryEntry>[];
    for (final item in raw) {
      try {
        final map = jsonDecode(item);
        if (map is Map<String, Object?>) {
          entries.add(HistoryEntry.fromMap(map));
        } else if (map is Map<String, dynamic>) {
          entries.add(HistoryEntry.fromMap(map));
        }
      } catch (_) {
        continue;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _history
        ..clear()
        ..addAll(entries);
      _historyLoaded = true;
    });
  }

  Future<void> _saveHistory() async {
    if (!_historyLoaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = _history.map((entry) => jsonEncode(entry.toMap())).toList();
    await prefs.setStringList('history', raw);
  }

  @override
  void dispose() {
    _expressionController.dispose();
    _expressionFocusNode.dispose();
    super.dispose();
  }

  String get _expression => _expressionController.text;

  void _onButtonPressed(String label) {
    setState(() {
      _expressionFocusNode.requestFocus();
      if (label == 'C') {
        _clear();
        return;
      }
      if (label == '⌫') {
        _backspace();
        _updatePreview();
        return;
      }
      if (label == '=') {
        _evaluateFinal();
        return;
      }

      if (_operatorMap.containsKey(label)) {
        _insertText(label);
        _updatePreview();
        return;
      }

      _insertText(label);
      _updatePreview();
    });
  }

  void _clear() {
    _setExpression('');
    _result = '';
    _hasError = false;
    _justEvaluated = false;
  }

  void _backspace() {
    final selection = _normalizedSelection();
    if (selection.start == 0 && selection.end == 0) {
      return;
    }

    if (!selection.isCollapsed) {
      final updated = _expression.replaceRange(selection.start, selection.end, '');
      _setExpression(
        updated,
        selection: TextSelection.collapsed(offset: selection.start),
      );
      _justEvaluated = false;
      return;
    }

    final start = selection.start - 1;
    final updated = _expression.replaceRange(start, selection.start, '');
    _setExpression(updated, selection: TextSelection.collapsed(offset: start));
    _justEvaluated = false;
  }

  void _evaluateFinal() {
    final expressionSnapshot = _expression;
    final eval = _logic.evaluate(_normalizeExpression(expressionSnapshot));
    if (!eval.isValid) {
      _result = '';
      _hasError = false;
      return;
    }

    _result = eval.text ?? '';
    _hasError = eval.isError;

    if (!_hasError && _result.isNotEmpty) {
      _history.insert(
        0,
        HistoryEntry(
          expression: expressionSnapshot,
          result: _result,
          createdAt: DateTime.now(),
        ),
      );
      _saveHistory();
      _setExpression(_result);
      _justEvaluated = true;
    }
  }

  void _updatePreview() {
    final eval = _logic.evaluate(_normalizeExpression(_expression));
    if (!eval.isValid) {
      _result = _expression.isEmpty ? '0' : '';
      _hasError = false;
      return;
    }

    _result = eval.text ?? '';
    _hasError = eval.isError;
  }

  void _insertText(String text) {
    if (_justEvaluated && _shouldReplaceOnInput(text)) {
      _setExpression('', selection: const TextSelection.collapsed(offset: 0));
      _justEvaluated = false;
    }
    _replaceSelection(text);
  }

  bool _shouldReplaceOnInput(String text) {
    return RegExp(r'[0-9(.]').hasMatch(text);
  }

  void _setExpression(String text, {TextSelection? selection}) {
    _expressionController.value = TextEditingValue(
      text: text,
      selection: selection ?? TextSelection.collapsed(offset: text.length),
    );
  }

  void _replaceSelection(String text) {
    final selection = _normalizedSelection();
    final updated = _expression.replaceRange(selection.start, selection.end, text);
    final caret = selection.start + text.length;
    _setExpression(updated, selection: TextSelection.collapsed(offset: caret));
  }

  TextSelection _normalizedSelection() {
    final selection = _expressionController.selection;
    final length = _expression.length;
    if (!selection.isValid) {
      return TextSelection.collapsed(offset: length);
    }
    int start = selection.start;
    int end = selection.end;
    if (start < 0 || start > length) {
      start = length;
    }
    if (end < 0 || end > length) {
      end = length;
    }
    return TextSelection(baseOffset: start, extentOffset: end);
  }

  String _normalizeExpression(String expression) {
    return expression
        .replaceAll('÷', '/')
        .replaceAll('×', '*')
        .replaceAll('−', '-');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final numberBackground = colors.surfaceVariant;
    final numberForeground = colors.onSurfaceVariant;
    final operatorBackground = colors.primaryContainer;
    final operatorForeground = colors.onPrimaryContainer;
    final clearBackground = const Color(0xFFFF6B6B);
    final clearForeground = Colors.white;
    final equalsBackground = const Color(0xFFFFC857);
    final equalsForeground = const Color(0xFF1B1B1B);

    final displayResult = _result.isNotEmpty
        ? _result
        : (_expression.isEmpty ? '0' : '');


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => _MenuAction.values
                .map(
                  (action) => PopupMenuItem<_MenuAction>(
                    value: action,
                    child: Text(_menuText[action] ?? ''),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 20.0;
            final spacing = constraints.maxWidth < 380 ? 10.0 : 14.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                spacing,
                horizontalPadding,
                spacing,
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: CalculatorDisplay(
                      expressionController: _expressionController,
                      expressionFocusNode: _expressionFocusNode,
                      result: displayResult,
                      isError: _hasError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildButton(
                                  label: 'C',
                                  background: clearBackground,
                                  foreground: clearForeground,
                                  onTap: () => _onButtonPressed('C'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '⌫',
                                  background: operatorBackground,
                                  foreground: operatorForeground,
                                  onTap: () => _onButtonPressed('⌫'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '(',
                                  background: operatorBackground,
                                  foreground: operatorForeground,
                                  onTap: () => _onButtonPressed('('),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: ')',
                                  background: operatorBackground,
                                  foreground: operatorForeground,
                                  onTap: () => _onButtonPressed(')'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildButton(
                                  label: '7',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('7'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '8',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('8'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '9',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('9'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '÷',
                                  background: operatorBackground,
                                  foreground: operatorForeground,
                                  onTap: () => _onButtonPressed('÷'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildButton(
                                  label: '4',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('4'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '5',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('5'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '6',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('6'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '×',
                                  background: operatorBackground,
                                  foreground: operatorForeground,
                                  onTap: () => _onButtonPressed('×'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildButton(
                                  label: '1',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('1'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '2',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('2'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '3',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('3'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '−',
                                  background: operatorBackground,
                                  foreground: operatorForeground,
                                  onTap: () => _onButtonPressed('−'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacing),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildButton(
                                  label: '0',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('0'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '.',
                                  background: numberBackground,
                                  foreground: numberForeground,
                                  onTap: () => _onButtonPressed('.'),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '=',
                                  background: equalsBackground,
                                  foreground: equalsForeground,
                                  elevation: 2,
                                  onTap: () => _onButtonPressed('='),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _buildButton(
                                  label: '+',
                                  background: operatorBackground,
                                  foreground: operatorForeground,
                                  onTap: () => _onButtonPressed('+'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleMenuAction(_MenuAction action) {
    switch (action) {
      case _MenuAction.history:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HistoryScreen(history: _history),
          ),
        );
        break;
      case _MenuAction.theme:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ThemeScreen(
              themeMode: widget.themeMode,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        );
        break;
      case _MenuAction.help:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const HelpScreen()),
        );
        break;
    }
  }

  Widget _buildButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    double elevation = 1,
  }) {
    return AspectRatio(
      aspectRatio: 1,
      child: CalculatorButton(
        label: label,
        background: background,
        foreground: foreground,
        elevation: elevation,
        onTap: onTap,
      ),
    );
  }
}

enum _MenuAction {
  history,
  theme,
  help,
}
