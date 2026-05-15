import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tirage'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 64,
                  color: AppColors.softGold,
                ),
                const SizedBox(height: 24),
                Text(
                  'Tirage à venir',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Le moteur de tirage symbolique sera disponible prochainement.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.subtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
