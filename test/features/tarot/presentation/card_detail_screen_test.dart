import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_card.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/card_detail_screen.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/cards_library_screen.dart';
import 'package:pile_ou_face/features/tarot/services/app_data_reset_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';

const _libraryFixture = '''
[
  {
    "id": "carte_a",
    "number": 0,
    "name": "Carte A",
    "image_path": null,
    "keywords_upright": ["alpha", "souffle"],
    "keywords_reversed": ["a-inv"],
    "meaning_upright": "Sens droit A à découvrir.",
    "meaning_reversed": "Sens inversé A à apprivoiser.",
    "love": "Côté relations A.",
    "work": "Côté travail A.",
    "money": "Côté argent A.",
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
    "keywords_upright": ["beta"],
    "keywords_reversed": ["b-inv"],
    "meaning_upright": "Sens droit B.",
    "meaning_reversed": "Sens inversé B.",
    "love": "Côté relations B.",
    "work": "Côté travail B.",
    "money": "Côté argent B.",
    "advice": "Conseil B.",
    "warning": "Avertissement B.",
    "short_message": "Court B.",
    "share_message": "Partage B.",
    "tags": ["tag-b"]
  }
]
''';

const TarotCard _sampleCard = TarotCard(
  id: 'carte_a',
  number: 0,
  name: 'Carte A',
  imagePath: null,
  keywordsUpright: ['alpha', 'souffle'],
  keywordsReversed: ['a-inv'],
  meaningUpright: 'Sens droit A à découvrir.',
  meaningReversed: 'Sens inversé A à apprivoiser.',
  love: 'Côté relations A.',
  work: 'Côté travail A.',
  money: 'Côté argent A.',
  advice: 'Conseil A.',
  warning: 'Avertissement A.',
  shortMessage: 'Court A.',
  shareMessage: 'Partage A.',
  tags: ['tag-a'],
);

Widget _wrapLibrary(TarotRepository repo) {
  return MaterialApp(
    home: TarotScope(
      repository: repo,
      drawService: TarotDrawService(repository: repo),
      dailyService: DailyReadingService(repository: repo),
      quotaService: DailyQuotaService(),
      resetService: AppDataResetService(),
      child: const CardsLibraryScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CardDetailScreen (standalone)', () {
    testWidgets('shows card name and the editorial section headings',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CardDetailScreen(card: _sampleCard)),
      );

      // AppBar title + body heading both render the card name.
      expect(find.text('Carte A'), findsAtLeastNWidgets(1));

      expect(find.text('Message principal'.toUpperCase()), findsOneWidget);
      expect(
        find.text('Quand la carte est inversée'.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('Relations'.toUpperCase()), findsOneWidget);
      expect(find.text('Travail / projets'.toUpperCase()), findsOneWidget);
      expect(find.text('LE PETIT MOT'), findsOneWidget);
      // The previous "INVITATION" label has been retired in lot 10.
      expect(find.text('INVITATION'), findsNothing);
      expect(find.text('À GARDER À L’ESPRIT'), findsOneWidget);
    });

    testWidgets('renders the editorial bodies of the sections',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CardDetailScreen(card: _sampleCard)),
      );

      expect(find.text('Sens droit A à découvrir.'), findsOneWidget);
      expect(find.text('Sens inversé A à apprivoiser.'), findsOneWidget);
      expect(find.text('Côté relations A.'), findsOneWidget);
      expect(find.text('Côté travail A.'), findsOneWidget);
      expect(find.text('Conseil A.'), findsOneWidget);
      expect(find.text('Avertissement A.'), findsOneWidget);
    });

    testWidgets('renders without overflow on a 320x568 viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: CardDetailScreen(card: _sampleCard)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Carte A'), findsAtLeastNWidgets(1));
    });
  });

  group('CardsLibraryScreen tap → CardDetailScreen', () {
    testWidgets('tapping a card opens its detail screen', (tester) async {
      final repo =
          TarotRepository(loader: (_) async => _libraryFixture);

      await tester.pumpWidget(_wrapLibrary(repo));
      await tester.pumpAndSettle();

      // Library is now populated.
      expect(find.text('Carte A'), findsOneWidget);
      expect(find.text('Message principal'.toUpperCase()), findsNothing);

      await tester.tap(find.text('Carte A'));
      await tester.pumpAndSettle();

      // Detail screen is now on top: sections + body of Carte A are visible.
      expect(find.text('Message principal'.toUpperCase()), findsOneWidget);
      expect(find.text('Sens droit A à découvrir.'), findsOneWidget);
    });
  });
}
