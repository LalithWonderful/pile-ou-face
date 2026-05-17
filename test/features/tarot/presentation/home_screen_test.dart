import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/pile_ou_face_app.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/reading_intent.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/home_screen.dart';
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

/// The invisible 110x110 square that wraps the home logo and hosts the
/// debug-only sustained-press Listener. Tests target this surface rather
/// than the inner Image so the assertions match the user's tappable
/// region exactly.
final Finder _logoTouchTargetFinder = find.byKey(homeLogoDebugPressTargetKey);

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
        '"Une situation" routes into the 3-card choice flow',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      // The compact button labels are visible; the long retired ones
      // must not appear on the home anymore.
      expect(find.text('Je me pose une question d’amour'), findsNothing);
      expect(find.text('Éclairer une situation'), findsNothing);

      await tester.tap(find.text('Une situation'));
      await tester.pumpAndSettle();

      // AppBar uses the intent title, and the choice screen sits in
      // front of the existing reading screen — no "Révéler le tirage"
      // CTA on the new step.
      expect(find.text('Je me pose une question'),
          findsAtLeastNWidgets(1));
      expect(find.text('Choisis tes 3 cartes'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsNothing);
    });

    testWidgets(
        '"L’amour" routes into the 3-card choice flow',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('L’amour'));
      await tester.pumpAndSettle();

      expect(find.text('Question d’amour'), findsOneWidget);
      expect(find.text('Choisis tes 3 cartes'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsNothing);
    });

    testWidgets(
        '"Le travail" routes into the 3-card choice flow',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('Le travail'));
      await tester.pumpAndSettle();

      expect(find.text('Question de travail'), findsOneWidget);
      expect(find.text('Choisis tes 3 cartes'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsNothing);
    });

    testWidgets(
        '"L’argent" routes into the 3-card choice flow',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('L’argent'));
      await tester.pumpAndSettle();

      expect(find.text('Question d’argent'), findsOneWidget);
      expect(find.text('Choisis tes 3 cartes'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsNothing);
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
        '5 taps on the logo reset quotas in debug mode',
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

      for (var i = 0; i < 5; i++) {
        await tester.tap(_logoTouchTargetFinder);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quotas de test réinitialisés.'), findsOneWidget);
      expect(await quotaService.remaining(ReadingIntent.general), 2);
    });

    testWidgets(
        '4 taps on the logo do not reset quotas',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyQuotaService.prefsKey:
            '{"date":"${_todayKey()}","counters":{"general":2}}',
      });

      final quotaService = DailyQuotaService();
      expect(await quotaService.remaining(ReadingIntent.general), 0);

      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.tap(_logoTouchTargetFinder);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quotas de test réinitialisés.'), findsNothing);
      expect(await quotaService.remaining(ReadingIntent.general), 0);
    });

    testWidgets(
        '5 taps on the title text do not reset quotas (gesture is logo-only)',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyQuotaService.prefsKey:
            '{"date":"${_todayKey()}","counters":{"general":2}}',
      });

      final quotaService = DailyQuotaService();
      expect(await quotaService.remaining(ReadingIntent.general), 0);

      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));
      await tester.pumpAndSettle();

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Pile ou Face'));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Quotas de test réinitialisés.'), findsNothing);
      expect(await quotaService.remaining(ReadingIntent.general), 0);
    });

    testWidgets(
        'tap counter resets after the 3-second window so partial runs cannot accumulate',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyQuotaService.prefsKey:
            '{"date":"${_todayKey()}","counters":{"general":2}}',
      });

      final quotaService = DailyQuotaService();
      expect(await quotaService.remaining(ReadingIntent.general), 0);

      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));
      await tester.pumpAndSettle();

      // Tap 4 times — one short of the threshold.
      for (var i = 0; i < 4; i++) {
        await tester.tap(_logoTouchTargetFinder);
        await tester.pump();
      }
      // Let the 3-second window expire, then tap 4 more times.
      await tester.pump(const Duration(seconds: 4));
      for (var i = 0; i < 4; i++) {
        await tester.tap(_logoTouchTargetFinder);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 100));

      // 8 taps total but the counter reset at second 3, so we are at 4
      // taps in the current window — no reset.
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
