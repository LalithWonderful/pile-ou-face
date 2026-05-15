# Lot 0 — Initialisation du projet Pile ou Face

## Objectif

Poser le socle technique d'une application mobile Flutter autonome appelée
**Pile ou Face**, destinée à servir de fast-win pour tester publication,
acquisition, analytics, UX et diffusion avant un projet plus complexe.

Le lot 0 se limite au squelette : pas de backend, pas de Firebase / Supabase,
pas d'IA, pas d'authentification, pas de paiement, pas d'assets obligatoires.

## Commandes exécutées

```bash
flutter create --project-name pile_ou_face --org com.lalith.pileouface \
  --platforms=ios,android .
flutter analyze
flutter test
```

`flutter run` n'a pas été exécuté faute de device branché — non bloquant pour
ce lot.

## Structure créée

```
lib/
  main.dart
  app/
    pile_ou_face_app.dart
    app_theme.dart
  features/
    tarot/
      models/         (.gitkeep)
      data/           (.gitkeep)
      services/       (.gitkeep)
      presentation/
        screens/
          home_screen.dart
          reading_screen.dart
          cards_library_screen.dart
        widgets/      (.gitkeep)
test/
  widget_test.dart
docs/
  launch/
    lot_0_initial_setup.md
```

- `main.dart` : point d'entrée, instancie `PileOuFaceApp`.
- `app/pile_ou_face_app.dart` : `MaterialApp` racine, thème clair, home =
  `HomeScreen`.
- `app/app_theme.dart` : thème premium minimaliste (fond ivoire, vert profond,
  doré doux).
- `features/tarot/presentation/screens/home_screen.dart` : titre, sous-titre,
  bouton principal *Commencer un tirage*, bouton secondaire *Découvrir les
  cartes*, mention discrète en bas.
- `reading_screen.dart` et `cards_library_screen.dart` : écrans placeholder
  accessibles via `Navigator.push` (pas de `go_router` pour éviter la
  sur-architecture sur 3 écrans).

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.0s)`
- `flutter test` : `+1 All tests passed!` (smoke test de la home — vérifie
  titre, sous-titre, libellés des deux boutons et mention de bas de page).

## Limites connues

- Aucun contenu tarot réel : les écrans Tirage et Bibliothèque sont des
  placeholders. Le JSON de cartes sera ajouté dans un lot ultérieur.
- Aucun asset visuel (illustrations, fond, logo) — typographie système
  Material par défaut.
- Pas de navigation typée (`go_router`) ; `Navigator` simple suffit pour 3
  écrans.
- Pas de gestion d'état (Riverpod / Bloc) : à introduire quand un véritable
  flux de tirage existera.
- `flutter run` non vérifié sur device physique pour ce lot.
- Plateformes générées : iOS et Android uniquement (web/desktop exclus par
  défaut).

## Prochaine étape recommandée

Lot 1 — Contenu et tirage offline :

1. Définir le modèle de carte (`TarotCard`) dans `features/tarot/models/`.
2. Ajouter le JSON local des cartes dans `assets/tarot/` et le déclarer dans
   `pubspec.yaml`.
3. Implémenter un `TarotRepository` lisant ce JSON, exposé via un service.
4. Brancher `ReadingScreen` sur un tirage aléatoire (1 ou 3 cartes) et
   `CardsLibraryScreen` sur la liste complète.
5. Ajouter quelques tests unitaires sur le repository et le service de tirage.
