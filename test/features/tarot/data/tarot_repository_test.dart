import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';

const _fixture = '''
[
  {
    "id": "le_mat",
    "number": 0,
    "name": "Le Mat",
    "keywords": ["liberté", "commencement"],
    "uprightMeaning": "Un nouveau départ.",
    "reversedMeaning": "Imprudence."
  },
  {
    "id": "le_bateleur",
    "number": 1,
    "name": "Le Bateleur",
    "keywords": ["initiative"],
    "uprightMeaning": "Passage à l'action.",
    "reversedMeaning": "Hésitation."
  }
]
''';

void main() {
  group('TarotRepository', () {
    test('parses JSON into TarotCard list', () async {
      final repo = TarotRepository(loader: (_) async => _fixture);
      final cards = await repo.loadMajorArcana();

      expect(cards, hasLength(2));
      expect(cards.first.id, 'le_mat');
      expect(cards.first.name, 'Le Mat');
      expect(cards.first.keywords, ['liberté', 'commencement']);
      expect(cards.first.uprightMeaning, 'Un nouveau départ.');
      expect(cards[1].number, 1);
    });

    test('caches results after first load', () async {
      var calls = 0;
      final repo = TarotRepository(
        loader: (_) async {
          calls++;
          return _fixture;
        },
      );

      await repo.loadMajorArcana();
      await repo.loadMajorArcana();

      expect(calls, 1);
    });

    test('clearCache forces a reload', () async {
      var calls = 0;
      final repo = TarotRepository(
        loader: (_) async {
          calls++;
          return _fixture;
        },
      );

      await repo.loadMajorArcana();
      repo.clearCache();
      await repo.loadMajorArcana();

      expect(calls, 2);
    });
  });
}
