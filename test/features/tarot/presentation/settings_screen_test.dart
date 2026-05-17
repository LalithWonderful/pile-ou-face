import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/reading_intent.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/settings_screen.dart';
import 'package:pile_ou_face/features/tarot/services/app_data_reset_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/local_storage_keys.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _emptyFixture = '[]';

String _todayKey() {
  final d = DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

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

    testWidgets(
        'confirming dialog clears the daily reading but preserves quotas',
        (tester) async {
      // Seed today's daily reading and a partially consumed quota.
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalStorageKeys.dailyReadingDate: '2026-05-15',
        LocalStorageKeys.dailyReadingCardId: 'le_mat',
        LocalStorageKeys.dailyReadingReversed: false,
        DailyQuotaService.prefsKey:
            '{"date":"2026-05-15","counters":{"general":1}}',
      });

      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effacer mes données'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effacer'));
      await tester.pumpAndSettle();

      // Snackbar confirmation.
      expect(find.text('Données effacées.'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      // Daily reading keys are wiped.
      expect(prefs.getKeys(), isNot(contains(LocalStorageKeys.dailyReadingDate)));
      expect(prefs.getKeys(),
          isNot(contains(LocalStorageKeys.dailyReadingCardId)));
      expect(prefs.getKeys(),
          isNot(contains(LocalStorageKeys.dailyReadingReversed)));
      // The daily quota key MUST survive the public clear-data flow.
      expect(prefs.getKeys(), contains(DailyQuotaService.prefsKey));
    });

    testWidgets(
        'public clear-data cannot bypass an exhausted daily quota',
        (tester) async {
      // Seed an exhausted quota for "general" (2/2).
      SharedPreferences.setMockInitialValues(<String, Object>{
        DailyQuotaService.prefsKey:
            '{"date":"${_todayKey()}","counters":{"general":2}}',
      });

      final quota = DailyQuotaService();
      expect(await quota.remaining(ReadingIntent.general), 0);

      await tester.pumpWidget(_wrapSettings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Effacer mes données'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Effacer'));
      await tester.pumpAndSettle();

      // After clearing, the user is still blocked.
      expect(await quota.remaining(ReadingIntent.general), 0);
      expect(await quota.tryConsume(ReadingIntent.general), isFalse);

      // The debug-only path still works (tests run in debug mode).
      await quota.resetDailyQuotaForDebug();
      expect(await quota.remaining(ReadingIntent.general), 2);
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
        find.textContaining('Effacer mes données'),
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
