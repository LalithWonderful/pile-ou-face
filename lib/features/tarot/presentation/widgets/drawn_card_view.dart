import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/drawn_card.dart';

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softGold.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (position != null) ...[
            Text(
              position!.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.softGold,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _romanNumeral(card.number),
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.softGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  card.name,
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            drawnCard.orientationLabel,
            style: textTheme.bodySmall?.copyWith(
              color: drawnCard.reversed
                  ? AppColors.charcoal
                  : AppColors.subtle,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 12),
          Text(
            drawnCard.meaning,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.softGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.softGold.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSEIL',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.softGold,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drawnCard.advice,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _romanNumeral(int n) {
    const numerals = <int, String>{
      1000: 'M',
      900: 'CM',
      500: 'D',
      400: 'CD',
      100: 'C',
      90: 'XC',
      50: 'L',
      40: 'XL',
      10: 'X',
      9: 'IX',
      5: 'V',
      4: 'IV',
      1: 'I',
    };
    if (n == 0) return '0';
    final buffer = StringBuffer();
    var remaining = n;
    for (final entry in numerals.entries) {
      while (remaining >= entry.key) {
        buffer.write(entry.value);
        remaining -= entry.key;
      }
    }
    return buffer.toString();
  }
}
