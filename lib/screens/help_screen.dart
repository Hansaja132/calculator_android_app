import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Calcify Help',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          Text(
            'Use the keypad to build your expression. You can tap the expression '
            'area to place the cursor and insert values anywhere. Long-press the '
            'result to select and copy it.',
          ),
          SizedBox(height: 12),
          Text(
            'Supported operators: +, −, ×, ÷, and parentheses. Tap = to finalize '
            'the result and it will be added to your history.',
          ),
        ],
      ),
    );
  }
}
