# Lot 14 — Deuxième vague de cartes validées et garde éditoriale étendue

## Objectif

Poursuivre la validation éditoriale des arcanes majeurs en remplaçant
les textes des **8 cartes suivantes** avec la voix Pile ou Face
(bienveillante mais franche), et ajouter pour chacune le bloc
`spread_meanings` introduit au Lot 13.

En parallèle, la garde éditoriale automatique est étendue pour scanner
aussi les sous-champs `spread_meanings.*`, afin que la voix soit
protégée sur toute la profondeur du JSON.

L'app reste offline, sans nouvelle dépendance, sans backend, sans
analytics.

## Cartes mises à jour

Les huit arcanes suivants reçoivent le texte verbatim du brief
(`meaning_upright`, `short_message`, `advice`, `warning`, `love`,
`work`, `money`, `share_message`) et la structure `spread_meanings`
(trois textes de position) :

- La Force (`la_force`)
- L'Hermite (`l_ermite`)
- La Roue de Fortune (`la_roue_de_fortune`)
- La Justice (`la_justice`)
- Le Pendu (`le_pendu`)
- La Mort (`la_mort`, le texte parle de « L'Arcane sans nom »)
- La Tempérance (`la_temperance`, le texte parle de « Tempérance »)
- Le Diable (`le_diable`)

Les `id` et `name` sont **inchangés** conformément à la consigne :
- l'arcane 13 garde `name="La Mort"` même si le corps éditorial le
  désigne comme L'Arcane sans nom.
- l'arcane 14 garde `name="La Tempérance"` même si le corps éditorial
  l'appelle Tempérance.

Les autres champs hors cible (`meaning_reversed`, `keywords_upright`,
`keywords_reversed`, `image_path`, `tags`) sont conservés.

Les 8 cartes du Lot 13 ne sont pas touchées. Les **6 cartes restantes**
(La Maison-Dieu, L'Étoile, La Lune, Le Soleil, Le Jugement, Le Monde)
ne sont pas touchées non plus.

## Structure `spread_meanings` (rappel)

```json
"spread_meanings": {
  "where_you_are": "…",     // position 0 — « Là où tu en es »
  "current_energy": "…",    // position 1 — « L'énergie du moment »
  "advice": "…"             // position 2 — « Le conseil »
}
```

Champ optionnel au niveau de chaque carte. La stratégie nullable +
fallback retenue au Lot 13 reste inchangée.

## Stratégie fallback / cartes non validées

Inchangée :
- `TarotCard.spreadMeanings` reste nullable.
- Les **6 cartes** non encore validées (16 → 22) gardent
  `spreadMeanings == null` ; en tirage 3 cartes leur body retombe sur
  `meaning_upright/reversed` ou sur `love/work/money` selon l'intent
  (comportement Lot 11/13).
- Une amélioration utilisateur n'apparaît que sur les cartes validées.

Conséquence : si un tirage 3 cartes mélange validées et non validées,
chaque carte affiche son meilleur niveau de détail disponible, sans
mélange visuel ni écran bigarré.

## Adaptation éditoriale liée à la garde

La phrase brief de Tempérance — « tu vas finir par t'épuiser » —
déclenchait la regex `tu vas` de l'editorial guard
(`major_arcana_editorial_guard_test`). Adaptation minimale appliquée :

- **Avant** : « Si tu passes d'un extrême à l'autre, tu vas finir par
  t'épuiser. »
- **Après** : « Si tu passes d'un extrême à l'autre, tu risques de
  t'épuiser. »

Le sens (« deux extrêmes → épuisement ») est conservé. La forme passe
de prédictif (« tu vas finir ») à probable / conditionnel (« tu
risques de »), ce qui s'aligne avec la voix Pile ou Face : non
prédictive, jamais d'affirmation absolue. Même méthode que Lot 11 et
Lot 13 pour Le Chariot.

Aucun autre faux positif détecté sur les 8 cartes de ce lot.

## Garde éditoriale étendue

[test/features/tarot/assets/major_arcana_editorial_guard_test.dart](../../test/features/tarot/assets/major_arcana_editorial_guard_test.dart)
scannait jusque-là les neuf champs textuels racine. Le test parcourt
désormais aussi les trois sous-champs de `spread_meanings` quand ils
sont présents.

Pratiquement, pour chaque carte le test construit une liste de
`{label_lisible: contenu}` qui inclut :
- `meaning_upright`, `meaning_reversed`,
- `love`, `work`, `money`,
- `advice`, `warning`,
- `short_message`, `share_message`,
- `spread_meanings.where_you_are`,
- `spread_meanings.current_energy`,
- `spread_meanings.advice`.

Tous les motifs interdits historiques (`tu vas`, `vous allez`,
`cela va arriver`, `c'est certain`, `ton destin`, `mauvais présage`,
`les cartes disent`, `tu dois absolument`, `il faut absolument`,
`prédit`, `prédiction certaine`, `voyance`…) couvrent désormais
**tous** les contenus éditoriaux des cartes, pas juste la racine.

## Intégrité JSON

[test/features/tarot/assets/major_arcana_integrity_test.dart](../../test/features/tarot/assets/major_arcana_integrity_test.dart)
voit sa liste `validatedIds` passer de 8 à 16 ids. Les 16 cartes
validées doivent donc avoir `spread_meanings != null` ; les 6
restantes restent autorisées à le laisser à `null`.

Le test « when spread_meanings is present, all three position fields
are non-empty » s'applique à toutes les cartes, et reste vert sur les
16 nouveaux jeux de textes.

Vérification rapide :
```
grep -c '"spread_meanings":' assets/tarot/major_arcana.json  →  16
```

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.5s)`
- `flutter test` : `+57 All tests passed!`

Le total reste à 57 : pas de test ajouté, deux tests étendus
(garde éditoriale + liste des cartes validées), 8 cartes
réécrites. Tout passe, aucune régression.

## Limites connues

- 6 cartes restent à valider éditorialement : La Maison-Dieu,
  L'Étoile, La Lune, Le Soleil, Le Jugement, Le Monde. Tant que leur
  `spread_meanings` est `null`, le rendu de tirage 3 cartes reproduit
  le comportement Lot 11 pour elles (meaning ou domaine).
- L'arcane XIII conserve son nom JSON `La Mort` alors que le corps
  éditorial l'appelle systématiquement « L'Arcane sans nom ». Idem
  pour l'arcane XIV (`La Tempérance` côté JSON, « Tempérance » dans
  le corps). C'est volontaire : pas de migration d'id, pas de
  renaming, et l'UI affiche le `name` racine en titre.
- La garde éditoriale reste basée sur regex ; elle n'analyse pas le
  contexte sémantique. Les faux positifs locatifs type
  « où tu vas » continueront de demander une micro-adaptation
  manuelle si une rédactrice les utilise. Le pattern d'adaptation
  est stable (« où tu vas » → « où tu veux aller », « tu vas finir
  par » → « tu risques de »).
- Aucune relecture humaine externe n'a été menée sur ce lot ; la
  garde automatique protège contre les régressions de voix mais ne
  remplace pas une passe finale.

## Prochaine étape recommandée

Lot 15 — Dernière vague éditoriale + audits :

1. Valider les 6 derniers arcanes (Maison-Dieu, Étoile, Lune, Soleil,
   Jugement, Monde) avec la même structure et la garde étendue
   active.
2. Une fois les 22 validées, basculer `validatedIds` de l'integrity
   test en assertion universelle (« toutes les cartes doivent avoir
   `spread_meanings` ») et envisager de rendre le champ obligatoire
   au niveau du modèle Dart.
3. Audit `Semantics` ciblé sur le complément de domaine pour les
   lecteurs d'écran (le label small caps doit être annoncé comme
   « introduit la lecture domaine » et non comme un titre nu).
4. Choix d'un provider analytics respectueux de la vie privée — en
   attente depuis le Lot 4.
