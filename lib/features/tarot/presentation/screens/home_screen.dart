import 'dart:math' as math;

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
                  minHeight: math.max(0.0, constraints.maxHeight - 48),
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
                      const SizedBox(height: 12),
                      Text(
                        'Pile ou Face a un message pour toi.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.deepGreen,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(flex: 2),
                      ElevatedButton.icon(
                        onPressed: () => _openDailyMessage(context),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Découvrir mon message du jour'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Je me pose une question sur…',
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.deepGreen.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _IntentButtonsGrid(onTap: (i) => _openIntent(context, i)),
                      const Spacer(flex: 3),
                      Text(
                        'À toi d’interpréter.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.deepGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Application de divertissement et d’introspection.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.subtle,
                          fontSize: 11,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () => _openLibrary(context),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AppColors.subtle.withValues(alpha: 0.85),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            child: const Text('Voir les cartes'),
                          ),
                        ),
                      ],
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

class _IntentButtonsGrid extends StatelessWidget {
  const _IntentButtonsGrid({required this.onTap});

  final void Function(ReadingIntent) onTap;

  ButtonStyle _compactStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _button(BuildContext context, ReadingIntent intent) {
    return OutlinedButton(
      style: _compactStyle(context),
      onPressed: () => onTap(intent),
      child: Text(intent.homeLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _button(context, ReadingIntent.general)),
            const SizedBox(width: 10),
            Expanded(child: _button(context, ReadingIntent.love)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _button(context, ReadingIntent.work)),
            const SizedBox(width: 10),
            Expanded(child: _button(context, ReadingIntent.money)),
          ],
        ),
      ],
    );
  }
}
