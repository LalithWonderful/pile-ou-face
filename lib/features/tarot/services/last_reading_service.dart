import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/tarot_repository.dart';
import '../models/drawn_card.dart';
import '../models/last_three_card_reading.dart';
import '../models/reading_intent.dart';
import 'local_storage_keys.dart';

/// Persists the most recent 3-card reading so the user can reopen it
/// from HomeScreen without re-tirage and without burning a fresh
/// quota slot. Only ONE last reading is kept — there is no history.
///
/// Storage format (JSON in SharedPreferences under
/// [LocalStorageKeys.lastThreeCardReading]):
///
/// ```json
/// {
///   "intent": "love",
///   "createdAt": "2026-05-17T10:30:00.000",
///   "cards": [
///     {"id": "le_mat", "reversed": false},
///     {"id": "le_bateleur", "reversed": true},
///     {"id": "l_imperatrice", "reversed": false}
///   ]
/// }
/// ```
///
/// On `load`, card ids are resolved against [repository] to rebuild
/// full [DrawnCard] objects. If the deck no longer contains one of the
/// stored ids (e.g. asset edit), `load` returns `null` and the user
/// simply doesn't see a "Revoir mon dernier tirage" button.
class LastReadingService {
  LastReadingService({
    required this.repository,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const String prefsKey = LocalStorageKeys.lastThreeCardReading;

  final TarotRepository repository;
  final DateTime Function() _clock;

  Future<void> save({
    required ReadingIntent intent,
    required List<DrawnCard> cards,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'intent': _intentKey(intent),
      'createdAt': _clock().toIso8601String(),
      'cards': [
        for (final c in cards)
          <String, dynamic>{
            'id': c.card.id,
            'reversed': c.reversed,
          },
      ],
    };
    await prefs.setString(prefsKey, jsonEncode(payload));
  }

  /// Returns whether a saved reading payload exists in storage. Does
  /// NOT validate the payload — HomeScreen only uses this for the
  /// "should the CTA be visible" decision; the actual resolution
  /// happens lazily in [load].
  Future<bool> hasSavedReading() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    return raw != null && raw.isNotEmpty;
  }

  /// Rebuilds the snapshot from storage. Returns `null` if no reading
  /// is stored, the payload is malformed, or one of the stored card
  /// ids is no longer present in the deck.
  Future<LastThreeCardReading?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;

    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final intent = _parseIntent(json['intent'] as String?);
    if (intent == null) return null;

    final createdAtRaw = json['createdAt'] as String?;
    final createdAt = createdAtRaw == null
        ? _clock()
        : (DateTime.tryParse(createdAtRaw) ?? _clock());

    final cardsRaw = json['cards'];
    if (cardsRaw is! List || cardsRaw.length != 3) return null;

    final deck = await repository.loadMajorArcana();
    final byId = {for (final c in deck) c.id: c};

    final drawn = <DrawnCard>[];
    for (final item in cardsRaw) {
      if (item is! Map<String, dynamic>) return null;
      final id = item['id'] as String?;
      final reversed = item['reversed'];
      if (id == null || reversed is! bool) return null;
      final card = byId[id];
      if (card == null) return null;
      drawn.add(DrawnCard(card: card, reversed: reversed));
    }

    return LastThreeCardReading(
      intent: intent,
      cards: List<DrawnCard>.unmodifiable(drawn),
      createdAt: createdAt,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }

  static String _intentKey(ReadingIntent intent) => switch (intent) {
        ReadingIntent.general => 'general',
        ReadingIntent.love => 'love',
        ReadingIntent.work => 'work',
        ReadingIntent.money => 'money',
      };

  static ReadingIntent? _parseIntent(String? key) => switch (key) {
        'general' => ReadingIntent.general,
        'love' => ReadingIntent.love,
        'work' => ReadingIntent.work,
        'money' => ReadingIntent.money,
        _ => null,
      };
}
