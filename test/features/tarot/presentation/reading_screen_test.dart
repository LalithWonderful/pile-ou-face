import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_spread.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/reading_screen.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Widget _wrap({
  required Widget child,
  required TarotRepository repository,
  required TarotDrawService drawService,
  required DailyReadingService dailyService,
}) {
  return MaterialApp(
    home: TarotScope(
      repository: repository,
      drawService: drawService,
      dailyService: dailyService,
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ReadingScreen (free draw)', () {
    testWidgets('shows idle state with reveal CTA on mount', (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(spread: TarotSpread.single),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      expect(find.text('Tirage du jour'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsOneWidget);
      expect(find.text('Le Mat'), findsNothing);
    });

    testWidgets('reveals a drawn card after tapping the CTA',
        (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(spread: TarotSpread.single),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(find.text('Révéler le tirage'), findsNothing);
      expect(find.text('Le Mat'), findsOneWidget);
      expect(find.text('Un pas neuf.'), findsOneWidget);
    });
  });

  group('ReadingScreen (daily mode)', () {
    testWidgets('uses the daily message wording in idle state',
        (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(
        repository: repo,
        random: Random(0),
        clock: () => DateTime(2026, 5, 15),
      );

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(isDaily: true),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      expect(find.text('Mon message du jour'), findsOneWidget);
      expect(find.text('Révéler mon message'), findsOneWidget);
      expect(find.text('Libre à toi de l’interpréter.'), findsOneWidget);
    });

    testWidgets('reveals the daily card via DailyReadingService',
        (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(
        repository: repo,
        random: Random(0),
        clock: () => DateTime(2026, 5, 15),
      );

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(isDaily: true),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      await tester.tap(find.text('Révéler mon message'));
      await tester.pumpAndSettle();

      expect(find.text('Le Mat'), findsOneWidget);
      expect(find.text('Révéler mon message'), findsNothing);

      // The reading is now persisted for today.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(DailyReadingService.dateKey), '2026-05-15');
      expect(prefs.getString(DailyReadingService.cardIdKey), 'le_mat');
    });
  });
}
