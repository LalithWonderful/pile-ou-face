import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/tarot_card.dart';
import '../widgets/accent_panel.dart';
import '../widgets/card_art_placeholder.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key, required this.card});

  final TarotCard card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(card.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CardArtPlaceholder(
                  variant: CardArtVariant.faceUp,
                  card: card,
                  width: 160,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                card.name,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.deepGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final kw in card.keywordsUpright)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kw,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.deepGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              _Section(
                title: 'Message principal',
                body: card.meaningUpright,
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'Quand la carte est inversée',
                body: card.meaningReversed,
              ),
              const SizedBox(height: 18),
              _Section(title: 'Relations', body: card.love),
              const SizedBox(height: 18),
              _Section(title: 'Travail / projets', body: card.work),
              const SizedBox(height: 22),
              AccentPanel(
                label: 'INVITATION',
                icon: Icons.auto_awesome,
                accent: AppColors.softGold,
                background: AppColors.softGold.withValues(alpha: 0.14),
                border: AppColors.softGold.withValues(alpha: 0.4),
                body: card.advice,
              ),
              const SizedBox(height: 12),
              AccentPanel(
                label: 'À GARDER À L’ESPRIT',
                icon: Icons.spa_outlined,
                accent: AppColors.subtle,
                background: AppColors.deepGreen.withValues(alpha: 0.05),
                border: AppColors.deepGreen.withValues(alpha: 0.15),
                body: card.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.softGold,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.charcoal,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

