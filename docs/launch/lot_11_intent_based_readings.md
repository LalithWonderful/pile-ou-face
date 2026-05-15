# Lot 11 — Tirages par intention utilisateur

## Objectif

Restructurer l’app autour des **vraies questions humaines** plutôt que
de la mécanique « tirage 3 cartes » :
- *je me pose une question* (général),
- *je me pose une question d’amour*,
- *je me pose une question de travail*,
- *je me pose une question d’argent*.

Le tirage du jour reste tel quel : 1 carte, message général, sans
intention.

L’app reste offline, sans backend, sans analytics, sans nouvelle
dépendance.

## Décisions produit

### Accueil public

Cinq entrées, hiérarchie claire :

1. **CTA principal** (ElevatedButton) — `Découvrir mon message du jour`.
2. **CTA secondaires** (OutlinedButton) :
   - `Je me pose une question`,
   - `Je me pose une question d’amour`,
   - `Je me pose une question de travail`,
   - `Je me pose une question d’argent`.
3. **Lien dev** (TextButton, conditionné à `kDebugMode`) —
   `Voir les cartes`. En release, le lien disparaît complètement. Le
   `CardsLibraryScreen` reste dans le code et accessible directement
   par `Navigator.push` pour le développement, mais n’est plus exposé
   comme parcours utilisateur.

L’accueil bascule en `LayoutBuilder + SingleChildScrollView +
ConstrainedBox + IntrinsicHeight` pour absorber les hauteurs limitées
(petits écrans, scaling 1.4×) sans `RenderFlex overflow`.

### Domaines de tirage

Nouveau modèle simple :
[lib/features/tarot/models/reading_intent.dart](../../lib/features/tarot/models/reading_intent.dart) —
un `enum` `ReadingIntent` avec quatre valeurs
(`general`, `love`, `work`, `money`), chacune embarquant son
`homeLabel`, son `title` d’AppBar, son `intro` idle, et un `footer`
optionnel.

Aucune sur-architecture : un seul fichier, pas de service dédié, pas
de répertoire `domain/`.

### Positions du tirage 3 cartes

Inchangées par rapport au Lot 10 :
- `Là où tu en es`
- `L’énergie du moment`
- `Le conseil`

Toutes les intentions partagent ces trois positions ; seul le **body
texte** par carte change.

## Textes d’intro intégrés

| Intent  | Titre AppBar         | Intro idle                                                                 |
| ------- | -------------------- | -------------------------------------------------------------------------- |
| general | `Je me pose une question` | « Pense à ta question. Trois cartes pour y voir plus clair. » |
| love    | `Question d’amour`   | « Pense à cette personne, cette relation ou cette envie d’aimer. Trois cartes pour écouter ce que ton cœur sait déjà. » |
| work    | `Question de travail`| « Pense à ton projet, ton choix ou ta situation professionnelle. Trois cartes pour prendre du recul. » |
| money   | `Question d’argent`  | « Pense à une dépense, un projet ou une question d’argent. Trois cartes pour y voir plus clair. » |

## Champ JSON ajouté

**Oui, le champ `money` a été ajouté pour les 22 arcanes majeurs.**

Tous les autres champs (`meaning_upright/reversed`, `love`, `work`,
`advice`, `warning`, `short_message`, `share_message`, `keywords`,
`tags`) restent inchangés.

### Règles spécifiques argent

Pour rester aligné sur la promesse « bienveillante mais franche » :

À privilégier dans `money`
- vérifier les faits, regarder le risque réel ;
- ne pas confondre envie et certitude ;
- ralentir si une promesse semble trop belle ;
- poser une limite ;
- voir ce que tu peux assumer.

À éviter (audité par le guard éditorial, voir plus bas)
- `tu vas (gagner|perdre|…)`, `tu vas` en général ;
- `investis` / `n’investis pas` ;
- promesses de gain ou perte ;
- « ta situation va s’améliorer », « profit garanti », etc.

Aucun avertissement anxiogène n’est imposé dans l’écran principal. Une
seule mention discrète, en pied de la révélation argent uniquement :

> Ne remplace pas un conseil financier.

Présentée comme un footer en italique fin sous le bouton
`Faire un autre tirage` — pas comme un disclaimer agressif.

Exemples de ton retenus (extraits, brief verbatim repris) :

- **Le Bateleur** — « Tu peux commencer petit. Avant de mettre beaucoup
  d’énergie ou d’argent, teste, vérifie, et regarde si l’élan tient
  encore après l’enthousiasme du départ. »
- **La Justice** — « Reviens aux faits : chiffres, contrats,
  engagements, conséquences. Ce qui est juste n’est pas toujours ce
  qui fait le plus envie sur le moment. »
- **Le Diable** — « Regarde ce qui t’attire vraiment : le gain
  possible, la peur de manquer, ou l’envie de prouver quelque chose. Si
  une promesse semble trop belle, ralentis. »
- **La Maison-Dieu** — « Si quelque chose repose sur une base fragile,
  mieux vaut le voir avant que ça craque. Ce message t’invite à
  vérifier ce qui ne tient que par espoir. »
- **La Tempérance** — « Ni tout bloquer, ni tout risquer. Cherche le
  dosage juste : ce que tu peux engager sans te mettre en danger. »

## Adaptations code

- `TarotCard` gagne `money` (champ obligatoire, parser, accesseur).
- `DrawnCardView` accepte un `intent` optionnel et choisit le body :
  - null ou `general` → `drawnCard.meaning`
    (orientation-aware, comportement précédent),
  - `love` → `card.love`,
  - `work` → `card.work`,
  - `money` → `card.money`.
- `ReadingScreen` accepte un `intent` optionnel ; en mode intent,
  l’AppBar affiche `intent.title`, l’idle utilise `intent.intro`, le
  tirage forcé est `TarotSpread.threeCards`, et le footer
  `intent.footer` est rendu en italique fin sous le bouton de
  re-tirage quand il existe (uniquement money).
- `_StaggeredReveal` corrige au passage un **timer leak** : le
  `Future.delayed` initial est remplacé par un `Timer` stocké et
  annulé dans `dispose`. Sans ce fix, les tests qui scrollent un
  élément dont les animations n’avaient pas encore démarré
  remontaient « A Timer is still pending even after the widget tree
  was disposed ».

## Tests ajoutés / modifiés

- **`test/widget_test.dart`** : assertions complètes sur l’accueil (5
  CTAs validés, libellés retirés bloqués).
- **`test/features/tarot/presentation/home_screen_test.dart`** :
  5 tests de navigation (daily + 4 intents + lien dev biblio en
  kDebugMode) ; le test responsive 1.4× cherche le bon libellé
  daily.
- **`test/features/tarot/presentation/reading_screen_test.dart`** :
  nouveau groupe `ReadingScreen (intent-based)` (3 tests) — love
  affiche le body `love` et pas le `meaning`, money rend le footer
  `Ne remplace pas un conseil financier.` (via scroll sur 320×1200),
  general ne le rend pas.
- **`test/features/tarot/assets/major_arcana_integrity_test.dart`** :
  assertion `money.trim().isNotEmpty` ajoutée pour les 22 cartes.
- **`test/features/tarot/assets/major_arcana_editorial_guard_test.dart`** :
  `money` ajouté à la liste des champs scannés par le guard. Le ton
  des textes money est donc soumis aux mêmes interdits éditoriaux
  (`tu vas`, `voyance`, `ton destin`, etc.) que les autres champs.
- Fixtures patchées avec `money` dans : `tarot_repository_test`,
  `tarot_draw_service_test`, `daily_reading_service_test`,
  `daily_share_text_builder_test`, `home_screen_test`,
  `card_detail_screen_test`, `reading_screen_test`.

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.5s)`
- `flutter test` : `+54 All tests passed!`

48 → 54, soit **+6 tests nouveaux** côté intents et flow money, plus
ceux qui ont muté pour le nouveau wording.

## Problèmes rencontrés

1. **Faux positif éditorial sur Le Chariot** : ma première rédaction
   contenait « Si tu sais où tu vas », ce qui matche la regex `tu vas`
   du guard. Reformulé en « Une fois le cap posé, tu peux avancer
   doucement… ». Le sens est préservé sans déclencher la garde.
2. **Timer leak du `_StaggeredReveal`** : le `Future.delayed` non
   annulé fait crasher les tests qui scrollent un footer encore non
   monté. Remplacé par un `Timer` annulé dans `dispose`. Correction
   utile aussi en production (sortie rapide d’écran).
3. **Test d’accueil 1.4× obsolète** : une assertion cherchait encore
   l’ancien libellé `Découvrir mon message`. Mis à jour pour
   `Découvrir mon message du jour`.

## Limites connues

- L’écran `CardsLibraryScreen` n’est plus exposé en release, mais
  reste atteignable par code (accessible via `Navigator.push` depuis
  une éventuelle future feature ou un menu cachet).
- Pas de partage du tirage par intention : `share_message` reste
  attaché au tirage du jour. Étendre le partage aux intents nécessite
  un format éditorial dédié — hors scope.
- Pas d’écran Paramètres, donc pas de bascule
  « ne plus afficher le footer money » ni d’override des intentions.
- L’intent ne capte aucune sémantique amour/travail/argent côté
  modèle : c’est purement un sélecteur de champ. Pas de filtrage de
  cartes, pas de pondération.
- Pas d’analytics : impossible de mesurer quelle intention est la plus
  utilisée.
- Aucune relecture humaine externe du contenu `money` à ce stade ; le
  guard éditorial automatique bloque les régressions mais ne remplace
  pas une passe rédactionnelle finale.

## Prochaine étape recommandée

Lot 12 — Personnalisation discrète et accessibilité :

1. Écran Paramètres minimaliste exposant
   `DailyReadingService.clearToday()` et un éventuel toggle pour
   masquer le footer money (`UserPrefs`).
2. Animation `Hero` sur le `CardArtPlaceholder` entre la bibliothèque
   et la fiche détail (Lot 10 reporté).
3. Audit `Semantics` ciblé sur la fiche détail et les CTAs accueil.
4. Choix d’un provider analytics respectueux de la vie privée — en
   attente depuis le Lot 4. À arbitrer avant toute instrumentation.
