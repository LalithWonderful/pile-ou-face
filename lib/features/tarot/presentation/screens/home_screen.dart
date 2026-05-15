import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/tarot_spread.dart';
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

  void _openThreeCardsReading(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const ReadingScreen(spread: TarotSpread.threeCards),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                label: const Text('Découvrir mon message'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _openThreeCardsReading(context),
                child: const Text('Éclairer une situation'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _openLibrary(context),
                child: const Text('Voir les cartes'),
              ),
              const Spacer(flex: 2),
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
  }
}
