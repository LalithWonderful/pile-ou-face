import 'package:flutter_test/flutter_test.dart';

import 'package:pile_ou_face/app/pile_ou_face_app.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';

void main() {
  testWidgets(
      'Home screen exposes the five intent-based entry points and footer',
      (WidgetTester tester) async {
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
    expect(find.text('Pile ou Face a un message pour toi.'), findsOneWidget);

    // Five product-validated entry points.
    expect(find.text('Découvrir mon message du jour'), findsOneWidget);
    expect(find.text('Je me pose une question'), findsOneWidget);
    expect(find.text('Je me pose une question d’amour'), findsOneWidget);
    expect(find.text('Je me pose une question de travail'), findsOneWidget);
    expect(find.text('Je me pose une question d’argent'), findsOneWidget);

    // Retired labels must not reappear.
    expect(find.text('Découvrir mon message'), findsNothing);
    expect(find.text('Éclairer une situation'), findsNothing);
    expect(find.text('Faire un tirage 3 cartes'), findsNothing);

    expect(find.text('Libre à toi de l’interpréter.'), findsOneWidget);
    expect(
      find.text('Application de divertissement et d’introspection.'),
      findsOneWidget,
    );
  });
}
