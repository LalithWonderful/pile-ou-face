import 'package:flutter_test/flutter_test.dart';

import 'package:pile_ou_face/app/pile_ou_face_app.dart';

void main() {
  testWidgets('Home screen renders title and primary actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PileOuFaceApp());

    expect(find.text('Pile ou Face'), findsOneWidget);
    expect(find.text('Tirages symboliques en français'), findsOneWidget);
    expect(find.text('Commencer un tirage'), findsOneWidget);
    expect(find.text('Découvrir les cartes'), findsOneWidget);
    expect(
      find.text('Application de divertissement et d’introspection.'),
      findsOneWidget,
    );
  });
}
