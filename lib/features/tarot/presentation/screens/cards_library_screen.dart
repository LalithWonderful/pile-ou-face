import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class CardsLibraryScreen extends StatelessWidget {
  const CardsLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque des cartes'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.style_outlined,
                  size: 64,
                  color: AppColors.softGold,
                ),
                const SizedBox(height: 24),
                Text(
                  'Bibliothèque à venir',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Le contenu détaillé des cartes sera chargé depuis un fichier local.',
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
