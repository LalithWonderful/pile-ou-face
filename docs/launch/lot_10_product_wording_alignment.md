# Lot 10 — Recentrage UX et wording produit

## Objectif

Aligner les libellés visibles de l'app sur le positionnement Pile ou
Face : proche, bienveillante mais franche, qui **propose un message** et
**aide à prendre du recul**, sans tomber dans un vocabulaire technique
de cartomancie (tirage, situation/énergie/conseil bruts, conseil, etc.).

Le périmètre est strictement éditorial : aucun changement de logique
métier, aucun changement de JSON, aucune dépendance ajoutée. Tous les
changements vivent dans l'UI Flutter et leurs tests miroirs.

## Décisions de wording

### Accueil

| Avant                       | Après                     | Rôle             |
| --------------------------- | ------------------------- | ---------------- |
| Découvrir mon message       | Découvrir mon message     | CTA principal    |
| Faire un tirage 3 cartes    | **Éclairer une situation**| CTA secondaire   |
| Découvrir les cartes        | **Voir les cartes**       | Lien tertiaire   |

La hiérarchie visuelle est inchangée : `ElevatedButton` principal,
`OutlinedButton` secondaire, `TextButton` tertiaire. Seuls les libellés
changent.

### Écran tirage 3 cartes

- AppBar et `spread.label` :
  `Tirage en trois cartes` → **`Éclairer une situation`**.
  L'AppBar reflète maintenant exactement le CTA tapé sur l'accueil.
- Description idle (`spread.description`) :
  > « Pense à une situation. Pile ou Face t'aide à la regarder sous
  > trois angles : là où tu en es, l'énergie du moment, et le conseil
  > à garder. »
- Positions des trois cartes (`spread.positions`) :

| Avant       | Après                  |
| ----------- | ---------------------- |
| Situation   | **Là où tu en es**     |
| Énergie     | **L'énergie du moment**|
| Conseil     | **Le conseil**         |

Les chips de position dans `DrawnCardView` les rendent en small caps
gold (`position.toUpperCase()`), ce qui donne par exemple
`LÀ OÙ TU EN ES`.

### Encarts de lecture

| Encart           | Avant         | Après             |
| ---------------- | ------------- | ----------------- |
| Conseil / tirage | `CONSEIL`     | **`LE PETIT MOT`**|
| Conseil / fiche  | `INVITATION`  | **`LE PETIT MOT`**|
| Vigilance douce  | `À GARDER À L'ESPRIT` | inchangé   |

Les deux occurrences du conseil partagent désormais le même libellé
`LE PETIT MOT` côté tirage et côté fiche carte. Le mot **Invitation**
est explicitement retiré (non validé). Le wording **À GARDER À
L'ESPRIT** est conservé.

## Écrans impactés

- [lib/features/tarot/models/tarot_spread.dart](../../lib/features/tarot/models/tarot_spread.dart)
  — label, description et positions de `TarotSpread.threeCards`.
- [lib/features/tarot/presentation/screens/home_screen.dart](../../lib/features/tarot/presentation/screens/home_screen.dart)
  — libellés des deux CTAs secondaire et tertiaire.
- [lib/features/tarot/presentation/widgets/drawn_card_view.dart](../../lib/features/tarot/presentation/widgets/drawn_card_view.dart)
  — label de l'encart conseil (`CONSEIL` → `LE PETIT MOT`).
- [lib/features/tarot/presentation/screens/card_detail_screen.dart](../../lib/features/tarot/presentation/screens/card_detail_screen.dart)
  — label de l'encart conseil (`INVITATION` → `LE PETIT MOT`).

Le JSON éditorial `assets/tarot/major_arcana.json` n'est **pas** touché.

## Tests adaptés

### [test/widget_test.dart](../../test/widget_test.dart)
- Le smoke d'accueil cherche `Éclairer une situation` et `Voir les
  cartes` au lieu des anciens libellés.
- Ajout d'assertions négatives `findsNothing` sur les libellés retirés
  (`Faire un tirage 3 cartes`, `Découvrir les cartes`) pour bloquer les
  régressions.

### [test/features/tarot/presentation/home_screen_test.dart](../../test/features/tarot/presentation/home_screen_test.dart)
- Le test de navigation 3 cartes tape `Éclairer une situation` et
  s'attend à `findsAtLeastNWidgets(1)` sur ce libellé sur l'écran
  cible (AppBar + reste de la page).
- Le test de navigation bibliothèque tape `Voir les cartes`.
- Les deux ajoutent une assertion explicite `findsNothing` sur l'ancien
  libellé pour verrouiller la migration.

### [test/features/tarot/models/tarot_spread_test.dart](../../test/features/tarot/models/tarot_spread_test.dart)
- Le test d'assertion sur les positions cherche désormais
  `['Là où tu en es', 'L'énergie du moment', 'Le conseil']` et vérifie
  aussi `spread.label == 'Éclairer une situation'`.
- Le test « pas de label legacy » est étendu pour couvrir à la fois les
  termes Lot 3 (`Passé / Présent / Futur`) et Lot 4-9
  (`Situation / Énergie / Conseil` bruts).

### [test/features/tarot/presentation/reading_screen_test.dart](../../test/features/tarot/presentation/reading_screen_test.dart)
- Le test responsive 3 cartes assert maintenant
  `find.text('LÀ OÙ TU EN ES')` (chip de position uppercased).

### [test/features/tarot/presentation/card_detail_screen_test.dart](../../test/features/tarot/presentation/card_detail_screen_test.dart)
- Cherche `LE PETIT MOT` et bloque `INVITATION` avec un `findsNothing`.

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.5s)`
- `flutter test` : `+48 All tests passed!`

48/48 verts (même total qu'au Lot 9, aucun test ajouté ni supprimé —
uniquement des libellés mis à jour).

## Limites connues

- L'AppBar de la bibliothèque conserve `Bibliothèque des cartes` : le
  CTA d'entrée s'appelle désormais `Voir les cartes` mais la
  destination garde son titre métier. C'est volontaire (pas de
  redondance, pas d'instruction explicite dans le brief), mais une
  futur passe pourrait l'unifier.
- L'AppBar du daily reste `Mon message du jour` et le label single
  `Tirage du jour` est inchangé — aucun ajustement demandé sur ces
  écrans.
- Les libellés `LE PETIT MOT` et `À GARDER À L'ESPRIT` restent en
  small caps avec letter-spacing : aucun changement de style, juste
  un changement de texte.
- Pas de localisation : tous les libellés sont en français en dur. Une
  future internationalisation passerait par `flutter_localizations`,
  hors scope du V1.
- Pas de test linguistique qui scanne l'arbre Flutter pour bloquer la
  réapparition de termes proscrits côté UI ; les assertions
  `findsNothing` ciblées (Lot 10) couvrent les points sensibles
  actuels, mais ne sont pas exhaustives.

## Prochaine étape recommandée

Lot 11 — Navigation latérale et animations légères dans la fiche :

1. Permettre de passer d'une carte à l'autre depuis la fiche détail
   (swipe ou flèches précédent/suivant) sans repasser par la liste.
2. Transition `Hero` sur le `CardArtPlaceholder` entre la bibliothèque
   et la fiche détail.
3. Audit `Semantics` ciblé sur la fiche détail si les sections doivent
   être groupées pour les lecteurs d'écran.
4. Choix d'un provider analytics respectueux de la vie privée — en
   attente depuis le Lot 4. À arbitrer avant toute instrumentation, y
   compris des partages.
