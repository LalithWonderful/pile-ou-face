import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/reading_intent.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_spread.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/reading_screen.dart';
import 'package:pile_ou_face/features/tarot/services/app_data_reset_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
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
    "money": "Vérifie avant d'engager.",
    "advice": "Faire le premier pas.",
    "warning": "Distinguer élan et fuite.",
    "short_message": "Un pas neuf.",
    "share_message": "J'ai tiré Le Mat.",
    "tags": ["commencement"]
  }
]
''';

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
    "spread_meanings": {
      "where_you_are": "Position 1 de la carte A.",
      "current_energy": "Position 2 de la carte A.",
      "advice": "Position 3 de la carte A."
    },
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
    "spread_meanings": {
      "where_you_are": "Position 1 de la carte B.",
      "current_energy": "Position 2 de la carte B.",
      "advice": "Position 3 de la carte B."
    },
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
    "spread_meanings": {
      "where_you_are": "Position 1 de la carte C.",
      "current_energy": "Position 2 de la carte C.",
      "advice": "Position 3 de la carte C."
    },
    "tags": ["tag-c"]
  }
]
''';

Widget _wrap({
  required Widget child,
  required TarotRepository repository,
  required TarotDrawService drawService,
  required DailyReadingService dailyService,
  DailyQuotaService? quotaService,
  AppDataResetService? resetService,
}) {
  return MaterialApp(
    home: TarotScope(
      repository: repository,
      drawService: drawService,
      dailyService: dailyService,
      quotaService: quotaService ?? DailyQuotaService(),
      resetService: resetService ?? AppDataResetService(),
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

    testWidgets('three-card spread does not expose the share button',
        (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(spread: TarotSpread.threeCards),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(find.text('Partager ce message'), findsNothing);
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
      expect(find.text('À toi d’interpréter.'), findsOneWidget);
      expect(find.text('Partager ce message'), findsNothing);
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

    testWidgets('exposes the share button once the message is revealed',
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

      await tester.scrollUntilVisible(
        find.text('Partager ce message'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Partager ce message'), findsOneWidget);
    });

    testWidgets('reveal CTA flips to a loading label as soon as it is tapped',
        (tester) async {
      // A completer-backed loader suspends the async chain so that the
      // transient loading state stays visible long enough to assert on.
      final loaderCompleter = Completer<String>();
      final repo =
          TarotRepository(loader: (_) => loaderCompleter.future);
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
      await tester.pump();

      // Visual double-tap protection: the CTA is replaced by the loading
      // label, so a second tap on the original label cannot fire a second
      // draw.
      expect(find.text('Révéler mon message'), findsNothing);
      expect(find.text('Un instant…'), findsOneWidget);

      loaderCompleter.complete(_singleCardFixture);
      await tester.pumpAndSettle();
      expect(find.text('Le Mat'), findsOneWidget);
    });

    testWidgets('surfaces a SnackBar when sharing fails', (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(
        repository: repo,
        random: Random(0),
        clock: () => DateTime(2026, 5, 15),
      );

      Future<void> throwingInvoker(String _) async {
        throw Exception('share unavailable in test');
      }

      await tester.pumpWidget(_wrap(
        child: ReadingScreen(
          isDaily: true,
          shareInvoker: throwingInvoker,
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      await tester.tap(find.text('Révéler mon message'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Partager ce message'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Partager ce message'));
      await tester.pumpAndSettle();

      expect(find.text('Le partage n’a pas pu se lancer.'), findsOneWidget);
      // Button has returned to its idle state, not stuck on "Un instant…".
      expect(find.text('Partager ce message'), findsOneWidget);
    });

    testWidgets('daily mode is not affected by quota service', (tester) async {
      SharedPreferences.setMockInitialValues({
        'quota.daily_intent_counters':
            '{"date":"2026-05-15","counters":{"general":2,"love":2,"work":2,"money":2}}',
      });
      final quotaService = DailyQuotaService(
        clock: () => DateTime(2026, 5, 15),
      );
      final repo = TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(
        repository: repo,
        random: Random(0),
        clock: () => DateTime(2026, 5, 15),
      );

      await tester.pumpWidget(_wrap(
        child: ReadingScreen(
          isDaily: true,
          shareInvoker: (String _) async {},
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
        quotaService: quotaService,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Révéler mon message'));
      await tester.pumpAndSettle();

      expect(find.text('Le Mat'), findsOneWidget);
      expect(find.text('Mon message du jour'), findsOneWidget);
    });

    testWidgets('daily mode does not show quota hint after reveal',
        (tester) async {
      final repo = TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(
        repository: repo,
        random: Random(0),
        clock: () => DateTime(2026, 5, 15),
      );

      await tester.pumpWidget(_wrap(
        child: ReadingScreen(
          isDaily: true,
          shareInvoker: (String _) async {},
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Révéler mon message'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Il te reste'), findsNothing);
      expect(find.textContaining('Laisse ce message infuser'), findsNothing);
    });
  });

  group('ReadingScreen (responsiveness)', () {
    Future<void> noopInvoker(String _) async {}

    testWidgets(
        'daily mode renders and exposes a scrollable share button on '
        'a 320x568 viewport', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(
        repository: repo,
        random: Random(0),
        clock: () => DateTime(2026, 5, 15),
      );

      await tester.pumpWidget(_wrap(
        child: ReadingScreen(
          isDaily: true,
          shareInvoker: noopInvoker,
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      await tester.tap(find.text('Révéler mon message'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Le Mat'), findsOneWidget);

      // Share CTA must remain reachable via scroll on a narrow screen.
      await tester.scrollUntilVisible(
        find.text('Partager ce message'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Partager ce message'), findsOneWidget);
    });

    testWidgets('three-card spread renders on a 320x568 viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo =
          TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(spread: TarotSpread.threeCards),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));
      await tester.pumpAndSettle();

      // The idle CTA may sit below the viewport on a narrow phone; the
      // _IdleState is now scrollable so it can be reached.
      await tester.scrollUntilVisible(
        find.text('Révéler le tirage'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // First slot is rendered eagerly by the ListView; the others come
      // through scroll, which is the expected behaviour on a narrow
      // phone. Position chip uses the product-voice wording.
      expect(find.text('Là où tu en es'), findsOneWidget);
    });

    testWidgets('three-card navigation resets scroll to the top',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo =
          TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(spread: TarotSpread.threeCards),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Révéler le tirage'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;

      await tester.scrollUntilVisible(
        find.text('L’énergie du moment'),
        200,
        scrollable: scrollable,
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
      await tester.tap(find.text('L’énergie du moment'));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        0,
      );

      await tester.scrollUntilVisible(
        find.text('Le conseil'),
        200,
        scrollable: scrollable,
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
      await tester.tap(find.text('Le conseil'));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        0,
      );

      await tester.scrollUntilVisible(
        find.text('L’énergie du moment'),
        200,
        scrollable: scrollable,
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
      await tester.tap(find.text('L’énergie du moment'));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('daily mode renders at 1.4x text scaling', (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _singleCardFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(
        repository: repo,
        random: Random(0),
        clock: () => DateTime(2026, 5, 15),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.4),
          ),
          child: _wrap(
            child: ReadingScreen(
              isDaily: true,
              shareInvoker: noopInvoker,
            ),
            repository: repo,
            drawService: drawService,
            dailyService: dailyService,
          ),
        ),
      );

      await tester.tap(find.text('Révéler mon message'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Le Mat'), findsOneWidget);
    });
  });

  group('ReadingScreen (intent-based)', () {
    testWidgets(
        'love intent uses spread_meanings as main body and surfaces the '
        'EN AMOUR domain complement', (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.love),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      // AppBar reflects the intent title.
      expect(find.text('Question d’amour'), findsOneWidget);

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      // Main body now comes from spread_meanings.where_you_are
      // (validated card in slot 0). The general meaning must not be
      // the main body in this mode.
      expect(find.textContaining('Position 1 de la carte'),
          findsAtLeastNWidgets(1));
      expect(find.text('Sens droit A.'), findsNothing);

      // The love body is preserved as the domain complement, with the
      // "EN AMOUR" small-caps label introduced for the validated card.
      expect(find.text('EN AMOUR'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Amour'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'general intent on a validated card renders spread_meanings as '
        'main body, without domain complement', (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.general),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      // Position-specific body is rendered.
      expect(find.textContaining('Position 1 de la carte'),
          findsAtLeastNWidgets(1));
      // No domain complement label appears in general mode.
      expect(find.text('EN AMOUR'), findsNothing);
      expect(find.text('AU TRAVAIL'), findsNothing);
      expect(find.text('CÔTÉ ARGENT'), findsNothing);
    });

    testWidgets('money intent renders the financial-advice footer',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo =
          TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.money),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      expect(find.text('Question d’argent'), findsOneWidget);

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      // The discreet footer disclaimer is reached via scroll on a
      // narrow viewport.
      await tester.scrollUntilVisible(
        find.text('Ne remplace pas un conseil financier.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Ne remplace pas un conseil financier.'),
        findsOneWidget,
      );
    });

    testWidgets('general intent does not render the money footer',
        (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.general),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ne remplace pas un conseil financier.'),
        findsNothing,
      );
    });

    testWidgets(
        'quota exhausted on mount shows gentle unavailable view',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'quota.daily_intent_counters':
            '{"date":"2026-05-15","counters":{"love":2}}',
      });
      final quotaService = DailyQuotaService(
        clock: () => DateTime(2026, 5, 15),
      );
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.love),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
        quotaService: quotaService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Révéler le tirage'), findsNothing);
      expect(
        find.text('Tu as déjà tiré deux messages sur l’amour aujourd’hui.'),
        findsOneWidget,
      );
      expect(find.text('Revenir à l\'accueil'), findsOneWidget);
    });

    testWidgets(
        'intent with remaining quota reveals normally and consumes one',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final quotaService = DailyQuotaService(
        clock: () => DateTime(2026, 5, 15),
      );
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.love),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
        quotaService: quotaService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Révéler le tirage'), findsOneWidget);

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(find.text('Question d’amour'), findsOneWidget);
      expect(find.text('Là où tu en es'), findsOneWidget);
      expect(await quotaService.remaining(ReadingIntent.love), 1);
    });

    testWidgets(
        'tryConsume false during tap shows gentle unavailable view',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'quota.daily_intent_counters':
            '{"date":"2026-05-15","counters":{"love":1}}',
      });
      final quotaService = DailyQuotaService(
        clock: () => DateTime(2026, 5, 15),
      );
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.love),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
        quotaService: quotaService,
      ));
      await tester.pump(); // exécute checkQuota initial

      // Consommer le dernier tirage en dehors de l'UI
      await quotaService.tryConsume(ReadingIntent.love);

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(find.text('Révéler le tirage'), findsNothing);
      expect(
        find.text('Tu as déjà tiré deux messages sur l’amour aujourd’hui.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'after first intent draw shows remaining hint with one left',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final quotaService = DailyQuotaService(
        clock: () => DateTime(2026, 5, 15),
      );
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.love),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
        quotaService: quotaService,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(find.text('Là où tu en es'), findsOneWidget);
      expect(
        find.text('Il te reste un tirage amour aujourd’hui.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'after second intent draw shows exhausted hint and no redraw button',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'quota.daily_intent_counters':
            '{"date":"2026-05-15","counters":{"love":1}}',
      });
      final quotaService = DailyQuotaService(
        clock: () => DateTime(2026, 5, 15),
      );
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService =
          TarotDrawService(repository: repo, random: Random(0));
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: const ReadingScreen(intent: ReadingIntent.love),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
        quotaService: quotaService,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Révéler le tirage'));
      await tester.pumpAndSettle();

      expect(find.text('Là où tu en es'), findsOneWidget);
      expect(
        find.textContaining('Laisse ce message infuser'),
        findsOneWidget,
      );
      expect(
        find.textContaining('demain pour un nouveau tirage amour'),
        findsOneWidget,
      );
      expect(find.text('Faire un autre tirage'), findsNothing);
    });
  });
}
