import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/drawn_card.dart';
import 'package:pile_ou_face/features/tarot/models/reading_intent.dart';
import 'package:pile_ou_face/features/tarot/services/last_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/local_storage_keys.dart';
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
  "money": "Argent $i.",
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

LastReadingService _buildService({
  int deckSize = 22,
  DateTime? now,
}) {
  final repo = TarotRepository(loader: (_) async => _buildFixture(deckSize));
  return LastReadingService(
    repository: repo,
    clock: () => now ?? DateTime(2026, 5, 17, 10, 30),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('LastReadingService', () {
    test('hasSavedReading is false when storage is empty', () async {
      final service = _buildService();
      expect(await service.hasSavedReading(), isFalse);
      expect(await service.load(), isNull);
    });

    test('save persists the intent, cards and createdAt', () async {
      final service = _buildService(now: DateTime(2026, 5, 17, 10, 30));
      final repo = TarotRepository(loader: (_) async => _buildFixture(22));
      final deck = await repo.loadMajorArcana();

      final cards = <DrawnCard>[
        DrawnCard(card: deck[0], reversed: false),
        DrawnCard(card: deck[5], reversed: true),
        DrawnCard(card: deck[11], reversed: false),
      ];

      await service.save(intent: ReadingIntent.love, cards: cards);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(LocalStorageKeys.lastThreeCardReading);
      expect(raw, isNotNull);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['intent'], 'love');
      expect(json['createdAt'], '2026-05-17T10:30:00.000');
      final storedCards = json['cards'] as List<dynamic>;
      expect(storedCards, hasLength(3));
      expect(storedCards[0], {'id': 'card_0', 'reversed': false});
      expect(storedCards[1], {'id': 'card_5', 'reversed': true});
      expect(storedCards[2], {'id': 'card_11', 'reversed': false});
    });

    test('load rebuilds the exact same cards and orientations', () async {
      final service = _buildService(now: DateTime(2026, 5, 17));
      final repo = TarotRepository(loader: (_) async => _buildFixture(22));
      final deck = await repo.loadMajorArcana();

      final cards = <DrawnCard>[
        DrawnCard(card: deck[3], reversed: true),
        DrawnCard(card: deck[7], reversed: false),
        DrawnCard(card: deck[14], reversed: true),
      ];
      await service.save(intent: ReadingIntent.work, cards: cards);

      final snapshot = await service.load();
      expect(snapshot, isNotNull);
      expect(snapshot!.intent, ReadingIntent.work);
      expect(snapshot.cards, hasLength(3));
      expect(snapshot.cards[0].card.id, 'card_3');
      expect(snapshot.cards[0].reversed, isTrue);
      expect(snapshot.cards[1].card.id, 'card_7');
      expect(snapshot.cards[1].reversed, isFalse);
      expect(snapshot.cards[2].card.id, 'card_14');
      expect(snapshot.cards[2].reversed, isTrue);
      expect(snapshot.createdAt, DateTime(2026, 5, 17));
    });

    test('save replaces a previously stored reading', () async {
      final service = _buildService();
      final repo = TarotRepository(loader: (_) async => _buildFixture(22));
      final deck = await repo.loadMajorArcana();

      await service.save(
        intent: ReadingIntent.love,
        cards: [
          DrawnCard(card: deck[0], reversed: false),
          DrawnCard(card: deck[1], reversed: false),
          DrawnCard(card: deck[2], reversed: false),
        ],
      );
      await service.save(
        intent: ReadingIntent.money,
        cards: [
          DrawnCard(card: deck[9], reversed: true),
          DrawnCard(card: deck[10], reversed: true),
          DrawnCard(card: deck[11], reversed: true),
        ],
      );

      final snapshot = await service.load();
      expect(snapshot!.intent, ReadingIntent.money);
      expect(snapshot.cards.map((c) => c.card.id),
          ['card_9', 'card_10', 'card_11']);
    });

    test('load returns null when payload is malformed JSON', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageKeys.lastThreeCardReading: '{not json',
      });
      final service = _buildService();
      expect(await service.load(), isNull);
    });

    test('load returns null when a stored card id no longer exists',
        () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageKeys.lastThreeCardReading: jsonEncode({
          'intent': 'love',
          'createdAt': '2026-05-17T10:30:00.000',
          'cards': [
            {'id': 'card_0', 'reversed': false},
            {'id': 'phantom_card', 'reversed': true},
            {'id': 'card_2', 'reversed': false},
          ],
        }),
      });
      final service = _buildService();
      expect(await service.load(), isNull);
    });

    test('clear removes the saved reading', () async {
      final service = _buildService();
      final repo = TarotRepository(loader: (_) async => _buildFixture(22));
      final deck = await repo.loadMajorArcana();
      await service.save(
        intent: ReadingIntent.general,
        cards: [
          DrawnCard(card: deck[0], reversed: false),
          DrawnCard(card: deck[1], reversed: false),
          DrawnCard(card: deck[2], reversed: false),
        ],
      );
      expect(await service.hasSavedReading(), isTrue);

      await service.clear();

      expect(await service.hasSavedReading(), isFalse);
      expect(await service.load(), isNull);
    });
  });
}
