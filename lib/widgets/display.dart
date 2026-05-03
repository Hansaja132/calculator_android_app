import 'package:flutter/material.dart';

class CalculatorDisplay extends StatelessWidget {
  final TextEditingController expressionController;
  final FocusNode expressionFocusNode;
  final String result;
  final bool isError;

  const CalculatorDisplay({
    super.key,
    required this.expressionController,
    required this.expressionFocusNode,
    required this.result,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: TextField(
                    controller: expressionController,
                    focusNode: expressionFocusNode,
                    readOnly: true,
                    showCursor: true,
                    autofocus: true,
                    cursorColor: Theme.of(context).colorScheme.primary,
                    cursorWidth: 2,
                    cursorRadius: const Radius.circular(1),
                    onTap: () => expressionFocusNode.requestFocus(),
                    enableInteractiveSelection: true,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.65),
                        ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SelectableText(
                    result,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: isError
                              ? Colors.redAccent
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
