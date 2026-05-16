import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

/// Static privacy policy screen used while no public URL is available.
///
/// The placeholder [AppConstants.privacyPolicyUrl] is kept centralised
/// elsewhere so a future lot can swap this internal page for an
/// external launch (via `url_launcher`) without touching call sites.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  /// Bumped manually whenever the wording below is updated.
  static const String _lastUpdated = '16 mai 2026';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pile ou Face est conçue pour fonctionner localement, sur '
                'ton appareil, sans compte et sans serveur dédié. Voici '
                'comment tes données sont traitées.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.charcoal,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const _Section(
                title: 'Données collectées',
                body:
                    'Aujourd’hui, Pile ou Face ne collecte pas de données '
                    'personnelles. L’application ne demande pas d’e-mail, '
                    'ne crée pas de compte, et ne transmet aucune donnée '
                    'd’utilisation à un serveur Pile ou Face. Aucun outil '
                    'de mesure d’audience (analytics) n’est intégré dans '
                    'l’application.\n\n'
                    'À noter : l’installation et la mise à jour de '
                    'l’application transitent par l’App Store ou le Play '
                    'Store. Ces plateformes peuvent traiter certaines '
                    'données selon leurs propres règles de '
                    'confidentialité, indépendamment de Pile ou Face.',
              ),
              const _Section(
                title: 'Données enregistrées localement',
                body:
                    'Pour faire fonctionner l’application, certaines '
                    'informations sont enregistrées localement sur ton '
                    'appareil :\n'
                    '• ton message du jour et la date du dernier tirage ;\n'
                    '• les compteurs de tirages par thème (Une situation, '
                    'L’amour, Le travail, L’argent) ;\n'
                    '• d’éventuelles préférences d’affichage.\n\n'
                    'Ces données restent sur ton téléphone. Elles ne sont '
                    'pas envoyées à Pile ou Face.',
              ),
              const _Section(
                title: 'Compte utilisateur',
                body:
                    'L’application fonctionne sans compte. Aucune adresse '
                    'e-mail, identifiant, mot de passe ou information '
                    'personnelle n’est demandé pour utiliser Pile ou Face.',
              ),
              const _Section(
                title: 'Paiement / achats intégrés',
                body:
                    'Pour le moment, Pile ou Face ne propose pas d’achats '
                    'intégrés. Si des achats intégrés sont ajoutés plus '
                    'tard, ils seront gérés par Apple ou Google selon ton '
                    'appareil, selon leurs propres règles de '
                    'confidentialité.',
              ),
              const _Section(
                title: 'Notifications',
                body: 'L’application n’envoie pas de notifications push.',
              ),
              const _Section(
                title: 'Partage',
                body:
                    'Lorsque tu utilises l’option de partage d’un message, '
                    'Pile ou Face s’appuie sur la fonction de partage '
                    'native de ton téléphone. Tu choisis toi-même '
                    'l’application de destination (messagerie, e-mail, '
                    'notes, etc.). Pile ou Face n’envoie le message à '
                    'aucun autre destinataire.',
              ),
              const _Section(
                title: 'Suppression des données',
                body:
                    'À tout moment, depuis l’écran Paramètres, tu peux '
                    'utiliser l’action « Effacer mes données » pour '
                    'supprimer les données enregistrées localement par '
                    'Pile ou Face.\n\n'
                    'Tu peux aussi désinstaller l’application : cela '
                    'supprime également les données locales associées.',
              ),
              const _Section(
                title: 'Contact',
                body:
                    'Pour toute question concernant cette politique ou '
                    'tes données, tu peux nous contacter via la fiche de '
                    'l’application sur l’App Store ou le Play Store.',
              ),
              const _Section(
                title: 'Dernière mise à jour',
                body: _lastUpdated,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.deepGreen,
              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
