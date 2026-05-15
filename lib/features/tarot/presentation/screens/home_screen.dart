import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/reading_intent.dart';
import 'cards_library_screen.dart';
import 'reading_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openDailyMessage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ReadingScreen(isDaily: true),
      ),
    );
  }

  void _openIntent(BuildContext context, ReadingIntent intent) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(intent: intent),
      ),
    );
  }

  void _openLibrary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CardsLibraryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      Text(
                        'Pile ou Face',
                        textAlign: TextAlign.center,
                        style: textTheme.displaySmall?.copyWith(
                          color: AppColors.deepGreen,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pile ou Face a un message pour toi.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.deepGreen,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(flex: 3),
                      ElevatedButton.icon(
                        onPressed: () => _openDailyMessage(context),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Découvrir mon message du jour'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            _openIntent(context, ReadingIntent.general),
                        child: Text(ReadingIntent.general.homeLabel),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () =>
                            _openIntent(context, ReadingIntent.love),
                        child: Text(ReadingIntent.love.homeLabel),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () =>
                            _openIntent(context, ReadingIntent.work),
                        child: Text(ReadingIntent.work.homeLabel),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () =>
                            _openIntent(context, ReadingIntent.money),
                        child: Text(ReadingIntent.money.homeLabel),
                      ),
                      const Spacer(flex: 2),
                      if (kDebugMode) ...[
                        TextButton(
                          onPressed: () => _openLibrary(context),
                          child: const Text('Voir les cartes'),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Libre à toi de l’interpréter.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.deepGreen,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Application de divertissement et d’introspection.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.subtle,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
