import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import 'cards_library_screen.dart';
import 'reading_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openReading(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReadingScreen()),
    );
  }

  void _openLibrary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CardsLibraryScreen()),
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
              const SizedBox(height: 12),
              Text(
                'Tirages symboliques en français',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.subtle,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () => _openReading(context),
                child: const Text('Commencer un tirage'),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => _openLibrary(context),
                child: const Text('Découvrir les cartes'),
              ),
              const Spacer(flex: 2),
              Text(
                'Application de divertissement et d’introspection.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.subtle,
                  fontSize: 12,
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
