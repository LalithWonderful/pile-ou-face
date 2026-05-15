import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _buildFixture(int count) {
  final buffer = StringBuffer('[');
  for (var i = 0; i < count; i++) {
    if (i > 0) buffer.write(',');
    buffer.write('''
{
  "id": "card_$i",
  "number": $i,
  "name": "Carte $i",
  "image_path": null,
  "keywords_upright": ["droit_$i"],
  "keywords_reversed": ["inverse_$i"],
  "meaning_upright": "Sens droit $i.",
  "meaning_reversed": "Sens inversé $i.",
  "love": "Amour $i.",
  "work": "Travail $i.",
  "advice": "Conseil $i.",
  "warning": "Avertissement $i.",
  "short_message": "Court $i.",
  "share_message": "Partage $i.",
  "tags": ["tag_$i"]
}
''');
  }
  buffer.write(']');
  return buffer.toString();
}

DailyReadingService _buildService({
  required DateTime now,
  int deckSize = 22,
  int randomSeed = 42,
}) {
  final repo =
      TarotRepository(loader: (_) async => _buildFixture(deckSize));
  return DailyReadingService(
    repository: repo,
    random: Random(randomSeed),
    clock: () => now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('DailyReadingService', () {
    test('creates and persists a reading when none exists today', () async {
      final service = _buildService(now: DateTime(2026, 5, 15));

      final reading = await service.getOrCreateToday();

      expect(reading.card.id, isNotEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(DailyReadingService.dateKey), '2026-05-15');
      expect(
        prefs.getString(DailyReadingService.cardIdKey),
        reading.card.id,
      );
      expect(
        prefs.getBool(DailyReadingService.reversedKey),
        reading.reversed,
      );
    });

    test('returns the same reading when called twice the same day', () async {
      final service = _buildService(now: DateTime(2026, 5, 15));

      final first = await service.getOrCreateToday();
      final second = await service.getOrCreateToday();

      expect(second.card.id, first.card.id);
      expect(second.reversed, first.reversed);
    });

    test('regenerates a new reading on a different day', () async {
      final today = _buildService(
        now: DateTime(2026, 5, 15),
        randomSeed: 1,
      );
      final tomorrow = _buildService(
        now: DateTime(2026, 5, 16),
        randomSeed: 2,
      );

      final firstReading = await today.getOrCreateToday();
      final secondReading = await tomorrow.getOrCreateToday();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(DailyReadingService.dateKey), '2026-05-16');
      expect(
        prefs.getString(DailyReadingService.cardIdKey),
        secondReading.card.id,
      );
      // With different seeds and a fresh shuffle on day change, very high
      // odds the picked card is not the previous one; we assert the stored
      // id has been refreshed rather than asserting two distinct cards.
      expect(secondReading.card.id, isNotNull);
      expect(firstReading.card.id, isNotNull);
    });

    test('stores only the three documented keys', () async {
      final service = _buildService(now: DateTime(2026, 5, 15));

      await service.getOrCreateToday();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys(),
        unorderedEquals(<String>{
          DailyReadingService.dateKey,
          DailyReadingService.cardIdKey,
          DailyReadingService.reversedKey,
        }),
      );
    });

    test('clearToday wipes the stored daily reading', () async {
      final service = _buildService(now: DateTime(2026, 5, 15));
      await service.getOrCreateToday();

      await service.clearToday();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('formats todayKey as yyyy-MM-dd with zero-padding', () {
      final service = _buildService(now: DateTime(2026, 1, 7));
      expect(service.todayKey(), '2026-01-07');
    });
  });
}
