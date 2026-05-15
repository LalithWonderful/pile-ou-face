import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/drawn_card.dart';
import '../../models/reading_intent.dart';
import 'accent_panel.dart';
import 'card_art_placeholder.dart';

class DrawnCardView extends StatelessWidget {
  const DrawnCardView({
    super.key,
    required this.drawnCard,
    this.position,
    this.positionIndex,
    this.intent,
  });

  final DrawnCard drawnCard;
  final String? position;

  /// 0 → "Là où tu en es", 1 → "L'énergie du moment", 2 → "Le conseil".
  /// When present together with [drawnCard.card.spreadMeanings], the
  /// matching position-specific text becomes the main body.
  final int? positionIndex;

  /// Drives which body text is shown for the card. When null or
  /// [ReadingIntent.general], and no position-specific reading is
  /// available, the orientation-aware [DrawnCard.meaning] is used
  /// (daily and general questions). For love / work / money, the
  /// matching domain field of the card is shown if no validated
  /// position reading exists.
  final ReadingIntent? intent;

  String? _positionBody() {
    final meanings = drawnCard.card.spreadMeanings;
    if (meanings == null || positionIndex == null) return null;
    switch (positionIndex!) {
      case 0:
        return meanings.whereYouAre;
      case 1:
        return meanings.currentEnergy;
      case 2:
        return meanings.advice;
      default:
        return null;
    }
  }

  String _fallbackBody(ReadingIntent? i) {
    switch (i) {
      case ReadingIntent.love:
        return drawnCard.card.love;
      case ReadingIntent.work:
        return drawnCard.card.work;
      case ReadingIntent.money:
        return drawnCard.card.money;
      case ReadingIntent.general:
      case null:
        return drawnCard.meaning;
    }
  }

  /// Domain complement (love/work/money body) shown **below** the
  /// position-specific body when both exist and are different.
  String? _domainComplement(ReadingIntent? i) {
    final position = _positionBody();
    if (position == null) return null;
    switch (i) {
      case ReadingIntent.love:
        return drawnCard.card.love;
      case ReadingIntent.work:
        return drawnCard.card.work;
      case ReadingIntent.money:
        return drawnCard.card.money;
      case ReadingIntent.general:
      case null:
        return null;
    }
  }

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
            _positionBody() ?? _fallbackBody(intent),
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (_domainComplement(intent) != null &&
              intent?.domainLabel != null) ...[
            const SizedBox(height: 14),
            _DomainComplement(
              label: intent!.domainLabel!,
              body: _domainComplement(intent)!,
            ),
          ],
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

class _DomainComplement extends StatelessWidget {
  const _DomainComplement({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.deepGreen.withValues(alpha: 0.75),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.charcoal,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

