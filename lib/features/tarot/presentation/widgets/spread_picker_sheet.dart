import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/tarot_spread.dart';

Future<TarotSpread?> showSpreadPicker(BuildContext context) {
  return showModalBottomSheet<TarotSpread>(
    context: context,
    backgroundColor: AppColors.ivory,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _SpreadPickerSheet(),
  );
}

class _SpreadPickerSheet extends StatelessWidget {
  const _SpreadPickerSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.subtle.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Choisir un tirage',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final spread in TarotSpread.values) ...[
              _SpreadOption(spread: spread),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpreadOption extends StatelessWidget {
  const _SpreadOption({required this.spread});

  final TarotSpread spread;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).pop(spread),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.softGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${spread.cardCount}',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spread.label, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      spread.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}
