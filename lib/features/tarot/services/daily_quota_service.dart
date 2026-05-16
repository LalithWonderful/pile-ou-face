import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_quota_snapshot.dart';
import '../models/reading_intent.dart';

/// Tracks daily per-intent consumption counters (MVP quota = 2 / day).
class DailyQuotaService {
  DailyQuotaService({
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const String _prefsKey = 'quota.daily_intent_counters';
  static const int _quota = 2;

  final DateTime Function() _clock;

  String _todayKey() {
    final d = _clock();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _intentKey(ReadingIntent intent) => switch (intent) {
        ReadingIntent.general => 'general',
        ReadingIntent.love => 'love',
        ReadingIntent.work => 'work',
        ReadingIntent.money => 'money',
      };

  Future<DailyQuotaSnapshot> _loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return _freshSnapshot();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final snapshot = DailyQuotaSnapshot.fromJson(json);
      final today = _todayKey();
      if (snapshot.date != today) {
        return _freshSnapshot();
      }
      return snapshot;
    } catch (_) {
      return _freshSnapshot();
    }
  }

  DailyQuotaSnapshot _freshSnapshot() {
    final today = _todayKey();
    return DailyQuotaSnapshot(
      date: today,
      counters: const {
        'general': 0,
        'love': 0,
        'work': 0,
        'money': 0,
      },
    );
  }

  Future<void> _saveSnapshot(DailyQuotaSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(snapshot.toJson()));
  }

  /// Returns how many draws remain for [intent] today (never negative).
  Future<int> remaining(ReadingIntent intent) async {
    final snapshot = await _loadSnapshot();
    final used = snapshot.counters[_intentKey(intent)] ?? 0;
    final result = _quota - used;
    return result < 0 ? 0 : result;
  }

  /// Increments the counter for [intent] if quota remains.
  /// Returns `true` when consumption succeeded, `false` if quota is exhausted.
  Future<bool> tryConsume(ReadingIntent intent) async {
    final snapshot = await _loadSnapshot();
    final key = _intentKey(intent);
    final used = snapshot.counters[key] ?? 0;
    if (used >= _quota) {
      return false;
    }
    final updated = snapshot.copyWith(
      counters: {
        ...snapshot.counters,
        key: used + 1,
      },
    );
    await _saveSnapshot(updated);
    return true;
  }

  /// Exposes the current snapshot (useful for tests / debug).
  Future<DailyQuotaSnapshot> currentSnapshot() async {
    return _loadSnapshot();
  }
}
