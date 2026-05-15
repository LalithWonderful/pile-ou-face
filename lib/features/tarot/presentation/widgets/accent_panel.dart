import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

/// A small framed panel used to surface a short editorial nudge
/// (CONSEIL / INVITATION / À GARDER À L'ESPRIT, etc.) above or below
/// a card's main body.
///
/// The label row keeps its [Text] inside a [Flexible] so long labels can
/// wrap on narrow screens (the same fix that landed on
/// [CardDetailScreen] in lot 8 is now applied everywhere this panel
/// renders).
class AccentPanel extends StatelessWidget {
  const AccentPanel({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.background,
    required this.border,
    required this.body,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color border;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: accent,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.charcoal,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
