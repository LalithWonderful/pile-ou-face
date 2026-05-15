import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('major_arcana.json integrity', () {
    late List<TarotCard> cards;

    setUpAll(() async {
      cards = await TarotRepository().loadMajorArcana();
    });

    test('contains the 22 major arcana', () {
      expect(cards, hasLength(22));
    });

    test('numbers cover 0..21 without duplicates', () {
      final numbers = cards.map((c) => c.number).toList()..sort();
      expect(numbers, List<int>.generate(22, (i) => i));
    });

    test('ids are unique', () {
      final ids = cards.map((c) => c.id).toSet();
      expect(ids, hasLength(22));
    });

    test('critical text fields are non-empty for every card', () {
      for (final c in cards) {
        expect(c.name, isNotEmpty, reason: '${c.id}.name');
        expect(c.meaningUpright.trim(), isNotEmpty,
            reason: '${c.id}.meaning_upright');
        expect(c.meaningReversed.trim(), isNotEmpty,
            reason: '${c.id}.meaning_reversed');
        expect(c.love.trim(), isNotEmpty, reason: '${c.id}.love');
        expect(c.work.trim(), isNotEmpty, reason: '${c.id}.work');
        expect(c.money.trim(), isNotEmpty, reason: '${c.id}.money');
        expect(c.advice.trim(), isNotEmpty, reason: '${c.id}.advice');
        expect(c.warning.trim(), isNotEmpty, reason: '${c.id}.warning');
        expect(c.shortMessage.trim(), isNotEmpty,
            reason: '${c.id}.short_message');
        expect(c.shareMessage.trim(), isNotEmpty,
            reason: '${c.id}.share_message');
      }
    });

    test('keyword arrays are non-empty for every card', () {
      for (final c in cards) {
        expect(c.keywordsUpright, isNotEmpty,
            reason: '${c.id}.keywords_upright');
        expect(c.keywordsReversed, isNotEmpty,
            reason: '${c.id}.keywords_reversed');
        expect(c.tags, isNotEmpty, reason: '${c.id}.tags');
      }
    });

    test('all 22 major arcana now carry spread_meanings (Lot 15: 22/22)',
        () {
      for (final c in cards) {
        expect(c.spreadMeanings, isNotNull,
            reason: '${c.id} must carry spread_meanings');
      }
    });

    test(
        'when spread_meanings is present, all three position fields are '
        'non-empty', () {
      for (final c in cards) {
        final meanings = c.spreadMeanings;
        if (meanings == null) continue;
        expect(meanings.whereYouAre.trim(), isNotEmpty,
            reason: '${c.id}.spread_meanings.where_you_are');
        expect(meanings.currentEnergy.trim(), isNotEmpty,
            reason: '${c.id}.spread_meanings.current_energy');
        expect(meanings.advice.trim(), isNotEmpty,
            reason: '${c.id}.spread_meanings.advice');
      }
    });

    test('all cards carry a non-null, non-empty imagePath', () {
      for (final c in cards) {
        expect(c.imagePath, isNotNull, reason: '${c.id} must have imagePath');
        expect(c.imagePath, isNotEmpty,
            reason: '${c.id} imagePath must not be empty');
      }
    });
  });
}
