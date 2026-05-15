# Lot 3 — Expérience de tirage immersive

## Objectif

Faire passer le tirage d'une simple liste statique à une vraie expérience
de lecture : intention avant le tirage, révélation animée, mise en page
premium, sans assets lourds, sans backend, sans dépendance externe ajoutée.

L'architecture (`TarotScope`, `TarotRepository`, `TarotDrawService`) reste
intacte. Seules la couche UI et un libellé de spread évoluent.

## Changements UX

### 1. ReadingScreen — état initial puis révélation

Deux phases distinctes :

- **Idle** : la description du tirage est affichée en italique douce, les
  cartes apparaissent face cachée (placeholders élégants), suivies d'une
  invitation « Prenez un instant, puis révélez votre tirage. » et d'un CTA
  principal `Révéler le tirage` (état `Révélation…` pendant l'appel).
- **Revealed** : la liste des `DrawnCardView` s'affiche, avec un effet
  *fade + slide* léger en cascade par carte (`_StaggeredReveal`,
  ~110 ms de décalage entre chaque carte, 420 ms par carte,
  `Curves.easeOutCubic`). En bas, un bouton secondaire
  `Retirer une carte` rejoue l'animation.

La transition entre les deux phases est portée par un `AnimatedSwitcher`
(350 ms, `easeOutCubic`). Le retour est assuré par la flèche par défaut de
l'`AppBar`.

### 2. DrawnCardView — lecture lisible et premium

Le panneau de carte affiche désormais, dans l'ordre :

1. position (chip doré en small caps) si tirage à plusieurs cartes,
2. **visual placeholder** centré (numéro romain + nom en small caps sur
   fond vert profond, bordures dorées) — voir section 4,
3. nom de la carte,
4. orientation (Sens droit / Sens inversé),
5. mots-clés orientés (chips vert profond),
6. **message court** en italique, séparé par une barre dorée verticale,
7. signification principale (orientation-spécifique),
8. encart **CONSEIL** sur fond doré clair,
9. encart **À GARDER À L'ESPRIT** sur fond vert très clair — `warning`
   présenté comme une note douce, pas une alerte.

La carte gagne aussi une ombre portée discrète pour le côté premium.

### 3. Tirage 3 cartes — labels introspectifs

`TarotSpread.threeCards.positions` passe de
`['Passé', 'Présent', 'Futur']` à `['Situation', 'Énergie', 'Conseil']`.

La description du spread est reformulée :
`Une situation, son énergie, et le conseil qui s'y rattache.`

### 4. Placeholder visuel sans illustration

Nouveau widget `CardArtPlaceholder` :

- variante **faceDown** : fond vert profond avec dégradé subtil, double
  bordure dorée, icône `auto_awesome` centrée. Utilisée dans l'état idle
  du tirage.
- variante **faceUp** : même cadre, mais numéro romain de la carte en
  grand au centre, petite icône en haut, nom de la carte en small caps en
  bas. Utilisée dans le `DrawnCardView`.
- constructeur **mini** : version compacte (44 px) pour le leading de la
  bibliothèque.

Aucun asset image n'est requis : tout est dessiné en Flutter, palette
existante (ivoire / vert profond / doré doux), ratio carte 1 : 1.6.

### 5. CardsLibraryScreen — léger lifting

Chaque ligne utilise désormais `CardArtPlaceholder.mini` en leading pour
homogénéiser le vocabulaire visuel avec le tirage, sans détourner du
contenu textuel (liste simple, pas d'écran détail encore).

## Choix sur les labels du tirage 3 cartes

Le triptyque *Situation / Énergie / Conseil* est retenu pour trois raisons :

1. **Introspectif plutôt que prédictif** : on cesse de promettre une lecture
   du « futur », ce qui s'aligne sur le positionnement
   « divertissement et introspection » et limite les risques de
   sur-promesse.
2. **Universel** : trois positions claires qui restent valables pour des
   questions très diverses (relation, projet, doute, choix).
3. **Cohérent avec le ton éditorial du Lot 2** : la troisième position
   reprend le mot *Conseil*, qui est aussi un des champs centraux du JSON
   (`advice`).

## Choix sur les cartes inversées

Comportement inchangé par rapport au Lot 1 :

- 50/50 aléatoire géré dans `TarotDrawService.draw`.
- Mots-clés et signification affichés selon l'orientation (`DrawnCard.keywords`,
  `DrawnCard.meaning`).
- Le label « Sens inversé » reste affiché tel quel, en italique discret,
  sans dramatisation et sans icône d'alerte.
- Le `warning` (champ universel à la carte) est affiché dans tous les cas,
  pas seulement en sens inversé — il reste un rappel doux et bienveillant.

Pas d'option utilisateur pour désactiver les inversions à ce stade : on
laisse cette préférence pour un éventuel lot Paramètres.

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 0.9s)`
- `flutter test` : `+18 All tests passed!`

Détail des suites :

- `widget_test.dart` (1) : smoke home inchangé, toujours vert.
- `tarot_repository_test.dart` (3) : inchangé.
- `tarot_draw_service_test.dart` (4) : inchangé.
- `major_arcana_integrity_test.dart` (5) : inchangé.
- `tarot_spread_test.dart` (3, **nouveau**) : vérifie le nombre de
  positions du tirage simple, les nouveaux labels
  `Situation / Énergie / Conseil`, et l'absence des anciens labels
  `Passé / Présent / Futur`.
- `reading_screen_test.dart` (2, **nouveau**) : vérifie l'affichage de
  l'état idle (CTA `Révéler le tirage`, carte non encore visible) et
  l'apparition d'une carte après tap sur le CTA (carte `Le Mat`,
  `short_message` visible, CTA `Révéler` disparu).

## Limites connues

- Pas d'écran de détail par carte depuis la bibliothèque ; un tap n'a
  pas encore d'effet. À traiter dans un lot ultérieur si l'usage le
  justifie.
- Pas d'animation 3D de retournement (`flip`) ; la révélation reste
  une transition fondu + glissement. Le brief demandait « animation
  simple ».
- Pas de feedback haptique sur le tap CTA (pas crucial sans publication
  immédiate).
- Pas de partage ni de capture du tirage à ce stade (lot dédié prévu,
  candidat à `share_plus`).
- Pas de persistance : un retour arrière puis ré-ouverture du tirage
  refait un nouveau tirage. Pas encore de « tirage du jour » sauvegardé.
- Visuel des cartes 100 % généré côté Flutter, design volontairement
  abstrait — les illustrations propres restent à produire (lot artwork).

## Prochaine étape recommandée

Lot 4 — Rétention quotidienne et partage :

1. Persister localement le « tirage du jour » avec `shared_preferences`
   (date, ids, orientations) pour proposer une expérience récurrente.
2. Ajouter une action de partage construite à partir de `share_message`
   (introduction de `share_plus` validée si nécessaire).
3. Écran de détail carte depuis la bibliothèque, réutilisant les
   sections `love`, `work`, `advice`, `warning` du JSON éditorial.
4. Petits ajustements UX en fonction de retours utilisateurs réels
   (timing des animations, lisibilité, hiérarchie des sections).
5. Choix d'un provider analytics à valider avant d'instrumenter les
   premiers événements (vue home, tirage lancé, partage déclenché).
