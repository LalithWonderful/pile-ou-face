# Lot 4 — Tirage du jour et cadrage éditorial

## Objectif

Introduire un véritable « message du jour » persisté localement et aligner
l'app sur le positionnement éditorial validé : Pile ou Face est une
expérience de divertissement et d'introspection, pas un service de
prédiction.

Le tirage du jour est stable pendant la journée, renouvelable le lendemain,
et stocké en local avec un strict minimum d'information. Aucun backend,
aucune nouvelle dépendance externe à part `shared_preferences`.

## Choix produit

- **Phrase d'accroche** mise en avant sur l'accueil :
  « Pile ou Face a un message pour toi. »
- **CTA principal** : « Découvrir mon message » — ouvre le tirage du jour
  (1 carte, persisté).
- **CTA secondaire** : « Faire un tirage 3 cartes » — ouvre un tirage libre
  Situation / Énergie / Conseil, sans persistance.
- **Mention discrète** : « Libre à toi de l'interpréter. » présente sur
  l'accueil et reprise sur le tirage du jour.
- **Disclaimer** : « Application de divertissement et d'introspection. »
  conservé sur l'accueil et rappelé en pied du message du jour.
- **Bibliothèque** : reléguée à un bouton texte tertiaire pour ne pas
  rivaliser avec les deux gestes principaux.

Le picker bottom-sheet introduit au Lot 1 est retiré : la décision se prend
désormais directement à l'accueil, ce qui réduit un tap et clarifie
l'arbitrage *message du jour* vs *tirage libre*.

## Structure de stockage local

Persistance via `shared_preferences`, trois clés uniquement :

| Clé                       | Type    | Contenu                                |
| ------------------------- | ------- | -------------------------------------- |
| `daily_reading.date`      | string  | Date locale au format `yyyy-MM-dd`.    |
| `daily_reading.card_id`   | string  | `id` stable de la carte tirée.         |
| `daily_reading.reversed`  | bool    | Orientation droit (`false`) / inversé. |

Aucune donnée personnelle, aucun identifiant utilisateur, aucun token. Le
test `stores only the three documented keys` garantit que rien d'autre ne
fuit dans `SharedPreferences`.

## Règle de renouvellement quotidien

Implémentée dans `DailyReadingService.getOrCreateToday()` :

1. Calcul du `todayKey()` au format `yyyy-MM-dd` à partir d'une horloge
   injectable (`DateTime.now` par défaut).
2. Si la clé `daily_reading.date` correspond à `todayKey()` **et** que
   `card_id` + `reversed` sont présents **et** que la carte référencée
   existe encore dans le JSON, le `DrawnCard` correspondant est renvoyé
   tel quel.
3. Sinon, tirage : shuffle déterministe (Random injectable), première
   carte, orientation aléatoire. Les trois clés sont réécrites avec la
   nouvelle date et la nouvelle carte.

Conséquence directe :
- Plusieurs appels le même jour renvoient strictement la même carte.
- Un appel le lendemain remplace l'entrée et donne potentiellement une
  autre carte.
- L'absence de stockage initial déclenche un tirage.

Le service expose aussi `clearToday()` pour invalider explicitement le
stockage (utile en test, ou pour un futur paramètre utilisateur).

## Wording intégré

- Accueil :
  - titre : « Pile ou Face »,
  - accroche : « Pile ou Face a un message pour toi. »,
  - CTA principal : « Découvrir mon message »,
  - CTA secondaire : « Faire un tirage 3 cartes »,
  - lien tertiaire : « Découvrir les cartes »,
  - mention : « Libre à toi de l'interpréter. »,
  - disclaimer : « Application de divertissement et d'introspection. ».
- Écran message du jour :
  - AppBar : « Mon message du jour »,
  - description idle : « Pile ou Face a un message pour toi. Prends un
    instant, puis révèle-le. »,
  - hint idle : « Libre à toi de l'interpréter. »,
  - CTA idle : « Révéler mon message »,
  - pied après révélation : « Libre à toi de l'interpréter. » +
    disclaimer.
- Écran tirage libre 3 cartes : inchangé côté wording (Situation / Énergie
  / Conseil), CTA idle « Révéler le tirage », CTA secondaire après
  révélation « Faire un autre tirage ».

## Parcours

- **Découvrir mon message** : `HomeScreen` → `ReadingScreen(isDaily: true)`.
  Idle → tap → `DailyReadingService.getOrCreateToday()` → animation de
  révélation (1 carte) → pied de carte « Libre à toi de l'interpréter. ».
  Aucun bouton « Retirer » : le tirage du jour ne peut pas être remplacé
  sans action explicite (le service est privé et n'est pas exposé via UI à
  ce stade).
- **Faire un tirage 3 cartes** : `HomeScreen` →
  `ReadingScreen(spread: TarotSpread.threeCards)`. Idle → tap → `TarotDrawService.draw` →
  animation en cascade (3 cartes) → bouton « Faire un autre tirage » qui
  rejoue le tirage libre sans toucher au stockage quotidien.
- **Découvrir les cartes** : inchangé.

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.1s)`
- `flutter test` : `+26 All tests passed!`

Détail :

- `widget_test.dart` (1) : nouveau wording d'accueil — titre, accroche,
  deux CTAs, mention « Libre à toi de l'interpréter. », disclaimer.
- `tarot_repository_test.dart` (3) : inchangé.
- `tarot_draw_service_test.dart` (4) : inchangé.
- `major_arcana_integrity_test.dart` (5) : inchangé.
- `tarot_spread_test.dart` (3) : inchangé.
- `daily_reading_service_test.dart` (**nouveau**, 6 tests) :
  - création + persistance des trois clés quand rien n'est stocké,
  - réutilisation strictement identique sur le même jour,
  - régénération sur un autre jour (la date persistée bascule),
  - **garantie qu'aucune clé supplémentaire n'est écrite** (assertion
    `unorderedEquals` sur `prefs.getKeys()`),
  - `clearToday()` vide complètement le stockage,
  - format `todayKey()` zéro-paddé `yyyy-MM-dd`.
- `reading_screen_test.dart` (4) :
  - tirage libre — idle + reveal (inchangé conceptuellement, adapté au
    nouveau scope avec `dailyService`),
  - tirage du jour — wording idle (« Mon message du jour »,
    « Révéler mon message », « Libre à toi de l'interpréter. »),
  - tirage du jour — révélation et persistance effective dans
    `SharedPreferences`.

## Limites connues

- Pas de partage du tirage du jour à ce stade : la phrase
  `share_message` est rédigée dans le JSON mais aucune action de partage
  natif n'est branchée. `share_plus` est candidat pour le lot suivant.
- Pas d'historique des messages des jours précédents (volontairement
  hors scope V1, et hors stockage minimal).
- Pas d'option utilisateur pour réinitialiser ou changer le message du
  jour : le service expose `clearToday()` mais ne le branche pas à l'UI.
- Pas de notification push pour signaler le nouveau message du jour
  (nécessiterait Firebase ou un autre backend, exclu de la V1).
- Pas de détection de changement de fuseau horaire : la clé du jour est
  calculée sur l'heure locale au moment de l'appel ; un voyage à
  l'étranger peut donc « avancer » ou « reculer » le message du jour
  d'une journée. Acceptable pour V1.
- Pas d'analytics : impossible pour le moment de mesurer combien
  d'utilisateurs ouvrent le message du jour par semaine.
- Migration JSON non versionnée : si une carte disparaît du JSON, le
  service retombe sur un nouveau tirage le même jour (`null` retourné
  par `_findCardById`). Comportement défensif acceptable, à formaliser
  si on commence à supprimer ou renommer des cartes.

## Prochaine étape recommandée

Lot 5 — Partage et instrumentation minimale :

1. Brancher un partage natif sur le message du jour à partir de
   `share_message` (introduction de `share_plus`, première dépendance
   externe orientée distribution).
2. Ajouter une vue détail carte depuis la bibliothèque, réutilisant
   `love`, `work`, `advice`, `warning`.
3. Cadrer un provider analytics léger (PostHog, Plausible, ou autre
   solution respectueuse de la vie privée) et instrumenter trois
   événements clés : ouverture du message du jour, partage, ouverture
   d'une carte depuis la bibliothèque.
4. Préparer un petit écran « Paramètres » exposant `clearToday()` et un
   éventuel switch « inclure les sens inversés » pour donner à
   l'utilisateur·rice un sentiment de contrôle.
5. Audit accessibilité minimal (tailles de texte, contrastes, libellés
   `Semantics`) avant publication.
