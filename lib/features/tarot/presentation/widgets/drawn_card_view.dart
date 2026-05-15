import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/drawn_card.dart';
import 'accent_panel.dart';
import 'card_art_placeholder.dart';

class DrawnCardView extends StatelessWidget {
  const DrawnCardView({
    super.key,
    required this.drawnCard,
    this.position,
  });

  final DrawnCard drawnCard;
  final String? position;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final card = drawnCard.card;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.softGold.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (position != null) ...[
            Text(
              position!.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.softGold,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Center(
            child: CardArtPlaceholder(
              variant: CardArtVariant.faceUp,
              card: card,
              width: 130,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            card.name,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.deepGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            drawnCard.orientationLabel,
            style: textTheme.bodySmall?.copyWith(
              color: drawnCard.reversed
                  ? AppColors.charcoal
                  : AppColors.subtle,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final kw in drawnCard.keywords)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 14),
          _ShortMessage(text: card.shortMessage),
          const SizedBox(height: 12),
          Text(
            drawnCard.meaning,
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          AccentPanel(
            label: 'LE PETIT MOT',
            icon: Icons.auto_awesome,
            accent: AppColors.softGold,
            background: AppColors.softGold.withValues(alpha: 0.14),
            border: AppColors.softGold.withValues(alpha: 0.4),
            body: drawnCard.advice,
          ),
          const SizedBox(height: 10),
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
    );
  }
}

class _ShortMessage extends StatelessWidget {
  const _ShortMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 2,
            decoration: BoxDecoration(
              color: AppColors.softGold.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                text,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.deepGreen,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

