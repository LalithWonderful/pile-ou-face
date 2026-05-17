import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/reading_intent.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/three_card_choice_screen.dart';
import 'package:pile_ou_face/features/tarot/services/app_data_reset_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/last_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Synthesises a fixture matching the production deck size (22 cards),
/// without dragging the full editorial asset into the test. Every card
/// is unique and gets the minimum schema a [TarotCard.fromJson] expects.
String _buildArcanaFixture(int count) {
  final cards = <Map<String, dynamic>>[
    for (var i = 0; i < count; i++)
      <String, dynamic>{
        'id': 'card_$i',
        'number': i,
        'name': 'Carte $i',
        'image_path': null,
        'keywords_upright': <String>['k$i'],
        'keywords_reversed': <String>['k${i}r'],
        'meaning_upright': 'Sens droit $i.',
        'meaning_reversed': 'Sens inversé $i.',
        'love': 'Amour $i.',
        'work': 'Travail $i.',
        'money': 'Argent $i.',
        'advice': 'Conseil $i.',
        'warning': 'Avertissement $i.',
        'short_message': 'Court $i.',
        'share_message': 'Partage $i.',
        'spread_meanings': <String, String>{
          'where_you_are': 'Position 1 de la carte $i.',
          'current_energy': 'Position 2 de la carte $i.',
          'advice': 'Position 3 de la carte $i.',
        },
        'tags': <String>['tag$i'],
      },
  ];
  return jsonEncode(cards);
}

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
  LastReadingService? lastReadingService,
}) {
  // Mirror production layering — TarotScope sits ABOVE MaterialApp so
  // pushed routes (e.g. the ReadingScreen launched after the third pick)
  // can still resolve the scope. The existing per-screen tests are fine
  // either way because they do not navigate.
  return TarotScope(
    repository: repository,
    drawService: drawService,
    dailyService: dailyService,
    quotaService: quotaService ?? DailyQuotaService(),
    resetService: resetService ?? AppDataResetService(),
    lastReadingService:
        lastReadingService ?? LastReadingService(repository: repository),
    child: MaterialApp(home: child),
  );
}

Future<void> _tapPoolCardAt(WidgetTester tester, int index) async {
  // Picked cards stay in the widget tree (faded out) so positional
  // matching by widget order would re-tap the same slot. The screen
  // exposes a stable key per pool index for this reason.
  await tester.tap(
    find.byKey(ThreeCardChoiceScreen.poolCardKey(index)),
    warnIfMissed: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ThreeCardChoiceScreen', () {
    testWidgets('renders the ritual headline, subtitle and 3 slot labels',
        (tester) async {
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: ThreeCardChoiceScreen(
          intent: ReadingIntent.love,
          random: Random(0),
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choisis tes 3 cartes'), findsOneWidget);
      expect(
        find.text('La bonne carte est celle qui t’appelle.'),
        findsOneWidget,
      );
      expect(find.text('LÀ OÙ TU EN ES'), findsOneWidget);
      expect(find.text('L’ÉNERGIE DU MOMENT'), findsOneWidget);
      expect(find.text('LE CONSEIL'), findsOneWidget);
      expect(find.text('Carte 1 sur 3'), findsOneWidget);
    });

    testWidgets(
        'picking 3 cards consumes one quota and navigates to the reading',
        (tester) async {
      final quotaService = DailyQuotaService(
        clock: () => DateTime(2026, 5, 17),
      );
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: ThreeCardChoiceScreen(
          intent: ReadingIntent.love,
          random: Random(0),
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
        quotaService: quotaService,
      ));
      await tester.pumpAndSettle();

      // First pick: consumes one quota and fills slot 1.
      await _tapPoolCardAt(tester, 0);
      await tester.pumpAndSettle();
      expect(await quotaService.remaining(ReadingIntent.love), 1);
      expect(find.text('Carte 2 sur 3'), findsOneWidget);

      // Second pick: fills slot 2; quota unchanged (only first pick consumes).
      await _tapPoolCardAt(tester, 1);
      await tester.pumpAndSettle();
      expect(await quotaService.remaining(ReadingIntent.love), 1);
      expect(find.text('Carte 3 sur 3'), findsOneWidget);

      // Third pick triggers the "Ton tirage t’attend." pause then the
      // navigation to the reading screen.
      await _tapPoolCardAt(tester, 2);
      await tester.pump();
      expect(find.text('Ton tirage t’attend.'), findsOneWidget);

      await tester.pump(ThreeCardChoiceScreen.transitionDelay);
      await tester.pumpAndSettle();

      // The reading screen replaces the choice screen and renders the
      // first position straight away (no idle CTA).
      expect(find.text('Question d’amour'), findsOneWidget);
      expect(find.text('Là où tu en es'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsNothing);
      // Quota is still at 1 — the reading screen did not double-consume
      // because it received a prepared draw.
      expect(await quotaService.remaining(ReadingIntent.love), 1);

      // The completed reading was persisted before navigating so the
      // home screen can offer "Revoir mon dernier tirage" later.
      final lastReading = LastReadingService(repository: repo);
      final snapshot = await lastReading.load();
      expect(snapshot, isNotNull);
      expect(snapshot!.intent, ReadingIntent.love);
      expect(snapshot.cards, hasLength(3));
    });

    testWidgets(
        'shows the quota exhausted state when quota is already at 0',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'quota.daily_intent_counters':
            '{"date":"2026-05-17","counters":{"love":2}}',
      });
      final quotaService = DailyQuotaService(
        clock: () => DateTime(2026, 5, 17),
      );
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: ThreeCardChoiceScreen(
          intent: ReadingIntent.love,
          random: Random(0),
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
        quotaService: quotaService,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choisis tes 3 cartes'), findsNothing);
      expect(
        find.text('Tu as déjà tiré deux messages sur l’amour aujourd’hui.'),
        findsOneWidget,
      );
      expect(find.text('Revenir à l\'accueil'), findsOneWidget);
    });

    testWidgets(
        'with a 22-card deck, the pool exposes 22 tappable candidate slots',
        (tester) async {
      // Wider canvas so the full fan (≈ 750 px on standard sizing) is
      // laid out without forcing the test to drive the horizontal
      // scroll just to assert key existence.
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = TarotRepository(loader: (_) async => _buildArcanaFixture(22));
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: ThreeCardChoiceScreen(
          intent: ReadingIntent.general,
          random: Random(0),
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));
      await tester.pumpAndSettle();

      // 22 unique pool keys exist, and exactly 22 of them — there is
      // no key 22 (off-by-one guard).
      for (var i = 0; i < ThreeCardChoiceScreen.poolSize; i++) {
        expect(
          find.byKey(ThreeCardChoiceScreen.poolCardKey(i)),
          findsOneWidget,
          reason: 'pool card $i should be present',
        );
      }
      expect(
        find.byKey(ThreeCardChoiceScreen.poolCardKey(22)),
        findsNothing,
      );
    });

    testWidgets(
        'small deck of 3 cards clamps the pool to min(poolSize, deck.length)',
        (tester) async {
      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: ThreeCardChoiceScreen(
          intent: ReadingIntent.love,
          random: Random(0),
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(ThreeCardChoiceScreen.poolCardKey(0)), findsOneWidget);
      expect(find.byKey(ThreeCardChoiceScreen.poolCardKey(1)), findsOneWidget);
      expect(find.byKey(ThreeCardChoiceScreen.poolCardKey(2)), findsOneWidget);
      expect(find.byKey(ThreeCardChoiceScreen.poolCardKey(3)), findsNothing);
    });

    testWidgets('renders without overflow on a 320x568 viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = TarotRepository(loader: (_) async => _threeCardsFixture);
      final drawService = TarotDrawService(repository: repo);
      final dailyService = DailyReadingService(repository: repo);

      await tester.pumpWidget(_wrap(
        child: ThreeCardChoiceScreen(
          intent: ReadingIntent.general,
          random: Random(0),
        ),
        repository: repo,
        drawService: drawService,
        dailyService: dailyService,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Choisis tes 3 cartes'), findsOneWidget);
    });
  });
}
