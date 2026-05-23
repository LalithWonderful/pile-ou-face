import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pile_ou_face/app/app_theme.dart';
import 'package:pile_ou_face/app/tarot_scope.dart';
import 'package:pile_ou_face/features/tarot/data/tarot_repository.dart';
import 'package:pile_ou_face/features/tarot/models/drawn_card.dart';
import 'package:pile_ou_face/features/tarot/models/tarot_card.dart';
import 'package:pile_ou_face/features/tarot/presentation/screens/reading_screen.dart';
import 'package:pile_ou_face/features/tarot/services/app_data_reset_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_quota_service.dart';
import 'package:pile_ou_face/features/tarot/services/daily_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/last_reading_service.dart';
import 'package:pile_ou_face/features/tarot/services/tarot_draw_service.dart';

String _toSlug(String name) {
  const accents = {
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'à': 'a', 'â': 'a', 'ä': 'a',
    'ô': 'o', 'ö': 'o',
    'û': 'u', 'ù': 'u', 'ü': 'u',
    'ç': 'c', 'ï': 'i', 'î': 'i',
  };
  var slug = name.toLowerCase();
  for (final entry in accents.entries) {
    slug = slug.replaceAll(entry.key, entry.value);
  }
  return slug.replaceAll("'", '').replaceAll('\u2019', '').replaceAll(' ', '_');
}

Future<void> _sendScreenshot(String filename, Uint8List bytes) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('http://localhost:8765/screenshot?name=$filename'),
    );
    request.add(bytes);
    final response = await request.close();
    await response.drain();
    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'capture all 44 daily message screenshots with real card artwork',
    (WidgetTester tester) async {
      // Use the real repository so WEBP assets load correctly on the simulator.
      final repository = TarotRepository();
      final cards = await repository.loadMajorArcana();

      var captured = 0;

      for (final card in cards) {
        for (final reversed in const [false, true]) {
          final orientation = reversed ? 'reversed' : 'upright';
          final slug = _toSlug(card.name);
          final number = (card.number + 1).toString().padLeft(2, '0');
          final filename = '${number}_${slug}_$orientation.png';

          final boundaryKey = ValueKey('screenshot_boundary_$captured');

          await tester.pumpWidget(
            TarotScope(
              repository: repository,
              drawService: TarotDrawService(repository: repository),
              dailyService: DailyReadingService(repository: repository),
              quotaService: DailyQuotaService(),
              resetService: AppDataResetService(),
              lastReadingService: LastReadingService(repository: repository),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                home: RepaintBoundary(
                  key: boundaryKey,
                  child: ReadingScreen(
                    isDaily: true,
                    preparedDraw: [
                      DrawnCard(card: card, reversed: reversed),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 800));
          await tester.pumpAndSettle();

          final boundary = tester.renderObject(
            find.byKey(boundaryKey),
          ) as RenderRepaintBoundary;

          // Use the device's natural pixel ratio for crisp marketing screenshots.
          final pixelRatio = WidgetsBinding
              .instance.platformDispatcher.implicitView!.devicePixelRatio;
          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          image.dispose();

          final bytes = byteData!.buffer.asUint8List();
          await _sendScreenshot(filename, bytes);

          captured++;
          print('[$captured/44] Sent $filename (${bytes.length} bytes)');
        }
      }

      print('\n✅ Done — $captured screenshots sent to host server');
    },
  );
}
