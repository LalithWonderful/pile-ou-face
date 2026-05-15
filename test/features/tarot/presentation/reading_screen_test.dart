import 'dart:async';
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
    "advice": "Conseil C.",
    "warning": "Avertissement C.",
    "short_message": "Court C.",
    "share_message": "Partage C.",
    "tags": ["tag-c"]
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
      expect(find.text('Libre à toi de l’interpréter.'), findsOneWidget);
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
      // phone.
      expect(find.text('SITUATION'), findsOneWidget);
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
}
