# Lot 13 — Cartes validées et lectures par position

## Objectif

Mettre à jour les **8 premières cartes** des arcanes majeurs avec la
voix Pile ou Face validée (bienveillante mais franche), et ouvrir le
modèle à une **lecture par position** dans le tirage 3 cartes (`Là où
tu en es / L'énergie du moment / Le conseil`).

L'app reste offline, sans nouvelle dépendance, sans backend, sans
analytics.

## Cartes mises à jour

Les huit arcanes suivants sont mis à jour avec les textes verbatim du
brief produit :

- Le Mat
- Le Bateleur
- La Papesse
- L'Impératrice
- L'Empereur
- Le Pape
- Les Amoureux
- Le Chariot

Pour chacune, les huit champs éditoriaux principaux ont été remplacés
(`meaning_upright`, `short_message`, `advice`, `warning`, `love`,
`work`, `money`, `share_message`), et une nouvelle structure
`spread_meanings` a été ajoutée avec les trois textes de position.

Les 14 autres arcanes (de La Justice à Le Monde) **ne sont pas
touchés** : ni en éditorial, ni en structure (pas de `spread_meanings`
ajouté).

## Structure `spread_meanings`

Nouveau champ optionnel au niveau de chaque carte, présent uniquement
sur les cartes validées :

```json
"spread_meanings": {
  "where_you_are": "…",
  "current_energy": "…",
  "advice": "…"
}
```

- `where_you_are` ↔ position « Là où tu en es » (slot 0).
- `current_energy` ↔ « L'énergie du moment » (slot 1).
- `advice` ↔ « Le conseil » (slot 2). À ne pas confondre avec le champ
  `advice` au niveau racine de la carte, qui alimente le panneau
  `LE PETIT MOT` (la garde reste séparée — sens différents,
  validation éditoriale distincte).

## Modèle Dart

- Nouveau `TarotSpreadMeanings` dans
  [lib/features/tarot/models/tarot_spread_meanings.dart](../../lib/features/tarot/models/tarot_spread_meanings.dart),
  avec `whereYouAre`, `currentEnergy`, `advice` et un constructeur
  `fromJson`.
- `TarotCard` expose `final TarotSpreadMeanings? spreadMeanings;` (nullable).
- `TarotCard.fromJson` lit la clé `spread_meanings` quand elle est un
  `Map<String, dynamic>`, sinon laisse `null`. Aucune carte n'est
  imposée d'avoir le champ.

## Stratégie cartes non encore validées

**Option retenue** : `spread_meanings` est **nullable**, le rendu
retombe sur le body existant (meaning / love / work / money) quand le
champ n'est pas présent.

Justifications :

- L'alternative recommandée par le brief (peupler les 22 cartes avec
  des fallback) demandait de rédiger 14 × 3 = 42 textes hors voix
  validée. Trop risqué éditorialement.
- La forme nullable préserve l'intégrité : on ne prétend pas avoir un
  contenu validé là où il n'existe pas.
- L'expérience utilisateur reste cohérente : sur une carte non
  validée, le tirage 3 cartes affiche le `meaning` ou la lecture de
  domaine (love/work/money), comme avant ce lot.
- Les tests d'intégrité couvrent les deux régimes : « si présent, les
  trois champs sont non vides » + « les 8 cartes validées doivent
  carrément avoir le champ ».

## Affichage dans le tirage 3 cartes

`DrawnCardView` reçoit deux nouveaux contextes :

- `positionIndex: int?` — slot 0, 1 ou 2 dans le tirage 3 cartes.
- `intent: ReadingIntent?` — déjà existant depuis le Lot 11.

Règle de rendu retenue :

1. **Body principal** :
   - Si la carte a `spread_meanings` **et** `positionIndex != null` →
     le texte de la position correspondante est utilisé comme corps
     principal.
   - Sinon, fallback : `intent.love/work/money` ou `meaning_upright/
     reversed` selon l'intent (comportement Lot 11).
2. **Complément de domaine** (love/work/money seulement) :
   - Affiché **uniquement** quand un body de position vient d'être
     rendu **et** que l'intent est love/work/money.
   - Petit label small caps `EN AMOUR` / `AU TRAVAIL` /
     `CÔTÉ ARGENT` suivi du body de domaine (`card.love/work/money`).
   - Sur une carte non validée en mode love/work/money, le body de
     domaine reste le corps principal (pas de duplication, pas de
     section complémentaire vide).

Ordre visuel final dans un tirage question 3 cartes (carte validée +
intent domaine) :

1. chip de position
2. art placeholder
3. nom + orientation
4. mots-clés
5. short_message (accent doré)
6. body de position (depuis spread_meanings)
7. complément de domaine (EN AMOUR / AU TRAVAIL / CÔTÉ ARGENT + body)
8. LE PETIT MOT (card.advice)
9. À GARDER À L'ESPRIT (card.warning)

Le tirage du jour (1 carte, intent null) ne montre ni le chip de
position ni les blocs de domaine — comportement inchangé.

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.5s)`
- `flutter test` : `+57 All tests passed!` (54 → 57, +3 nouveaux).

Détail :

- **Parsing** (`tarot_repository_test`) : la fixture porte désormais
  `spread_meanings` sur Le Mat et reste absente sur Le Bateleur ; les
  assertions vérifient les trois champs parsés et la valeur `null`
  sur l'autre carte.
- **Intégrité** (`major_arcana_integrity_test`, +2 tests) :
  - les 8 cartes validées doivent avoir `spread_meanings != null` ;
  - quand `spread_meanings` est présent, ses trois champs sont
    `non-empty`.
- **Affichage tirage** (`reading_screen_test`, 1 nouveau + 1
  retouché) :
  - le body de position est rendu en mode general ;
  - en mode love, le body de position est le principal **et** le
    label `EN AMOUR` apparaît au-dessus du body de domaine ;
  - les autres labels (`AU TRAVAIL`, `CÔTÉ ARGENT`) ne fuitent pas en
    général.

L'editorial guard couvre toujours `meaning_upright/reversed`, `love`,
`work`, `money`, `advice`, `warning`, `short_message`,
`share_message` mais **pas** `spread_meanings` à ce stade — voir
limites connues.

## Adaptation mineure du texte brief

Le `warning` du Chariot fourni par le brief contenait littéralement
« où tu vas », ce qui déclencherait la regex `tu vas` de la garde
éditorial existante (faux positif sémantique connu, déjà rencontré au
Lot 11). La phrase est reformulée a minima en « où tu veux aller »
pour rester compatible avec la garde, sans changer le sens.

## Limites connues

- 14 cartes restent à valider éditorialement ; tant que `spread_meanings`
  est `null` pour elles, le rendu de tirage 3 cartes reproduit le
  comportement Lot 11. Pas de régression utilisateur, juste un niveau
  de granularité plus faible sur ces cartes.
- La garde éditoriale (`major_arcana_editorial_guard_test`) ne scanne
  pas encore les champs `spread_meanings.*`. Ajout simple à prévoir
  avant la validation des cartes restantes pour éviter les
  régressions tonales.
- La logique de rendu ignore l'orientation pour `spread_meanings.*` :
  les textes de position sont écrits sans variante sens inversé. Pour
  les cartes non validées, l'orientation continue de piloter
  `meaning_upright` vs `meaning_reversed`.
- `LE PETIT MOT` peut afficher le `card.advice` (général à la carte)
  en même temps que `spread_meanings.advice` apparaît comme body
  principal sur le slot « Le conseil ». Les deux textes sont
  volontairement distincts (le brief les a séparés), mais une future
  passe pourrait fusionner si la redondance est jugée gênante en
  production.
- La fixture du `reading_screen_test` est désormais enrichie
  (`spread_meanings` sur les trois cartes synthétiques) — sans
  conséquence sur les autres suites.

## Prochaine étape recommandée

Lot 14 — Continuation éditoriale et garde-fous :

1. Valider les 14 arcanes restants avec la même structure (texte
   éditorial + `spread_meanings`), en respectant la voix
   « bienveillante mais franche ».
2. Étendre l'editorial guard pour scanner aussi
   `spread_meanings.{where_you_are, current_energy, advice}` contre les
   tournures proscrites.
3. Audit `Semantics` ciblé sur la section domaine complémentaire
   (label small caps + body) pour les lecteurs d'écran.
4. Choix d'un provider analytics respectueux de la vie privée — en
   attente depuis le Lot 4.
