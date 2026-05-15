import 'package:flutter_test/flutter_test.dart';

import 'package:pile_ou_face/app/pile_ou_face_app.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';

void main() {
  testWidgets(
      'Home screen exposes the validated positioning and primary actions',
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
    expect(find.text('Découvrir mon message'), findsOneWidget);
    expect(find.text('Faire un tirage 3 cartes'), findsOneWidget);
    expect(find.text('Découvrir les cartes'), findsOneWidget);
    expect(find.text('Libre à toi de l’interpréter.'), findsOneWidget);
    expect(
      find.text('Application de divertissement et d’introspection.'),
      findsOneWidget,
    );
  });
}
