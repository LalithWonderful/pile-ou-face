# Lot 15 — Finalisation des 22 arcanes majeurs Pile ou Face

## Objectif

Boucler la validation éditoriale des arcanes majeurs en remplaçant les
textes des **6 dernières cartes** avec la voix Pile ou Face, et
verrouiller l’intégrité de la nouvelle structure `spread_meanings` sur
les 22 cartes.

À la fin du Lot 15, **toutes les 22 cartes** ont :
- des textes éditoriaux Pile ou Face (`meaning_upright`,
  `short_message`, `advice`, `warning`, `love`, `work`, `money`,
  `share_message`),
- un bloc `spread_meanings.{where_you_are, current_energy, advice}`
  non vide,
- la même couverture par la garde éditoriale étendue au Lot 14.

L’app reste offline, sans nouvelle dépendance, sans backend, sans
analytics.

## Cartes mises à jour

Six arcanes finalisés ce lot (verbatim du brief produit) :

- La Maison Dieu (`la_maison_dieu`)
- L’Étoile (`l_etoile`)
- La Lune (`la_lune`)
- Le Soleil (`le_soleil`)
- Le Jugement (`le_jugement`)
- Le Monde (`le_monde`)

Pour chacune, les 8 champs éditoriaux principaux ont été remplacés et
la structure `spread_meanings` a été ajoutée avec ses trois textes de
position.

Les 16 cartes validées aux Lots 13-14 ne sont pas touchées. Les `id`
et `name` restent inchangés (même politique que les lots précédents :
on ne migre pas l’identifiant interne, on aligne uniquement le corps
éditorial).

## Confirmation 22/22

```
grep -c '"spread_meanings":' assets/tarot/major_arcana.json  →  22
```

L’assertion d’intégrité passe désormais sur l’ensemble des cartes :
```dart
test('all 22 major arcana now carry spread_meanings (Lot 15: 22/22)',
    () {
  for (final c in cards) {
    expect(c.spreadMeanings, isNotNull,
        reason: '${c.id} must carry spread_meanings');
  }
});
```

Le test « when spread_meanings is present, all three position fields
are non-empty » continue de couvrir les trois sous-champs.

## Stratégie `TarotCard.spreadMeanings`

**Option retenue : on conserve le champ nullable** au niveau du modèle
Dart pour ce Lot 15. Justifications :

1. **Minimiser le risque** : rendre le champ obligatoire forcerait à
   mettre à jour toutes les fixtures de test (`tarot_repository_test`,
   `daily_share_text_builder_test`, `home_screen_test`,
   `card_detail_screen_test`, `daily_reading_service_test`,
   `tarot_draw_service_test`, `reading_screen_test`), dont certaines
   construisent encore des `TarotCard` synthétiques sans
   `spread_meanings`.
2. **Découpler contenu et structure** : ce lot est strictement
   éditorial. Migrer le modèle en non-nullable mérite son propre lot
   technique, avec sa propre revue.
3. **Préserver le test repository** : il valide actuellement à la fois
   le cas `spread_meanings` présent (Le Mat de la fixture) et absent
   (Le Bateleur de la fixture). C’est utile tant que le code
   d’affichage gère encore le fallback nullable, et ça reste vrai
   après ce lot.

Côté **production**, le JSON livré n’a plus aucune carte sans
`spread_meanings`. Le code d’affichage qui retombe sur le fallback
(`meaning_upright/reversed` ou `love/work/money`) ne sera donc jamais
sollicité en production sur des fichiers livrés. Le fallback reste un
filet de sécurité pour les tests synthétiques et pour une éventuelle
migration future du JSON.

**Recommandation future** : un mini-lot technique dédié pourra
basculer `spreadMeanings` en non-nullable (`required` au constructeur,
parsing strict, fixtures de tests adaptées). À faire seulement si la
valeur ajoutée justifie le tour de mise à jour mécanique.

## Micro-adaptations liées à la garde éditoriale

Une seule cible sur ce lot :

- **Le Soleil — `meaning_upright`** : la phrase brief « tu vois mieux
  où tu vas, ce que tu veux, et ce que tu ne veux plus. » contenait
  « tu vas » dans un sens locatif, ce qui déclencherait la regex
  `tu vas` de la garde éditoriale (faux positif sémantique connu).
  Reformulé en : « tu vois mieux où tu te diriges, ce que tu veux, et
  ce que tu ne veux plus. ». Sens préservé, ton conservé. Même
  méthode que Lot 11 (Chariot money), Lot 13 (Chariot warning) et
  Lot 14 (Tempérance meaning_upright).

Aucune autre adaptation requise sur les 6 cartes : la garde étendue
introduite au Lot 14 a vérifié à la fois les champs racine et les
trois sous-champs `spread_meanings.*` sans soulever d’autre alerte.

## Tests adaptés

- **`major_arcana_integrity_test.dart`** : le test
  `validatedIds` (Lots 13-14) devient une assertion universelle.
  L’intitulé reflète la fin de la campagne (« Lot 15: 22/22 »). Les
  autres tests d’intégrité (numéros 0..21, ids uniques, champs texte
  non vides, mots-clés non vides, sous-champs `spread_meanings`
  non vides) restent inchangés et passent toujours.
- **`major_arcana_editorial_guard_test.dart`** : déjà étendu au
  Lot 14, scanne `spread_meanings.*` pour les 22 cartes — aucune
  modification nécessaire ici, ce qui prouve que l’extension du Lot 14
  était la bonne porte d’entrée.
- Aucun nouveau test ajouté : la couverture comportementale du Lot 13
  sur l’affichage 3 cartes reste suffisante (texte de position rendu
  comme corps principal, complément de domaine).

Résultats : `flutter analyze` clean, `flutter test` `+57 All tests
passed!`.

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.5s)`
- `flutter test` : `+57 All tests passed!`

Total inchangé (57) : un test resserré, aucun ajout, aucun retrait.

## Limites connues

- **Modèle nullable** : `TarotCard.spreadMeanings` reste typé `?` alors
  que le JSON livré n’a plus aucun champ absent. Décision documentée
  ci-dessus ; à reconsidérer dans un mini-lot dédié.
- **Pas de relecture humaine externe** sur ce dernier lot ; la garde
  automatique protège contre les régressions de voix mais ne remplace
  pas une passe rédactionnelle finale.
- **Le `name` JSON** des arcanes XIII et XIV reste `La Mort` /
  `La Tempérance` côté JSON alors que le corps éditorial peut les
  désigner sous d’autres formes (« L’Arcane sans nom » / « Tempérance »).
  Volontaire pour ne pas migrer les `name` au passage.
- **Pas de test linguistique** spécifique pour les nouveaux
  vocabulaires introduits ce lot (« Maison Dieu » avec ou sans tiret,
  « Tour », etc.). La garde éditoriale traite uniquement les motifs
  proscrits — pas les variantes orthographiques.

## Prochaine étape recommandée

Lot 16 — Audit final et préparation à la publication :

1. Passer `TarotCard.spreadMeanings` en non-nullable si la mise à jour
   mécanique des fixtures reste sous contrôle (mini-lot technique).
2. Relecture humaine des 22 cartes pour homogénéiser le ton (rythme,
   apostrophes, point médian, longueur des phrases).
3. Audit `Semantics` ciblé sur la grille d’intents et le complément
   de domaine pour les lecteurs d’écran.
4. Choix d’un provider analytics respectueux de la vie privée — en
   attente depuis le Lot 4.
5. Préparer un check-list de publication (icône, splash, métadonnées
   stores, captures d’écran).
