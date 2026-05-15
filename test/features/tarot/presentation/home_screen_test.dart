import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/pile_ou_face_app.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
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
        '"Découvrir mon message du jour" opens the daily reading screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _emptyFixture));

      await tester.tap(find.text('Découvrir mon message du jour'));
      await tester.pumpAndSettle();

      expect(find.text('Mon message du jour'), findsOneWidget);
      expect(find.text('Révéler mon message'), findsOneWidget);
    });

    testWidgets(
        '"Je me pose une question" opens the general intent reading screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      // Retired labels must not appear on the home anymore.
      expect(find.text('Éclairer une situation'), findsNothing);
      expect(find.text('Faire un tirage 3 cartes'), findsNothing);

      await tester.tap(find.text('Je me pose une question'));
      await tester.pumpAndSettle();

      // AppBar uses the intent title.
      expect(find.text('Je me pose une question'),
          findsAtLeastNWidgets(1));
      expect(find.text('Révéler le tirage'), findsOneWidget);
    });

    testWidgets(
        '"Je me pose une question d’amour" opens the love intent screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('Je me pose une question d’amour'));
      await tester.pumpAndSettle();

      expect(find.text('Question d’amour'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsOneWidget);
    });

    testWidgets(
        '"Je me pose une question de travail" opens the work intent screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('Je me pose une question de travail'));
      await tester.pumpAndSettle();

      expect(find.text('Question de travail'), findsOneWidget);
      expect(find.text('Révéler le tirage'), findsOneWidget);
    });

    testWidgets(
        '"Je me pose une question d’argent" opens the money intent screen',
        (tester) async {
      await tester.pumpWidget(_buildApp(fixture: _threeCardsFixture));

      await tester.tap(find.text('Je me pose une question d’argent'));
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
        find.text('Pile ou Face a un message pour toi.'),
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
        find.text('Découvrir mon message du jour'),
        findsOneWidget,
      );
    });
  });
}
