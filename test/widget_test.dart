import 'package:flutter_test/flutter_test.dart';

import 'package:pile_ou_face/app/pile_ou_face_app.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';

void main() {
  testWidgets(
      'Home screen presents the daily CTA, the question group and the four '
      'compact intent buttons', (WidgetTester tester) async {
    final repository = TarotRepository(loader: (_) async => '[]');
    final drawService = TarotDrawService(repository: repository);
    final dailyService = DailyReadingService(repository: repository);

    await tester.pumpWidget(
      PileOuFaceApp(
        repository: repository,
        drawService: drawService,
        dailyService: dailyService,
      ),
    );

    expect(find.text('Pile ou Face'), findsOneWidget);
    expect(find.text('C’est le moment de tirer une carte.'), findsOneWidget);

    // Primary CTA.
    expect(find.text('Découvrir ton message du jour'), findsOneWidget);

    // Group title.
    expect(find.text('Je me pose une question sur…'), findsOneWidget);

    // Four compact intent buttons.
    expect(find.text('Une situation'), findsOneWidget);
    expect(find.text('L’amour'), findsOneWidget);
    expect(find.text('Le travail'), findsOneWidget);
    expect(find.text('L’argent'), findsOneWidget);

    // Retired long labels must no longer appear on the home screen.
    expect(find.text('Je me pose une question'), findsNothing);
    expect(find.text('Je me pose une question d’amour'), findsNothing);
    expect(find.text('Je me pose une question de travail'), findsNothing);
    expect(find.text('Je me pose une question d’argent'), findsNothing);
    expect(find.text('Éclairer une situation'), findsNothing);
    expect(find.text('Faire un tirage 3 cartes'), findsNothing);

    expect(find.text('À toi d’interpréter.'), findsOneWidget);
    expect(
      find.text('Application de divertissement et d’introspection.'),
      findsOneWidget,
    );
  });
}
