import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_spread.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';

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

void main() {
  group('TarotDrawService', () {
    test('draws one card for the single spread', () async {
      final repo = TarotRepository(loader: (_) async => _buildFixture(22));
      final service =
          TarotDrawService(repository: repo, random: Random(42));

      final result = await service.draw(TarotSpread.single);

      expect(result, hasLength(1));
    });

    test('draws three distinct cards for the three-card spread', () async {
      final repo = TarotRepository(loader: (_) async => _buildFixture(22));
      final service =
          TarotDrawService(repository: repo, random: Random(7));

      final result = await service.draw(TarotSpread.threeCards);

      expect(result, hasLength(3));
      final ids = result.map((d) => d.card.id).toSet();
      expect(ids, hasLength(3), reason: 'cards must be unique within a draw');
    });

    test('throws when deck is too small', () async {
      final repo = TarotRepository(loader: (_) async => _buildFixture(2));
      final service = TarotDrawService(repository: repo);

      expect(
        () => service.draw(TarotSpread.threeCards),
        throwsA(isA<StateError>()),
      );
    });

    test('seeded random yields deterministic results', () async {
      final repoA = TarotRepository(loader: (_) async => _buildFixture(22));
      final repoB = TarotRepository(loader: (_) async => _buildFixture(22));
      final a = TarotDrawService(repository: repoA, random: Random(123));
      final b = TarotDrawService(repository: repoB, random: Random(123));

      final ra = await a.draw(TarotSpread.threeCards);
      final rb = await b.draw(TarotSpread.threeCards);

      for (var i = 0; i < ra.length; i++) {
        expect(ra[i].card.id, rb[i].card.id);
        expect(ra[i].reversed, rb[i].reversed);
      }
    });
  });
}
