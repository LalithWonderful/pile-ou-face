import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/tarot_scope.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openPrivacyPolicy(BuildContext context) {
    // For now the policy lives inside the app (no url_launcher in the
    // MVP dependency set). AppConstants.privacyPolicyUrl is preserved
    // centrally so a future lot can swap this navigation for an
    // external launch without touching call sites.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Effacer mes données ?'),
        content: const Text(
          'Cela supprimera ton tirage du jour et tes préférences locales. '
          'Tes quotas journaliers sont conservés pour préserver les limites '
          'de l’application. Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final scope = TarotScope.of(context);
      await scope.resetService.clearAll();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Données effacées.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _SectionHeader(title: 'Données locales'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tes tirages et préférences sont enregistrés uniquement sur cet appareil.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.charcoal,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => _confirmClearData(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Effacer mes données'),
              ),
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Confidentialité'),
            ListTile(
              leading: const Icon(Icons.policy_outlined, color: AppColors.deepGreen),
              title: const Text('Politique de confidentialité'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _openPrivacyPolicy(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.subtle,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
