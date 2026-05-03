class HistoryEntry {
  final String expression;
  final String result;
  final DateTime createdAt;

  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.createdAt,
  });

  Map<String, Object> toMap() {
    return {
      'expression': expression,
      'result': result,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HistoryEntry.fromMap(Map<String, Object?> map) {
    return HistoryEntry(
      expression: map['expression'] as String? ?? '',
      result: map['result'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
