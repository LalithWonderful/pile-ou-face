# Lot 1 — Contenu et tirage offline

## Objectif

Brancher le squelette du Lot 0 sur un véritable contenu tarot et un moteur de
tirage local. À l'issue du lot, l'utilisateur peut :

- ouvrir l'app, lancer un *Tirage du jour* (1 carte) ou un *Tirage en trois
  cartes* (passé / présent / futur) ;
- consulter la bibliothèque des 22 arcanes majeurs.

Tout reste offline, sans backend ni dépendance externe.

## Décisions de cadrage

| Question                  | Choix retenu                        |
| ------------------------- | ----------------------------------- |
| Jeu                       | 22 arcanes majeurs (numérotation Marseille) |
| Tirages câblés            | 1 carte + 3 cartes                  |
| Cartes inversées          | Activées (50/50 aléatoire)          |
| Contenu textuel V1        | Placeholder court FR (1 phrase / sens) |
| Navigation                | Picker bottom sheet + `Navigator.push` |
| Gestion d'état            | `InheritedWidget` (`TarotScope`) — pas de Riverpod |

## Commandes exécutées

```bash
flutter analyze
flutter test
```

## Structure ajoutée

```
assets/
  tarot/
    major_arcana.json            # 22 cartes : id, number, name, keywords,
                                 # uprightMeaning, reversedMeaning
lib/
  app/
    tarot_scope.dart             # InheritedWidget pour le repo + service
    pile_ou_face_app.dart        # instancie repo/service, wrappe MaterialApp
  features/tarot/
    models/
      tarot_card.dart            # modèle de carte + fromJson
      drawn_card.dart            # carte tirée (orientation + meaning helper)
      tarot_spread.dart          # enum TarotSpread.single / .threeCards
    data/
      tarot_repository.dart      # charge le JSON via rootBundle, cache mémoire
    services/
      tarot_draw_service.dart    # tirage (shuffle + random reversed)
    presentation/
      screens/
        home_screen.dart         # ouvre le picker
        reading_screen.dart      # affiche le tirage + bouton "Retirer"
        cards_library_screen.dart# liste des 22 arcanes
      widgets/
        spread_picker_sheet.dart # bottom sheet de sélection 1c / 3c
        drawn_card_view.dart     # rendu d'une carte tirée
test/
  features/tarot/
    data/tarot_repository_test.dart
    services/tarot_draw_service_test.dart
  widget_test.dart               # smoke test home, injection repo stub
docs/launch/lot_1_content_and_draw.md
```

## Modèle de données

`assets/tarot/major_arcana.json` : tableau JSON, chaque carte expose

```json
{
  "id": "le_mat",
  "number": 0,
  "name": "Le Mat",
  "keywords": ["liberté", "commencement", "spontanéité"],
  "uprightMeaning": "Un nouveau départ, libre et spontané.",
  "reversedMeaning": "Imprudence ou refus de s'engager."
}
```

L'`id` est stable et indépendant du nom affiché (pour pouvoir renommer sans
casser d'éventuelles persistances).

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.1s)`
- `flutter test` : `+8 All tests passed!`
  - Repository : parsing JSON, cache, invalidation.
  - DrawService : single, threeCards (cartes uniques), erreur si deck trop
    petit, déterminisme avec `Random` seedé.
  - Smoke widget test sur la home avec repo stub injecté.

## Limites connues

- Contenu placeholder : 1 phrase neutre par sens. Le contenu rédactionnel
  long est à produire dans un lot dédié.
- Pas d'illustrations / pas d'animations de retournement de carte.
- Pas de persistance : impossible de sauvegarder un tirage ou un historique.
- Pas de partage (capture, deep link). Sera utile pour l'acquisition.
- Pas d'écran de détail par carte depuis la bibliothèque (liste seule).
- 78 cartes complètes (mineurs) non incluses.
- Pas de tracking analytics : à introduire avant la publication.

## Prochaine étape recommandée

Lot 2 — UX et rétention :

1. Ajouter un écran de détail carte (tap depuis la bibliothèque), même
   placeholder, pour préparer la lecture longue.
2. Animation simple de révélation de carte dans `ReadingScreen` (fade + slide,
   pas d'asset requis).
3. Persistance locale (`shared_preferences`) du dernier tirage du jour pour
   conditionner la rétention.
4. Capture et partage du tirage (image PNG via `RepaintBoundary`).
5. Brancher un premier événement analytics (vue home, tirage lancé, tirage
   terminé) — choix du provider à faire (Firebase Analytics, PostHog, etc.).
