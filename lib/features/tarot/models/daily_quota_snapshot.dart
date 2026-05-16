import 'package:flutter/foundation.dart';

/// Immutable snapshot of the daily per-intent consumption counters.
@immutable
class DailyQuotaSnapshot {
  const DailyQuotaSnapshot({
    required this.date,
    required this.counters,
  });

  final String date;
  final Map<String, int> counters;

  factory DailyQuotaSnapshot.fromJson(Map<String, dynamic> json) {
    final rawCounters = json['counters'] as Map<String, dynamic>? ?? {};
    return DailyQuotaSnapshot(
      date: json['date'] as String? ?? '',
      counters: {
        for (final entry in rawCounters.entries)
          entry.key: (entry.value as num).toInt(),
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'counters': counters,
      };

  DailyQuotaSnapshot copyWith({
    String? date,
    Map<String, int>? counters,
  }) {
    return DailyQuotaSnapshot(
      date: date ?? this.date,
      counters: counters ?? Map<String, int>.of(this.counters),
    );
  }
}
