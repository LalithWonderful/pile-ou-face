import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_spread.dart';

void main() {
  group('TarotSpread', () {
    test('single spread keeps a one-position layout', () {
      const spread = TarotSpread.single;
      expect(spread.cardCount, 1);
      expect(spread.positions, hasLength(1));
    });

    test('threeCards spread uses introspective product-voice labels', () {
      const spread = TarotSpread.threeCards;
      expect(spread.cardCount, 3);
      expect(
        spread.positions,
        ['Là où tu en es', 'L’énergie du moment', 'Le conseil'],
      );
      expect(spread.label, 'Éclairer une situation');
    });

    test('threeCards no longer exposes any of the previously retired labels',
        () {
      const spread = TarotSpread.threeCards;
      const retired = <String>[
        // Lot 3 era (passé / présent / futur).
        'Passé', 'Présent', 'Futur',
        // Lot 4-9 era (Situation / Énergie / Conseil bare).
        'Situation', 'Énergie', 'Conseil',
      ];
      for (final label in retired) {
        expect(
          spread.positions.contains(label),
          isFalse,
          reason: 'retired label "$label" should have been replaced',
        );
      }
    });
  });
}
