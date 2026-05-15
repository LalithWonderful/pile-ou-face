# Lot 2 — Enrichissement éditorial du JSON Tarot

## Objectif

Remplacer le contenu placeholder court du Lot 1 par un contenu éditorial
français exploitable pour une V1 publique : chaque carte porte désormais des
interprétations dans plusieurs registres (général, amour, travail, conseil,
avertissement, message court, message de partage).

L'architecture du Lot 1 est préservée : pas de dépendance ajoutée, pas de
backend, pas d'analytics. Seul le contenu et son schéma évoluent.

## Structure JSON retenue

Chaque carte de `assets/tarot/major_arcana.json` expose 15 champs :

```json
{
  "id": "le_mat",
  "number": 0,
  "name": "Le Mat",
  "image_path": null,
  "keywords_upright": ["liberté", "commencement", "élan", "spontanéité"],
  "keywords_reversed": ["dispersion", "imprudence", "fuite", "indécision"],
  "meaning_upright": "Le Mat évoque un pas neuf…",
  "meaning_reversed": "Inversé, il signale une dispersion…",
  "love": "Une rencontre légère ou un souffle neuf…",
  "work": "Un projet émerge ou un changement de cap…",
  "advice": "Faire le premier pas, sans attendre toutes les réponses.",
  "warning": "Distinguer l'élan sincère de la simple envie de fuir.",
  "short_message": "Un pas neuf, tout simplement.",
  "share_message": "J'ai tiré Le Mat — un appel doux à l'élan et à la liberté.",
  "tags": ["commencement", "liberté", "mouvement"]
}
```

- Convention de nommage : `snake_case` côté JSON, `camelCase` côté modèle Dart.
- `image_path` reste à `null` pour les 22 cartes : le slot est prévu pour un
  lot d'illustrations futur, sans engagement de planning.
- `id` est volontairement stable et indépendant du `name`, pour pouvoir
  renommer une carte sans casser de futures persistances (favoris,
  historique).

## Champs ajoutés par rapport au Lot 1

| Champ              | Type           | Rôle                                                |
| ------------------ | -------------- | --------------------------------------------------- |
| `image_path`       | string \| null | Slot pour une future illustration.                  |
| `keywords_upright` | string[]       | Renomme `keywords`. Mots-clés du sens droit.        |
| `keywords_reversed`| string[]       | Nouveau. Mots-clés spécifiques du sens inversé.     |
| `meaning_upright`  | string         | Renomme `uprightMeaning` (snake_case).              |
| `meaning_reversed` | string         | Renomme `reversedMeaning` (snake_case).             |
| `love`             | string         | Lecture orientée relations affectives.              |
| `work`             | string         | Lecture orientée travail et projets.                |
| `advice`           | string         | Conseil court, universel à la carte.                |
| `warning`          | string         | Avertissement bienveillant, sans dramatisation.     |
| `short_message`    | string         | Phrase très courte (≈ 5–8 mots).                    |
| `share_message`    | string         | Phrase prête à partager, à la première personne.    |
| `tags`             | string[]       | Thématiques (filtrage, regroupements futurs).       |

## Choix éditoriaux

- **Ton** : accessible, doux, introspectif, légèrement mystique. Aucune
  formule prédictive absolue (« vous allez », « il faut »). Préférence pour
  les formes suggestives (« invite à », « peut révéler », « pourrait
  évoquer »).
- **Cadrage** : positionnement explicite « divertissement et introspection »,
  jamais « voyance certaine ».
- **Cartes sensibles** (La Mort, Le Diable, La Maison-Dieu) : reformulées
  comme transformation, conscience, libération — jamais anxiogènes.
- **Naming** : numérotation et noms d'arcanes du **tarot de Marseille**
  (8 = Justice, 11 = Force, 13 = La Mort, 16 = La Maison-Dieu, 0 = Le Mat).
- **Apostrophes typographiques** (`’`) utilisées partout pour cohérence et
  rendu mobile soigné.
- **Longueur** : 1 à 2 phrases courtes par champ. Optimisé pour un usage
  mobile rapide, pas pour un livre.

## Adaptations code

- `lib/features/tarot/models/tarot_card.dart` : 15 champs, `imagePath`
  nullable, factory `fromJson` adaptée au snake_case.
- `lib/features/tarot/models/drawn_card.dart` : nouveaux getters
  `keywords` (orientation-spécifique) et `advice` (universel à la carte).
- `lib/features/tarot/presentation/widgets/drawn_card_view.dart` : affiche
  désormais nom, sens droit/inversé, mots-clés orientés, message principal
  et un encart **CONSEIL** mis en valeur.
- `lib/features/tarot/presentation/screens/cards_library_screen.dart` :
  liste sur `keywordsUpright` (lecture neutre).
- `lib/features/tarot/presentation/screens/reading_screen.dart` : aucun
  changement (l'affichage est délégué au widget).

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 2.1s)`
- `flutter test` : `+13 All tests passed!`

Détail des suites :

- `tarot_repository_test.dart` (3 tests) : parsing complet des 15 champs,
  cache, invalidation.
- `tarot_draw_service_test.dart` (4 tests) : tirage 1 carte, 3 cartes
  uniques, erreur si deck trop petit, déterminisme avec `Random` seedé.
- `major_arcana_integrity_test.dart` (5 tests, **nouveau**) : sur le JSON
  réel chargé via `rootBundle`,
  - 22 cartes présentes,
  - numéros 0 à 21 sans doublon,
  - identifiants uniques,
  - champs texte critiques tous non vides,
  - tableaux de mots-clés et `tags` non vides.
- `widget_test.dart` (1 test) : smoke home inchangé.

## Limites connues

- 78 cartes complètes (arcanes mineurs) toujours hors périmètre.
- Pas d'illustrations associées : `image_path` reste `null` pour les 22
  cartes.
- Pas d'écran de détail par carte depuis la bibliothèque (liste seule).
- Pas de relecture éditoriale par un tiers humain ; le ton est cohérent
  mais une passe rédactionnelle finale sera utile avant publication.
- Pas de versionnage du schéma JSON : un futur changement (par ex.
  introduction d'un sous-modèle `interpretations`) cassera la compatibilité.
- Pas d'analytics sur l'usage des champs (quels textes sont lus le plus
  longtemps, lesquels donnent lieu au partage) — à brancher dans un lot
  rétention.

## Prochaine étape recommandée

Lot 3 — Lecture immersive et partage :

1. Écran de détail carte accessible depuis la bibliothèque, qui affiche
   `meaning_upright`, `love`, `work`, `advice`, `warning`.
2. Animation simple de révélation au moment du tirage (fade + slide léger).
3. Action de partage à partir de `share_message` (via `Share.share` du
   package `share_plus`, seule dépendance externe envisagée pour le partage
   natif).
4. Persistance locale du dernier tirage du jour
   (`shared_preferences`) pour préparer la rétention quotidienne.
5. Choix d'un provider analytics à valider avant câblage des premiers
   événements (vue home, tirage lancé, partage déclenché).
