# Lot 12 — Polish UX accueil et écrans question

## Objectif

Faire passer l'accueil et les écrans question d'une apparence
« liste de boutons » à un rendu plus posé, plus humain, et plus
rituel. Sur Pixel 8, l'accueil ne donne plus l'impression d'un
prototype et les écrans idle ne paraissent plus vides.

Aucune modification du JSON éditorial, aucune logique métier touchée,
aucune nouvelle dépendance.

## Changements HomeScreen

### Hiérarchie
- Titre `Pile ou Face`.
- Phrase d'accueil `Pile ou Face a un message pour toi.` (sans italique
  pour qu'elle ne soit pas perçue comme secondaire).
- CTA principal (ElevatedButton) `Découvrir mon message du jour`.
- Bloc *Je me pose une question sur…* (titre de groupe en
  `titleSmall`, `w500`, vert profond légèrement adouci).
- Grille 2×2 d'OutlinedButtons compacts (padding réduit, label
  bold) :

  ```
  ┌──────────────────┬──────────────────┐
  │  Une situation   │      L'amour     │
  ├──────────────────┼──────────────────┤
  │   Le travail     │     L'argent     │
  └──────────────────┴──────────────────┘
  ```

- Footer : `Libre à toi de l'interpréter.` + `Application de
  divertissement et d'introspection.`
- Lien dev `Voir les cartes` conservé mais durci :
  - uniquement `kDebugMode` (déjà le cas) ;
  - `TextButton` minimaliste, `fontSize 11`, `w400`, gris subtle,
    souligné, padding réduit, `tapTargetSize.shrinkWrap` ;
  - placé **sous** le disclaimer, à part — il ne peut plus se
    confondre avec un parcours utilisateur.

### Libellés
Les anciens libellés longs sur l'accueil disparaissent :
`Je me pose une question`, `Je me pose une question d'amour`, etc. Ils
restent visibles **uniquement** comme titres d'AppBar à l'arrivée sur
l'écran tirage (via `intent.title`), pas sur l'accueil.

L'`homeLabel` de chaque `ReadingIntent` passe en version courte :
`Une situation`, `L'amour`, `Le travail`, `L'argent`. L'`intent.title`
(AppBar) reste inchangé.

## Changements ReadingScreen idle

### Layout
- Conserve l'arborescence
  `LayoutBuilder + SingleChildScrollView + IntrinsicHeight + Column`
  introduite au Lot 9.
- Ratios des `Spacer` rebalancés :
  - `Spacer(flex: 1)` au-dessus de l'intro (au lieu de `Spacer()`
    par défaut),
  - `Spacer(flex: 2)` entre le hint et le CTA.
  Effet : le bloc central remonte d'environ un tiers, le CTA
  reste accessible en bas.
- Padding vertical du `SingleChildScrollView` passe de `16/24` à
  `12/24` pour gagner 4 px en haut.

### Intro hiérarchisée
Nouveau widget privé `_IntroText` qui découpe la description sur
`\n` et rend deux lignes différenciées :
- Ligne 1 : `titleMedium`, `w600`, **vert profond**, height 1.3.
- Ligne 2 : `bodyMedium`, **charcoal**, height 1.4, **sans italique**.

Conséquence sur les quatre intentions :
- *Pense à ta question.* (forte) / *Trois cartes pour y voir plus
  clair.* (douce)
- *Pense à cette personne, cette relation ou cette envie d'aimer.*
  / *Trois cartes pour écouter ce que ton cœur sait déjà.*
- Etc.

Pour le tirage du jour (description sans `\n`), une seule ligne
forte vert profond est affichée.

### Hint
`Prends un instant, puis révèle ton tirage.` (mode tirage) et
`Libre à toi de l'interpréter.` (mode daily) passent de
`bodySmall + couleur subtle + italique` (lecture de mention légale)
à `bodyMedium + vert profond 85 % + w500 + non italique` (lecture de
guide doux).

### Labels de positions sous les cartes (3 cartes uniquement)
Sous chacun des trois `CardArtPlaceholder` face-down, le label de la
position s'affiche en small caps doré clair :

```
[Carte 1]            [Carte 2]                  [Carte 3]
LÀ OÙ TU EN ES       L'ÉNERGIE DU MOMENT        LE CONSEIL
```

- Police : `labelSmall`, `fontSize 9`, `letterSpacing 1.0`, `w700`,
  couleur `softGold`, max 2 lignes (wrap si label trop long).
- Le mode daily (1 carte) ne montre pas de label — seul le tirage
  3 cartes affiche les positions, comme demandé.

## Décisions UX

- **Pas de carrousel ni de horizontal scroll** pour les 4
  intentions : la grille 2×2 reste la plus lisible et la plus
  élégante sans introduire de geste supplémentaire.
- **Pas de title case** : les libellés courts respectent la
  capitalisation naturelle du français (`Une situation`,
  `L'amour`…).
- **Italique retiré** sur l'accroche d'accueil et les hints : sur
  Pixel 8 réel, l'italique faisait « note de bas de page ». Le
  rythme typographique reste lisible en weight + couleur seule.
- **Lien `Voir les cartes`** : intentionnellement très discret en
  debug, **invisible en release** (`kDebugMode`). Aucun risque
  qu'un·e utilisateur·rice le confonde avec un parcours produit.
- **Daily inchangé** côté wording : la phrase
  `Pile ou Face a un message pour toi. Prends un instant, puis
  révèle-le.` reste l'intro de l'écran daily.

## Tests adaptés

- `test/widget_test.dart` — couvre la nouvelle hiérarchie d'accueil :
  CTA principal + titre de groupe + 4 boutons courts + bloque les
  anciens libellés longs et `Éclairer une situation`.
- `test/features/tarot/presentation/home_screen_test.dart` — les
  navigations tapent désormais `Une situation`, `L'amour`,
  `Le travail`, `L'argent`. Les titres d'AppBar attendus sont
  inchangés (`Je me pose une question`, `Question d'amour`, etc.).
- Aucun changement nécessaire sur `reading_screen_test.dart` : les
  tests existants vérifient `Mon message du jour`, `Tirage du jour`,
  `Révéler le tirage`, le footer money et la disposition responsive
  — tout reste valide avec le nouveau idle (les éléments testés
  existent toujours).

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.5s)`
- `flutter test` : `+54 All tests passed!` (inchangé par rapport
  au Lot 11 — pas de nouveau test ajouté, juste des assertions et
  des `tap` mis à jour).

## Limites connues

- La grille 2×2 force les 4 labels d'intentions à la même largeur,
  ce qui peut sembler artificiel quand `L'amour` est court et que
  `Une situation` est plus long. Visuellement c'est plus harmonieux
  que la `Wrap` libre, mais quelques pixels sont « gaspillés » dans
  les boutons les plus courts.
- Le lien `Voir les cartes` est désormais souligné en plus d'être
  petit/gris — choix volontaire pour signaler « c'est cliquable »
  malgré sa discrétion. À ré-évaluer si une vraie option settings
  émerge.
- Les labels de positions sous les cartes face-down peuvent passer
  sur deux lignes (par exemple `L'ÉNERGIE DU MOMENT`). Sur Pixel 8
  ils tiennent en une ligne pour les trois positions, mais à
  320 px de large la deuxième ligne est possible. C'est cohérent
  avec le contrat « lisibilité avant élégance forcée ».
- Le `_IntroText` ne supporte que deux niveaux : ligne 1 forte +
  reste du texte regroupé en ligne 2. Si une future description a
  besoin de trois niveaux distincts, il faudra l'étendre.
- Pas d'audit accessibilité formel sur les nouveaux contrastes
  (vert profond 85 % alpha sur ivoire — devrait passer largement
  WCAG AA mais non mesuré dans ce lot).

## Prochaine étape recommandée

Lot 13 — Hero + accessibilité ciblée :

1. Animation `Hero` sur le `CardArtPlaceholder` entre la
   bibliothèque (debug) et la fiche détail.
2. Petit audit `Semantics` ciblé sur la nouvelle grille
   d'intentions (descriptions textuelles claires pour les lecteurs
   d'écran : les 4 boutons sont à la même hauteur visuelle, leur
   ordre de lecture doit rester cohérent).
3. Optionnel : feedback haptique léger sur la révélation du
   message du jour.
4. Choix d'un provider analytics respectueux de la vie privée — en
   attente depuis le Lot 4. À arbitrer avant toute instrumentation.
