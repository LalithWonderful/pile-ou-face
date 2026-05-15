import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_spread.dart';

void main() {
  group('TarotSpread', () {
    test('single spread keeps a one-position layout', () {
      const spread = TarotSpread.single;
      expect(spread.cardCount, 1);
      expect(spread.positions, hasLength(1));
    });

    test('threeCards spread uses introspective labels', () {
      const spread = TarotSpread.threeCards;
      expect(spread.cardCount, 3);
      expect(spread.positions, ['Situation', 'Énergie', 'Conseil']);
    });

    test('threeCards no longer uses passé/présent/futur', () {
      const spread = TarotSpread.threeCards;
      for (final legacy in ['Passé', 'Présent', 'Futur']) {
        expect(
          spread.positions.contains(legacy),
          isFalse,
          reason: 'legacy label "$legacy" should have been replaced',
        );
      }
    });
  });
}
