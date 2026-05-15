import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/tarot_repository.dart';
import '../models/drawn_card.dart';
import '../models/tarot_card.dart';

class DailyReadingService {
  DailyReadingService({
    required this.repository,
    Random? random,
    DateTime Function()? clock,
  })  : _random = random ?? Random(),
        _clock = clock ?? DateTime.now;

  static const String dateKey = 'daily_reading.date';
  static const String cardIdKey = 'daily_reading.card_id';
  static const String reversedKey = 'daily_reading.reversed';

  final TarotRepository repository;
  final Random _random;
  final DateTime Function() _clock;

  Future<DrawnCard> getOrCreateToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = todayKey();
    final cards = await repository.loadMajorArcana();

    final storedDate = prefs.getString(dateKey);
    if (storedDate == today) {
      final storedId = prefs.getString(cardIdKey);
      final storedReversed = prefs.getBool(reversedKey);
      if (storedId != null && storedReversed != null) {
        final found = _findCardById(cards, storedId);
        if (found != null) {
          return DrawnCard(card: found, reversed: storedReversed);
        }
      }
    }

    if (cards.isEmpty) {
      throw StateError('No cards available to draw a daily reading.');
    }
    final pool = List<TarotCard>.of(cards)..shuffle(_random);
    final picked = pool.first;
    final reversed = _random.nextBool();

    await prefs.setString(dateKey, today);
    await prefs.setString(cardIdKey, picked.id);
    await prefs.setBool(reversedKey, reversed);

    return DrawnCard(card: picked, reversed: reversed);
  }

  Future<void> clearToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dateKey);
    await prefs.remove(cardIdKey);
    await prefs.remove(reversedKey);
  }

  String todayKey() {
    final d = _clock();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  TarotCard? _findCardById(List<TarotCard> cards, String id) {
    for (final c in cards) {
      if (c.id == id) return c;
    }
    return null;
  }
}
