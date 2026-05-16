# Pile ou Face

Pile ou Face est une application mobile Flutter de tirage de cartes, pensée comme un espace simple et sincère pour éclairer ce que l’on ressent et écouter son intuition.

## Statut

Application MVP en cours de préparation pour publication.

## Fonctionnalités MVP

- **Message du jour** — un tirage quotidien unique pour commencer la journée
- **Tirages avec intention** — questions sur l'amour, le travail, l'argent ou une situation générale
- **Quotas freemium locaux** — 2 tirages par thème et par jour, gérés localement
- **Partage natif** — partager son message via la feuille de partage du téléphone
- **Paramètres** — accès aux réglages de l'application
- **Effacement des données locales** — suppression des tirages, quotas et préférences en un geste
- **Politique de confidentialité** — page dédiée, transparente et sans jargon

## Positionnement

- Application d’introspection et de divertissement.
- Pas de compte obligatoire au MVP.
- Pas de backend au MVP.
- Toutes les données (tirages, quotas, préférences) sont stockées localement sur l’appareil.
- Aucune promesse prédictive absolue : les cartes invitent à la réflexion, elles ne dictent pas l’avenir.

## Technique

- [Flutter](https://flutter.dev)
- Dart
- [SharedPreferences](https://pub.dev/packages/shared_preferences) — persistance locale
- [share_plus](https://pub.dev/packages/share_plus) — partage natif
- Assets locaux (JSON des cartes, illustrations WebP)

## Confidentialité

La politique de confidentialité est disponible ici :
[docs/privacy-policy.html](docs/privacy-policy.html)

## Support

Pour toute question, consultez la page de support :
[docs/support.html](docs/support.html)

## Publication

Les pages publiques (politique de confidentialité, support, accueil) sont dans le dossier [`docs/`](docs/) et sont destinées à être publiées via **GitHub Pages**.

## Développement

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Licence

Licence non définie pour le moment.
