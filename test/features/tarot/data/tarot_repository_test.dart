import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';

const _fixture = '''
[
  {
    "id": "le_mat",
    "number": 0,
    "name": "Le Mat",
    "image_path": null,
    "keywords_upright": ["liberté", "commencement"],
    "keywords_reversed": ["dispersion"],
    "meaning_upright": "Un pas neuf.",
    "meaning_reversed": "Dispersion.",
    "love": "Souffle neuf.",
    "work": "Idée fraîche.",
    "advice": "Oser un premier pas.",
    "warning": "Ne pas confondre élan et fuite.",
    "short_message": "Un pas neuf.",
    "share_message": "J'ai tiré Le Mat.",
    "tags": ["commencement", "liberté"]
  },
  {
    "id": "le_bateleur",
    "number": 1,
    "name": "Le Bateleur",
    "image_path": null,
    "keywords_upright": ["initiative"],
    "keywords_reversed": ["hésitation"],
    "meaning_upright": "Passer à l'action.",
    "meaning_reversed": "Hésitation.",
    "love": "Authenticité.",
    "work": "Saisir une opportunité.",
    "advice": "Commencer modestement.",
    "warning": "Ne pas trop promettre.",
    "short_message": "Outils en main.",
    "share_message": "J'ai tiré Le Bateleur.",
    "tags": ["initiative"]
  }
]
''';

void main() {
  group('TarotRepository', () {
    test('parses JSON into TarotCard list with enriched fields', () async {
      final repo = TarotRepository(loader: (_) async => _fixture);
      final cards = await repo.loadMajorArcana();

      expect(cards, hasLength(2));
      final mat = cards.first;
      expect(mat.id, 'le_mat');
      expect(mat.number, 0);
      expect(mat.name, 'Le Mat');
      expect(mat.imagePath, isNull);
      expect(mat.keywordsUpright, ['liberté', 'commencement']);
      expect(mat.keywordsReversed, ['dispersion']);
      expect(mat.meaningUpright, 'Un pas neuf.');
      expect(mat.meaningReversed, 'Dispersion.');
      expect(mat.love, 'Souffle neuf.');
      expect(mat.work, 'Idée fraîche.');
      expect(mat.advice, 'Oser un premier pas.');
      expect(mat.warning, 'Ne pas confondre élan et fuite.');
      expect(mat.shortMessage, 'Un pas neuf.');
      expect(mat.shareMessage, "J'ai tiré Le Mat.");
      expect(mat.tags, ['commencement', 'liberté']);
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
