import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_spread.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/reading_screen.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';

const _singleCardFixture = '''
[
  {
    "id": "le_mat",
    "number": 0,
    "name": "Le Mat",
    "image_path": null,
    "keywords_upright": ["liberté", "élan"],
    "keywords_reversed": ["dispersion"],
    "meaning_upright": "Un pas neuf, simple et léger.",
    "meaning_reversed": "Dispersion à recadrer.",
    "love": "Souffle frais.",
    "work": "Idée à oser.",
    "advice": "Faire le premier pas.",
    "warning": "Distinguer élan et fuite.",
    "short_message": "Un pas neuf.",
    "share_message": "J'ai tiré Le Mat.",
    "tags": ["commencement"]
  }
]
''';

Widget _wrap(Widget child, TarotRepository repo, TarotDrawService service) {
  return MaterialApp(
    home: TarotScope(
      repository: repo,
      drawService: service,
      child: child,
    ),
  );
}

void main() {
  group('ReadingScreen', () {
    testWidgets('shows idle state with reveal CTA on mount', (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final service =
          TarotDrawService(repository: repo, random: Random(0));

      await tester.pumpWidget(
        _wrap(
          const ReadingScreen(spread: TarotSpread.single),
          repo,
          service,
        ),
      );

      expect(find.text('Tirage du jour'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsOneWidget);
      expect(find.text('Le Mat'), findsNothing);
    });

    testWidgets('reveals a drawn card after tapping the CTA',
        (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final service =
          TarotDrawService(repository: repo, random: Random(0));

      await tester.pumpWidget(
        _wrap(
          const ReadingScreen(spread: TarotSpread.single),
          repo,
          service,
        ),
      );

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(find.text('Révéler le tirage'), findsNothing);
      expect(find.text('Le Mat'), findsOneWidget);
      expect(find.text('Un pas neuf.'), findsOneWidget);
    });
  });
}
