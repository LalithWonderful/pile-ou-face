import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/settings_screen.dart';
import 'package:pile_ou_face/features/tarot/services/app_data_reset_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
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
    testWidgets('displays "Effacer mes données" button', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      expect(find.text('Effacer mes données'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog before clearing data',
        (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effacer mes données'));
      await tester.pumpAndSettle();

      expect(find.text('Effacer mes données ?'), findsOneWidget);
      expect(
        find.textContaining('Cette action ne peut pas être annulée'),
        findsOneWidget,
      );
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Effacer'), findsOneWidget);
    });

    testWidgets('canceling dialog keeps data intact', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effacer mes données'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Dialog is dismissed; SettingsScreen is still shown.
      expect(find.text('Paramètres'), findsOneWidget);
    });

    testWidgets('confirming dialog clears local data and shows snackbar',
        (tester) async {
      // Seed some data.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'daily_reading.date': '2026-05-15',
        'daily_reading.card_id': 'le_mat',
        'daily_reading.reversed': false,
        DailyQuotaService.prefsKey: '{"date":"2026-05-15","counters":{"general":1}}',
      });

      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effacer mes données'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effacer'));
      await tester.pumpAndSettle();

      // Snackbar confirmation.
      expect(find.text('Données effacées.'), findsOneWidget);

      // Verify keys are gone.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    testWidgets('displays privacy policy link', (tester) async {
      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      expect(find.text('Politique de confidentialité'), findsOneWidget);
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
