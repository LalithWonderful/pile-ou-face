import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/pile_ou_face_app.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/reading_intent.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _emptyFixture = '[]';

const _threeCardsFixture = '''
[
  {
    "id": "carte_a",
    "number": 0,
    "name": "Carte A",
    "image_path": null,
    "keywords_upright": ["a"],
    "keywords_reversed": ["a-inv"],
    "meaning_upright": "Sens droit A.",
    "meaning_reversed": "Sens inversé A.",
    "love": "Amour A.",
    "work": "Travail A.",
    "money": "Argent A.",
    "advice": "Conseil A.",
    "warning": "Avertissement A.",
    "short_message": "Court A.",
    "share_message": "Partage A.",
    "tags": ["tag-a"]
  },
  {
    "id": "carte_b",
    "number": 1,
    "name": "Carte B",
    "image_path": null,
    "keywords_upright": ["b"],
    "keywords_reversed": ["b-inv"],
    "meaning_upright": "Sens droit B.",
    "meaning_reversed": "Sens inversé B.",
    "love": "Amour B.",
    "work": "Travail B.",
    "money": "Argent B.",
    "advice": "Conseil B.",
    "warning": "Avertissement B.",
    "short_message": "Court B.",
    "share_message": "Partage B.",
    "tags": ["tag-b"]
  },
  {
    "id": "carte_c",
    "number": 2,
    "name": "Carte C",
    "image_path": null,
    "keywords_upright": ["c"],
    "keywords_reversed": ["c-inv"],
    "meaning_upright": "Sens droit C.",
    "meaning_reversed": "Sens inversé C.",
    "love": "Amour C.",
    "work": "Travail C.",
    "money": "Argent C.",
    "advice": "Conseil C.",
    "warning": "Avertissement C.",
    "short_message": "Court C.",
    "share_message": "Partage C.",
    "tags": ["tag-c"]
  }
]
''';

String _todayKey() {
  final d = DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

final Finder _logoFinder = find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName ==
          'assets/tarot/branding/pile_ou_face_logo.png',
);

PileOuFaceApp _buildApp({required String fixture}) {
  final repo = TarotRepository(loader: (_) async => fixture);
  return PileOuFaceApp(
    repository: repo,
    drawService: TarotDrawService(repository: repo),
    dailyService: DailyReadingService(repository: repo),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('HomeScreen navigation', () {
    testWidgets(
        '"Découvrir ton message du jour" opens the daily reading screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));

      await tester.tap(find.text('Découvrir ton message du jour'));
      await tester.pumpAndSettle();

      expect(find.text('Mon message du jour'), findsOneWidget);
      expect(find.text('Révéler mon message'), findsOneWidget);
    });

    testWidgets(
        '"Une situation" opens the general intent reading screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      // The compact button labels are visible; the long retired ones
      // must not appear on the home anymore.
      expect(find.text('Je me pose une question d’amour'), findsNothing);
      expect(find.text('Éclairer une situation'), findsNothing);

      await tester.tap(find.text('Une situation'));
      await tester.pumpAndSettle();

      // AppBar uses the intent title.
      expect(find.text('Je me pose une question'),
          findsAtLeastNWidgets(1));
      expect(find.text('Révéler le tirage'), findsOneWidget);
    });

    testWidgets(
        '"L’amour" opens the love intent screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('L’amour'));
      await tester.pumpAndSettle();

      expect(find.text('Question d’amour'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsOneWidget);
    });

    testWidgets(
        '"Le travail" opens the work intent screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('Le travail'));
      await tester.pumpAndSettle();

      expect(find.text('Question de travail'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsOneWidget);
    });

    testWidgets(
        '"L’argent" opens the money intent screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('L’argent'));
      await tester.pumpAndSettle();

      expect(find.text('Question d’argent'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsOneWidget);
    });

    testWidgets(
        'in debug mode, "Voir les cartes" opens the library screen',
        (tester) async {
      // Tests run in debug mode, so the discreet library link is
      // expected to be visible.
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      // Retired label must not appear.
      expect(find.text('Découvrir les cartes'), findsNothing);

      await tester.tap(find.text('Voir les cartes'));
      await tester.pumpAndSettle();

      expect(find.text('Bibliothèque des cartes'), findsOneWidget);
      expect(find.text('Carte A'), findsOneWidget);
    });

    testWidgets(
        'a 5-second sustained press on the logo resets quotas in debug mode',
        (tester) async {
      // Pre-seed the quota counters as if the user already hit the
      // 2-per-intent daily limit on the "general" intent.
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyQuotaService.prefsKey:
            '{"date":"${_todayKey()}","counters":{"general":2}}',
      });

      final quotaService = DailyQuotaService();
      expect(await quotaService.remaining(ReadingIntent.general), 0);

      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));
      await tester.pumpAndSettle();

      final gesture =
          await tester.startGesture(tester.getCenter(_logoFinder));
      // Hold for the full debug-reset duration. The Timer fires inside
      // this pump window.
      await tester.pump(const Duration(seconds: 5));
      await gesture.up();
      await tester.pump(); // surface the SnackBar
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quotas de test réinitialisés.'), findsOneWidget);
      expect(await quotaService.remaining(ReadingIntent.general), 2);
    });

    testWidgets(
        'releasing the logo before 5 seconds does not reset quotas',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyQuotaService.prefsKey:
            '{"date":"${_todayKey()}","counters":{"general":2}}',
      });

      final quotaService = DailyQuotaService();
      expect(await quotaService.remaining(ReadingIntent.general), 0);

      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));
      await tester.pumpAndSettle();

      final gesture =
          await tester.startGesture(tester.getCenter(_logoFinder));
      // Release well before the 5-second threshold (covers both an
      // accidental tap and a regular long-press around 500 ms).
      await tester.pump(const Duration(seconds: 2));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quotas de test réinitialisés.'), findsNothing);
      expect(await quotaService.remaining(ReadingIntent.general), 0);
    });

    testWidgets(
        'holding the title text does not reset quotas (gesture is logo-only)',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyQuotaService.prefsKey:
            '{"date":"${_todayKey()}","counters":{"general":2}}',
      });

      final quotaService = DailyQuotaService();
      expect(await quotaService.remaining(ReadingIntent.general), 0);

      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));
      await tester.pumpAndSettle();

      final gesture = await tester
          .startGesture(tester.getCenter(find.text('Pile ou Face')));
      // Even a full 5-second hold on the title must not trigger the
      // reset, because the Listener now only covers the logo.
      await tester.pump(const Duration(seconds: 5));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quotas de test réinitialisés.'), findsNothing);
      expect(await quotaService.remaining(ReadingIntent.general), 0);
    });

    testWidgets('settings icon opens the settings screen', (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Politique de confidentialité'), findsOneWidget);
    });
  });

  group('HomeScreen responsiveness', () {
    testWidgets('renders without overflow on a 320x568 viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('C’est le moment de tirer une carte.'),
        findsOneWidget,
      );
    });

    testWidgets('renders without overflow at 1.4x text scaling',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.4),
          ),
          child: _buildApp(fixture: _emptyFixture),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Découvrir ton message du jour'),
        findsOneWidget,
      );
    });
  });
}
