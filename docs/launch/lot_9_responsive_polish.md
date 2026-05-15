# Lot 9 — Responsive et polish des écrans principaux

## Objectif

Sécuriser le confort de lecture et le responsive des écrans tirage avant
d'ajouter analytics ou de nouvelles fonctionnalités. Le lot 8 avait fixé
l'overflow horizontal sur la fiche détail mais avait signalé que le même
risque persistait dans l'écran tirage. Le lot 8 avait aussi suggéré de
mutualiser les encarts CONSEIL / INVITATION / À GARDER À L'ESPRIT — c'est
fait ici.

Aucune dépendance ajoutée, aucun changement de logique métier, aucun
changement de contenu éditorial, aucun analytics.

## Problèmes corrigés

### 1. Overflow horizontal sur les encarts CONSEIL et À GARDER À L'ESPRIT

Les deux panneaux à l'intérieur de `DrawnCardView` avaient la même
structure `Row(Icon + SizedBox + Text)` sans contrainte de largeur sur
le label. Sur viewport étroit (320 px), `À GARDER À L'ESPRIT` débordait
horizontalement d'environ 5 à 6 pixels — le même bug que celui corrigé
sur `CardDetailScreen` au lot 8.

**Fix** : extraction du widget partagé
[lib/features/tarot/presentation/widgets/accent_panel.dart](../../lib/features/tarot/presentation/widgets/accent_panel.dart),
public, paramétré par `label`, `icon`, `accent`, `background`, `border`,
`body`. Le label est enveloppé dans un `Flexible` pour autoriser le
retour à la ligne sur écrans étroits, sans casser la mise en page sur
écrans normaux.

### 2. Overflow vertical de l'idle 3 cartes sur viewport étroit

Lors de l'ouverture du tirage 3 cartes sur 320×568, les trois
`CardArtPlaceholder` face-down de 92 px se mettaient en wrap sur deux
lignes (3 × 92 + 2 × 14 = 304 px > 272 px disponibles), poussant le CTA
`Révéler le tirage` sous le viewport. Résultat : `RenderFlex overflowed
by 64 pixels on the bottom` et CTA inatteignable.

**Fix** : l'arbre de l'`_IdleState` passe d'un simple `Padding > Column`
à `LayoutBuilder > SingleChildScrollView > ConstrainedBox(minHeight) >
IntrinsicHeight > Column`. Conséquences :

- Sur écran grand : les `Spacer()` agissent comme avant, le contenu est
  distribué verticalement et l'écran reste statique.
- Sur écran étroit : la `Column` peut dépasser `constraints.maxHeight`
  et le `SingleChildScrollView` autorise le scroll — aucun overflow
  rendu.

Le `minHeight: constraints.maxHeight - 40` laisse 40 px de marge pour
les `SafeArea` / `AppBar` insets et évite un saut visible.

### 3. Mutualisation des trois encarts

Avant le lot 9 :

- `DrawnCardView._AdvicePanel` (privé) — bloc CONSEIL doré.
- `DrawnCardView._WarningPanel` (privé) — bloc À GARDER À L'ESPRIT.
- `CardDetailScreen._AccentPanel` (privé) — version paramétrée déjà
  Flexible-safe.

Après le lot 9 :

- `widgets/accent_panel.dart` exporte `AccentPanel` (public) avec la
  variante Flexible-safe.
- `DrawnCardView` et `CardDetailScreen` instancient `AccentPanel` avec
  leurs propres couleurs/labels. Trois classes privées supprimées,
  un seul widget à maintenir.

## Tests ajoutés

`flutter analyze` : `No issues found! (ran in 1.3s)`
`flutter test` : `+48 All tests passed!` (45 → 48, +3 nouveaux).

Nouveau groupe `ReadingScreen (responsiveness)` dans
[test/features/tarot/presentation/reading_screen_test.dart](../../test/features/tarot/presentation/reading_screen_test.dart) :

1. **Daily à 320×568** : pump du daily mode sur surface 320×568, tap
   révèle la carte sans exception, `Le Mat` visible, `Partager ce
   message` atteignable via `scrollUntilVisible` après révélation.
   Couvre à la fois « pas d'exception » et « bouton Partager
   atteignable via scroll ».
2. **Tirage 3 cartes à 320×568** : pump du free three-card spread sur
   surface 320×568, scroll jusqu'au CTA `Révéler le tirage` (désormais
   scrollable grâce au fix), tap, pumpAndSettle.
   `tester.takeException()` doit être `null` et la première position
   `SITUATION` doit être rendue (les positions 2 et 3 sortent du
   viewport en mode mobile, ce qui est le comportement attendu d'une
   `ListView` lazy).
3. **Daily avec `textScaler 1.4`** : enveloppe la racine d'une
   `MediaQuery(textScaler: TextScaler.linear(1.4))`, révèle, vérifie
   l'absence d'exception et la présence du nom de la carte.

Les tests injectent un `shareInvoker` no-op pour éviter d'appeler la
feuille système native dans l'environnement de test (le point
d'injection introduit au Lot 7 reste utilisé).

## Accessibilité minimale

Audit rapide des CTAs principaux : tous portent un label `Text` clair,
qui alimente automatiquement l'arbre `Semantics` côté Flutter. Aucun
ajout de `Semantics` explicite jugé nécessaire :

- `Révéler le tirage` / `Révéler mon message` — `ElevatedButton.icon`
  avec label texte.
- `Partager ce message` — `OutlinedButton.icon` avec label texte.
- `Faire un autre tirage` — `OutlinedButton.icon` avec label texte.
- `Découvrir mon message` / `Faire un tirage 3 cartes` /
  `Découvrir les cartes` — boutons accueil, labels texte explicites.

Les icônes intégrées aux boutons (`Icons.auto_awesome`,
`Icons.ios_share`, `Icons.refresh`, `Icons.chevron_right`) sont
purement décoratives à côté d'un label visible — un `semanticLabel`
supplémentaire serait redondant.

Contrastes principaux : tous au-delà de 7:1
(charcoal/ivory, deepGreen/ivory). Le doré doux reste réservé aux
accents (chips, encarts), jamais au corps du texte.

## Limites connues

- Le test « 3 cartes 320×568 » ne valide que la première position parce
  que la `ListView` du `_RevealedState` ne rend pas les éléments hors
  écran. C'est volontaire et reflète le comportement réel — les autres
  positions s'affichent par scroll.
- Le `minHeight: constraints.maxHeight - 40` est une marge empirique
  pour la `SafeArea` et l'`AppBar` ; une approche plus rigoureuse
  serait de lire `MediaQuery.padding` dans le builder, mais l'écart de
  rendu est invisible et l'overhead n'est pas justifié à ce stade.
- Le mode sombre n'existe toujours pas dans l'app, donc aucun test ne
  le couvre.
- Sur viewport très étroit (< 280 px), des artefacts subsistent
  probablement sur la fiche carte ; pas de cible commerciale identifiée
  sous 320 px, donc hors scope.
- L'écran tirage et la fiche détail utilisent désormais la même
  apparence d'encart, mais conservent leurs **labels propres**
  (CONSEIL côté tirage, INVITATION côté fiche). Décision volontaire :
  ces labels portent du sens éditorial différent et ne doivent pas être
  unifiés.

## Prochaine étape recommandée

Lot 10 — Navigation latérale dans la fiche carte et animations légères :

1. Permettre de naviguer entre cartes depuis la fiche (swipe ou
   flèches précédent/suivant) sans repasser par la liste.
2. Petite transition `Hero` sur le `CardArtPlaceholder` entre la
   bibliothèque et la fiche.
3. Audit `Semantics` ciblé sur la fiche détail si les sections doivent
   être lues comme un tout par les lecteurs d'écran.
4. Choix d'un provider analytics respectueux de la vie privée — à
   valider avant toute instrumentation. Toujours en attente depuis le
   Lot 4.
