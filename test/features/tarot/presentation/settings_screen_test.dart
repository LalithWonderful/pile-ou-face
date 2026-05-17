import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/settings_screen.dart';
import 'package:pile_ou_face/features/tarot/services/app_data_reset_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/last_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _emptyFixture = '[]';

Widget _wrapSettings() {
  final repo = TarotRepository(loader: (_) async => _emptyFixture);
  return MaterialApp(
    home: TarotScope(
      repository: repo,
      drawService: TarotDrawService(repository: repo),
      dailyService: DailyReadingService(repository: repo),
      quotaService: DailyQuotaService(),
      resetService: AppDataResetService(),
      lastReadingService: LastReadingService(repository: repo),
      child: const SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SettingsScreen', () {
    testWidgets('does not expose any clear-data action in v1',
        (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      expect(find.text('Effacer mes données'), findsNothing);
      expect(find.text('Effacer mes données ?'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('keeps the short local-data notice', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      expect(
        find.text('Tes tirages sont enregistrés uniquement sur cet appareil.'),
        findsOneWidget,
      );
    });

    testWidgets('displays privacy policy link', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      expect(find.text('Politique de confidentialité'), findsOneWidget);
    });

    testWidgets('tapping the privacy link opens the internal policy page',
        (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Politique de confidentialité'));
      await tester.pumpAndSettle();

      // The internal page is now on top — its AppBar title repeats the
      // entry label, and the body carries the key MVP statements.
      expect(
        find.text('Politique de confidentialité'),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining('sans compte'),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining('enregistrées localement'),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining('désinstaller l’application'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('renders without overflow on a 320x568 viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Paramètres'), findsOneWidget);
    });
  });
}
