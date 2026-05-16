import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/models/reading_intent.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DailyQuotaService', () {
    late DailyQuotaService service;
    late DateTime now;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 5, 15);
      service = DailyQuotaService(clock: () => now);
    });

    test('initial snapshot has remaining = 2 for each intent', () async {
      for (final intent in ReadingIntent.values) {
        expect(await service.remaining(intent), 2);
      }
    });

    test('tryConsume decrements remaining from 2 to 1', () async {
      final consumed = await service.tryConsume(ReadingIntent.general);
      expect(consumed, isTrue);
      expect(await service.remaining(ReadingIntent.general), 1);
    });

    test('two tryConsume succeed, third returns false', () async {
      expect(await service.tryConsume(ReadingIntent.love), isTrue);
      expect(await service.tryConsume(ReadingIntent.love), isTrue);
      expect(await service.tryConsume(ReadingIntent.love), isFalse);
      expect(await service.remaining(ReadingIntent.love), 0);
    });

    test('consuming one intent does not affect others', () async {
      await service.tryConsume(ReadingIntent.general);
      expect(await service.remaining(ReadingIntent.general), 1);
      expect(await service.remaining(ReadingIntent.love), 2);
      expect(await service.remaining(ReadingIntent.work), 2);
      expect(await service.remaining(ReadingIntent.money), 2);
    });

    test('date change resets all counters', () async {
      await service.tryConsume(ReadingIntent.general);
      await service.tryConsume(ReadingIntent.love);
      expect(await service.remaining(ReadingIntent.general), 1);
      expect(await service.remaining(ReadingIntent.love), 1);

      // Simulate next day
      now = DateTime(2026, 5, 16);
      for (final intent in ReadingIntent.values) {
        expect(await service.remaining(intent), 2);
      }
    });

    test('malformed JSON returns fresh snapshot without crash', () async {
      SharedPreferences.setMockInitialValues({
        'quota.daily_intent_counters': 'not-json',
      });
      expect(await service.remaining(ReadingIntent.work), 2);
      expect(await service.tryConsume(ReadingIntent.work), isTrue);
    });

    test('missing intent key in counters is treated as 0', () async {
      SharedPreferences.setMockInitialValues({
        'quota.daily_intent_counters':
            '{"date":"2026-05-15","counters":{}}',
      });
      expect(await service.remaining(ReadingIntent.money), 2);
    });

    test('currentSnapshot reflects consumed counters', () async {
      await service.tryConsume(ReadingIntent.general);
      await service.tryConsume(ReadingIntent.general);
      await service.tryConsume(ReadingIntent.love);
      final snapshot = await service.currentSnapshot();
      expect(snapshot.date, '2026-05-15');
      expect(snapshot.counters['general'], 2);
      expect(snapshot.counters['love'], 1);
      expect(snapshot.counters['work'], 0);
      expect(snapshot.counters['money'], 0);
    });

    test('remaining never goes below 0', () async {
      await service.tryConsume(ReadingIntent.money);
      await service.tryConsume(ReadingIntent.money);
      await service.tryConsume(ReadingIntent.money); // false, no increment
      expect(await service.remaining(ReadingIntent.money), 0);
    });
  });
}
