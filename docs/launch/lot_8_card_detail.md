# Lot 8 — Écran détail carte et confort de lecture

## Objectif

Permettre à l'utilisateur·rice qui parcourt la bibliothèque d'ouvrir le
**détail d'une carte** pour y lire ses interprétations longues, sans
transformer l'app en encyclopédie froide. L'écran réutilise l'intégralité
des champs éditoriaux déjà alignés sur la voix Pile ou Face (Lots 4A et
4C) et les présente en sections proches de l'utilisateur·rice.

Aucune dépendance ajoutée, aucune modification du JSON, aucun changement
de la logique de tirage, aucun branchement analytics.

## Choix UX

### Parcours
- L'écran s'ouvre depuis `CardsLibraryScreen` au tap sur une ligne.
- Navigation `Navigator.push` classique avec `MaterialPageRoute`. Le
  retour utilise la flèche par défaut de l'`AppBar`.
- L'AppBar affiche le nom de la carte — pas besoin d'un breadcrumb.
- Les tuiles de la bibliothèque deviennent vraiment cliquables :
  `Material + InkWell` (ripple natif), nouvelle icône `chevron_right`
  pour signaler l'affordance.

### Structure éditoriale
Les titres des sections évitent le jargon « upright / reversed » et
privilégient une formulation directe :

| Champ JSON          | Section UI                       |
| ------------------- | -------------------------------- |
| `meaning_upright`   | **Message principal**            |
| `meaning_reversed`  | **Quand la carte est inversée**  |
| `love`              | **Relations**                    |
| `work`              | **Travail / projets**            |
| `advice`            | **INVITATION** (encart doré)     |
| `warning`           | **À GARDER À L'ESPRIT** (encart) |

`advice` et `warning` reprennent les encarts visuels existants du
`DrawnCardView` (cartouche dorée pour l'invitation, cartouche verte très
claire pour la mise en garde douce) afin que le vocabulaire visuel reste
cohérent entre le tirage et la fiche.

### Hiérarchie visuelle
- **Hero block** centré : `CardArtPlaceholder` face-up 160 px (numéro
  romain + nom small caps sur fond vert profond, palette existante).
- **Nom de la carte** en `headlineSmall` deepGreen sous le placeholder.
- **Mots-clés** (`keywords_upright`) en chips wrap, centrés.
- **Sections** en `SingleChildScrollView` avec espacement régulier
  (18 px entre sections texte, 22 px avant l'encart Invitation).
- Aucune image lourde, palette inchangée
  (ivoire / vert profond / doré doux).

## Fichiers créés / modifiés

### Créés
- [lib/features/tarot/presentation/screens/card_detail_screen.dart](../../lib/features/tarot/presentation/screens/card_detail_screen.dart)
  — l'écran et deux helpers privés (`_Section` pour les blocs texte,
  `_AccentPanel` pour les encarts Invitation / À garder à l'esprit).
- [test/features/tarot/presentation/card_detail_screen_test.dart](../../test/features/tarot/presentation/card_detail_screen_test.dart)
  — 4 tests (3 standalone + 1 navigation depuis la bibliothèque).
- `docs/launch/lot_8_card_detail.md` — ce document.

### Modifiés
- [lib/features/tarot/presentation/screens/cards_library_screen.dart](../../lib/features/tarot/presentation/screens/cards_library_screen.dart)
  — `_CardTile` passe d'un `Container` non-interactif à un
  `Material + InkWell` qui pousse `CardDetailScreen` au tap. Icône
  `chevron_right` ajoutée pour signaler la navigation.

## Tests

`flutter analyze` : `No issues found! (ran in 1.1s)`
`flutter test` : `+45 All tests passed!` (44 → 45 ? non, +4 nouveaux).

Détail :
- **CardDetailScreen — standalone (3 tests)** :
  - affiche le nom de la carte (AppBar + body) ;
  - affiche les six sections (titres tous présents) ;
  - affiche les corps de texte de chaque section ;
  - rendu sans overflow sur viewport 320×568.
- **CardsLibraryScreen → CardDetailScreen (1 test)** :
  - le tap sur une carte ouvre son détail avec le bon contenu visible.

## Limites connues

- Le détail réutilise le placeholder visuel (numéro + nom) — aucune
  illustration finale n'est embarquée. C'est cohérent avec le périmètre
  V1 mais la fiche peut sembler nue tant que les visuels ne sont pas
  faits.
- Pas de partage depuis la fiche carte : le `share_message` n'a de sens
  qu'attaché au tirage du jour (« Pile ou Face avait un message pour
  moi aujourd'hui »). Un partage « depuis la bibliothèque » nécessite
  un autre format éditorial ; à instruire dans un lot ultérieur si la
  demande émerge.
- Pas de navigation entre cartes (swipe ou flèches précédent/suivant)
  depuis la fiche. Retour à la liste obligatoire pour passer d'une
  carte à l'autre.
- Pas d'historique des cartes vues, pas de favoris.
- L'encart `À GARDER À L'ESPRIT` du `DrawnCardView` (écran tirage)
  garde la même structure `Row + Icon + Text` sans `Flexible` ; le test
  de viewport 320×568 n'a pas été ajouté sur l'écran tirage dans ce
  lot. Si le même overflow apparaît côté tirage, la correction
  symétrique (envelopper le label dans un `Flexible`) est triviale.
- Aucun feedback haptique sur le tap d'une carte (volontairement
  minimal).
- Aucune mesure d'usage de la fiche détail (pas d'analytics).

## Prochaine étape recommandée

Lot 9 — Confort de navigation et accessibilité :

1. Navigation latérale dans la fiche carte (swipe ou flèches) pour
   parcourir les arcanes sans repasser par la liste.
2. Petites animations de transition entre la liste et la fiche
   (`Hero` sur le `CardArtPlaceholder`).
3. Audit `Semantics` ciblé sur la fiche détail (les sections doivent
   être lues comme un tout, pas comme une suite de labels isolés).
4. Symétriser la mise en page des encarts entre tirage et fiche
   (extraire `_AccentPanel` dans un widget partagé si la duplication
   devient gênante).
5. Choix d'un provider analytics respectueux de la vie privée — toujours
   en attente, à valider avant toute instrumentation.
