# Lot 5 — Partage du message du jour

## Objectif

Permettre à l’utilisateur·rice de partager son **message du jour** vers
n’importe quelle app du système (Messages, Mail, Notes, réseaux sociaux,
etc.) à partir du champ `share_message` désormais aligné sur la voix
Pile ou Face (Lots 4A puis 4C).

Le partage est limité au tirage du jour. Le tirage libre 3 cartes ne
propose pas de partage à ce stade — décision documentée plus bas.

L’app reste offline, aucun nouveau service distant n’est introduit, et
aucune mesure d’usage n’est ajoutée.

## Dépendance ajoutée

```yaml
share_plus: ^13.1.0
```

API utilisée (13.x) :

```dart
await SharePlus.instance.share(ShareParams(text: text));
```

Aucun autre paquet ajouté. Les plumbings natifs (iOS/Android) sont gérés
par le plugin lui-même via `flutter pub get`.

## Format exact du texte partagé

```
Pile ou Face avait un message pour moi aujourd’hui :

{share_message}

Libre à moi de l’interpréter.
```

- Bloc d’intro (1 ligne), ligne vide, `share_message` (1 ligne ou plus
  selon la carte), ligne vide, signoff (1 ligne).
- Apostrophes typographiques (`’`) homogènes avec le reste de l’app.
- Aucune mention de voyance, de prédiction, de destin, ou de promesse
  d’avenir.
- Aucun lien `App Store` / `Play Store` ajouté pour l’instant (pas
  encore disponible).
- Pas de hashtag, pas de mention de la marque autre que la phrase
  d’intro — c’est l’utilisateur·rice qui parle (« moi »), pas l’app.

## Choix produit

- **Bouton visible uniquement après révélation** : `_DailyFooter` est
  rendu après le ListView des cartes, donc le bouton n’apparaît pas tant
  que `_result == null`.
- **Libellé** : `Partager ce message` — court, descriptif, sans
  promesse.
- **Icône** : `Icons.ios_share` (cohérente avec l’iconographie système
  iOS, neutre sur Android).
- **Mode quotidien uniquement** : pas de partage sur le tirage libre 3
  cartes. Raisons : la carte du jour est singulière, identifiée,
  partageable en une phrase ; un tirage 3 cartes ouvert n’a pas encore
  de format de partage clair (passé / présent / futur n’existent plus,
  c’est *Situation / Énergie / Conseil*) et risquerait de devenir
  trop long ou trop ambigu. À ré-évaluer dans un lot ultérieur si
  l’usage le justifie.
- **Pas de partage automatique** : le partage est toujours déclenché
  explicitement par tap utilisateur.
- **Pas d’image PNG** : on partage un texte natif, pas une image
  générée. Ça reste universellement compatible et léger.
- **Pas d’écran Paramètres** ni d’exposition de `clearToday()` dans
  l’UI (volontairement hors scope).
- **Pas de tracking** : aucune mesure n’est collectée sur les partages.

## Isolation du texte partagé

Le format est construit par une fonction pure
[lib/features/tarot/services/daily_share_text_builder.dart](../../lib/features/tarot/services/daily_share_text_builder.dart) :

```dart
String buildDailyShareText(DrawnCard drawn) {
  final shareMessage = drawn.card.shareMessage.trim();
  return 'Pile ou Face avait un message pour moi aujourd’hui :\n\n'
      '$shareMessage\n\n'
      'Libre à moi de l’interpréter.';
}
```

- Pure, sans dépendance sur Flutter, `SharedPreferences` ou
  `share_plus` ⇒ testable directement.
- `trim()` sur le `share_message` pour éviter les surprises si le JSON
  introduit une marge involontaire.
- Aucune autre logique métier : pas de format différent selon
  l’orientation (droit / inversé), pas de partage du `meaning` long,
  pas de prefixe carte. Volontairement minimal pour rester aligné sur
  l’audit Kimi.

L’invocation du partage natif vit dans `_DailyFooter._share` :

```dart
Future<void> _share() async {
  final text = buildDailyShareText(drawn);
  await SharePlus.instance.share(ShareParams(text: text));
}
```

Cette séparation permet de tester le format **sans** mocker
`share_plus`, et de garder `share_plus` confiné à un seul appel dans
toute l’app.

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.4s)`
- `flutter test` : `+33 All tests passed!`

Nouvelles suites :

- `daily_share_text_builder_test.dart` (**5 tests**) :
  - le `share_message` est bien embarqué dans le texte ;
  - les deux lignes éditoriales d’encadrement sont présentes ;
  - le layout final est exactement intro + ligne vide + share_message +
    ligne vide + signoff ;
  - aucune tournure de voyance (`les cartes disent`, `ton destin`,
    `mauvais présage`, `voyance`, `tu vas`, `c’est certain`) ;
  - les espaces de bord du `share_message` sont retirés.
- `reading_screen_test.dart` (**3 tests ajoutés**, total 6) :
  - daily — idle : le bouton `Partager ce message` n’est pas dans le
    DOM ;
  - daily — après révélation : `scrollUntilVisible` puis assertion sur
    la présence du bouton ;
  - free 3 cartes — après révélation : le bouton n’est pas exposé.

Aucun test ne tape réellement le bouton de partage : `SharePlus.instance`
ouvrirait une feuille système indisponible en test. Le builder est testé
indépendamment, ce qui suffit.

## Limites connues

- Pas de **partage par image** (capture PNG des cartes) : tout est
  texte. Plus simple, plus léger, mais visuellement moins immersif.
- Pas de **deep link** retour vers l’app dans le texte partagé : sera
  ajouté quand l’app aura une URL universelle (post-publication).
- Pas de partage sur le **tirage libre 3 cartes** : la décision est
  documentée ci-dessus et reste réversible.
- Pas d’**aperçu enrichi** (titre, description, image) : `share_plus`
  envoie du texte simple, certains réseaux sociaux n’en font pas une
  carte aussi visible qu’un lien.
- Pas de **mesure** des partages : impossible pour le moment de savoir
  combien de personnes utilisent réellement la fonctionnalité.
- L’icône `Icons.ios_share` est lue comme « partager » côté iOS mais
  est moins universelle sur Android — un test utilisateur·rice ciblé
  permettrait d’arbitrer entre `Icons.ios_share`, `Icons.share` et
  `Icons.share_outlined`.

## Prochaine étape recommandée

Lot 6 — Détail carte et confort de lecture :

1. Écran de détail carte accessible depuis la bibliothèque, qui
   réutilise `love`, `work`, `advice`, `warning` désormais alignés sur
   la voix Pile ou Face.
2. Réutiliser le bouton `Partager ce message` sur l’écran détail, avec
   le même format que le partage quotidien (ou une variante explicite
   « depuis la bibliothèque »).
3. Audit accessibilité minimal (tailles, contrastes, libellés
   `Semantics`) avant publication.
4. **Optionnel** : test linguistique automatisé qui parse le JSON et
   échoue sur les chaînes prohibées (`tu vas`, `c’est certain`,
   `ton destin`, `mauvais présage`, `tu dois absolument`) — protège la
   voix contre les régressions futures.
5. Choix d’un provider analytics respectueux de la vie privée (à
   valider avant d’instrumenter quoi que ce soit, y compris le partage).
