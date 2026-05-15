# Lot 4C — Renforcer la franchise éditoriale avant partage

## Objectif

L'audit Kimi sur le Lot 4A a relevé que la voix Pile ou Face penchait
parfois trop côté « douceur » au prix de la franchise : certains textes
étaient devenus vagues, abstraits, ou trop génériques. Avant le Lot 5
(partage), une passe ciblée remet la **tension utile** de chaque carte là
où elle s'était estompée — sans rebasculer dans la prédiction, ni la
peur, ni la culpabilité.

Périmètre strictement éditorial : 13 corrections de champs sur 9 cartes du
JSON + 2 micro-textes UI. Pas de réécriture totale, pas de nouvelle
dépendance, pas de changement d'architecture ou de logique de tirage.

## Ligne « bienveillante mais franche »

L'app :
- ne prédit pas, ne fait pas de voyance, ne culpabilise pas, ne fait pas
  peur ;
- **doit dire quelque chose de concret** et garder le sens réel des
  cartes ;
- peut poser une question qui pique un peu ;
- ne doit pas devenir molle, vague, abstraite ou hypocrite.

Mots forts gardés quand ils servent : *vérité intérieure, limite, peur,
désir, rupture, blocage, attachement, fin, choix, effondrement, lucidité*.

Mots / tournures toujours évités : *tu vas, cela va arriver, c'est
certain, les cartes disent que, ton destin, mauvais présage, tu dois
absolument*.

`advice` et `warning` n'ont pas été retouchés : l'audit les considère
comme la part la plus solide du fichier.

## Cartes / champs modifiés

| Carte             | Champ              | Type de correction                                    |
| ----------------- | ------------------ | ----------------------------------------------------- |
| La Justice        | `meaning_upright`  | Question franche au lieu d'une formule plate.         |
| La Justice        | `share_message`    | Phrase de partage qui assume la tension de la carte.  |
| Le Jugement       | `meaning_upright`  | Sortie de l'abstrait, refus du « faire semblant ».    |
| La Lune           | `meaning_upright`  | Le flou est nommé, la décision dans le flou refusée.  |
| La Maison-Dieu    | `meaning_upright`  | Effondrement nommé, sans dramatisation.               |
| Le Mat            | `share_message`    | Retrait de « doux », envie crue assumée.              |
| Le Diable         | `share_message`    | Retrait de « conscientiser », lucidité concrète.      |
| L'Étoile          | `share_message`    | Image incarnée au lieu d'un « peu d'espoir » abstrait.|
| Le Chariot        | `meaning_upright`  | Retrait du « les forces s'alignent toutes seules ».   |
| Le Chariot        | `short_message`    | Alignement franchise / `meaning_upright`.             |
| Le Pape           | `meaning_upright`  | Retrait de « éclairer le chemin », écouter ≠ accepter.|
| La Papesse        | `meaning_upright`  | Retrait de « presser les questions ».                 |
| La Tempérance     | `share_message`    | Triangulation explicite : ni casser, ni supporter.    |

## Exemples avant / après

### La Justice — `meaning_upright`
- **Avant** : « Tu peux regarder la situation telle qu'elle est, sans
  dramatiser ni complaire. Remettre les choses d'aplomb, doucement. »
- **Après** : « Ce message te ramène à une question simple : qu'est-ce
  qui est juste, au fond, même si ce n'est pas le plus confortable ? »

### Le Jugement — `meaning_upright`
- **Avant** : « Quelque chose en toi appelle, plus pleinement. Tu peux y
  répondre, sans avoir à tout comprendre d'un coup. »
- **Après** : « Quelque chose t'appelle depuis longtemps. Ce n'est pas
  trop tard — mais ce n'est plus le moment de faire semblant. »

### La Lune — `meaning_upright`
- **Avant** : « Tes émotions, tes rêves, ton intuition portent un
  message. Tu peux les écouter sans tout vouloir décoder. »
- **Après** : « Tu n'as pas toutes les cartes en main — et c'est normal.
  Ce message te demande de ne pas décider dans le flou. »

### La Maison-Dieu — `meaning_upright`
- **Avant** : « Quelque chose se redéfinit, peut-être un peu brusquement,
  et pourtant ça libère. Ce qui ne tenait plus debout cesse de te
  demander des efforts. »
- **Après** : « Ce qui tenait debout vacille. Ce n'est pas une punition —
  c'est l'occasion de sortir de ce qui t'étouffait. »

### Le Diable — `share_message`
- **Avant** : « Aujourd'hui, Le Diable m'invite à regarder ce qui me
  retient, avec douceur. »
- **Après** : « J'ai tiré Le Diable — et je commence à voir ce qui me
  tient, même quand je prétends le choisir. »

## Micro-textes UI

Deux ajustements dans
[lib/features/tarot/presentation/screens/reading_screen.dart](../../lib/features/tarot/presentation/screens/reading_screen.dart) :

- Label du bouton CTA pendant le chargement : `Révélation…` → `Un instant…`.
  Le mot « Révélation » sentait l'orchestre ; « Un instant » assume le
  délai sans en faire un événement mystique.
- Hint de l'état idle du tirage libre 3 cartes :
  `Prenez un instant, puis révélez votre tirage.` →
  `Prends un instant, puis révèle ton tirage.`
  Aligne tout l'idle sur le tutoiement qui était déjà la règle ailleurs.

Aucun autre vouvoiement résiduel détecté dans `lib/` après cette passe.

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.1s)`
- `flutter test` : `+26 All tests passed!`

Aucun test n'a été ajouté ni modifié. Les tests d'intégrité du JSON
(`major_arcana_integrity_test.dart`) continuent de garantir
- 22 cartes présentes,
- numéros 0..21 uniques,
- ids uniques,
- tous les champs texte critiques non vides,
- listes `keywords_upright`, `keywords_reversed`, `tags` non vides.

Un test linguistique automatisé (qui bloquerait la réapparition
d'expressions proscrites) reste optionnel pour le Lot 5.

## Limites connues

- Pas de relecture professionnelle externe ; la franchise gagne en netteté
  mais une passe humaine reste utile avant publication large.
- Les `advice` et `warning` n'ont pas été retouchés : si une future
  relecture les jugeait trop sages, un Lot 4D ciblé pourrait suivre la
  même méthode.
- Le ton reste uniforme pour les 22 cartes ; pas de variation
  matin / soir ou par contexte.
- Le hint « Prends un instant, puis révèle ton tirage. » ne s'applique
  qu'au tirage libre. En mode daily, le hint reste « Libre à toi de
  l'interpréter. » et n'est pas concerné par cette passe.

## Prochaine étape recommandée

Lot 5 — Partage et instrumentation minimale, plan inchangé :

1. Brancher un partage natif à partir de `share_message` (introduction
   éventuelle de `share_plus`), désormais avec des phrases qui assument
   la tension de chaque carte.
2. Écran détail carte depuis la bibliothèque, qui réutilisera
   `love` / `work` / `advice` / `warning` désormais alignés sur la voix.
3. Choix d'un provider analytics respectueux de la vie privée et
   instrumentation minimale (vue daily, partage, ouverture carte).
4. Petit écran Paramètres exposant `clearToday()` et un éventuel switch
   « inclure les sens inversés ».
5. **Optionnel mais peu coûteux** : test linguistique automatisé qui
   parse le JSON et échoue sur des chaînes prohibées (`tu vas`,
   `c'est certain`, `ton destin`, `mauvais présage`, `tu dois
   absolument`, etc.), pour protéger la voix contre les régressions.
