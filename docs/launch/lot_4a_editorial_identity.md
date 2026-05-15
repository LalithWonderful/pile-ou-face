# Lot 4A — Audit et renforcement de l’identité éditoriale

## Objectif

Sortir le contenu tarot d’un registre encyclopédique généraliste pour
installer la voix Pile ou Face : douce, intime, bienveillante, qui
s’adresse directement à toi sans jamais prédire, ordonner ou dramatiser.

Le périmètre est volontairement **uniquement éditorial** : aucun champ
supprimé, aucune dépendance ajoutée, aucun fichier de code modifié, aucun
test impacté côté logique.

## Règles éditoriales retenues

### Voix
- Adresse directe à la deuxième personne du singulier (`tu`).
- Présent simple, phrases courtes, ponctuation discrète.
- Inclusivité légère via le point médian (`fatigué·e`, `tel·le`) là où le
  genre serait sinon imposé. Évité quand le tour peut rester neutre.
- Apostrophes typographiques (`’`) homogènes dans tout le JSON.

### Vocabulaire privilégié
- `peut-être`, `tu peux`, `à ton rythme`, `sans te forcer`, `avec douceur`,
- `prends un instant`, `ce message t’invite`, `si cela résonne pour toi`,
- `ce que tu ressens`, `ce qui demande ton attention`,
- `ce que tu n’oses pas encore regarder`.

### Vocabulaire évité
- `tu dois`, `tu vas`, `il faut absolument`,
- `danger`, `mauvais présage`, `ton destin`, `tout est écrit`,
- `la vérité`, `révélation`, `les cartes savent`,
- formulations froides type encyclopédie.

### Cartes sensibles
Pour La Mort, Le Diable et La Maison-Dieu, le contenu est cadré comme
**mue, lucidité, libération, espace, clarification**. Ouverture explicite
par `Ici, [La Mort | Le Diable] parle de…` pour désamorcer l’imaginaire
anxiogène attaché au seul nom.

### Champs modifiés
Pour chacun des 22 arcanes majeurs :
- `meaning_upright`
- `meaning_reversed`
- `love`
- `work`
- `advice`
- `warning`
- `short_message`
- `share_message`

Soit **22 × 8 = 176 champs réécrits**.

### Champs explicitement conservés
- `id`, `number`, `name`, `image_path`,
- `keywords_upright`, `keywords_reversed`, `tags`.

Aucun champ supprimé, aucun champ ajouté : la structure du JSON est
inchangée et reste rétro-compatible avec le modèle `TarotCard`.

## Exemples avant / après

### Le Mat (0)
**Avant — meaning_upright** :
> Le Mat évoque un pas neuf, posé sans bagage inutile. Il invite à oser,
> même sans connaître toute la route.

**Après — meaning_upright** :
> Quelque chose en toi a envie de commencer, peut-être sans tout
> planifier. Tu peux faire un premier pas, à ton rythme, juste pour voir.

**Avant — share_message** :
> J’ai tiré Le Mat — un appel doux à l’élan et à la liberté.

**Après — share_message** :
> Aujourd’hui, Le Mat me souffle d’oser un premier pas.

### La Mort (13)
**Avant — meaning_upright** :
> La Mort parle ici d’une transformation, pas d’une menace. Quelque chose
> se termine pour laisser de la place à ce qui demande à naître.

**Après — meaning_upright** :
> Ici, La Mort parle de mue, pas de fin brutale. Quelque chose se termine
> pour faire place à plus juste, à ton rythme.

**Avant — short_message** : `Une mue, plus qu’une fin.`
**Après — short_message** : `Une mue, bien plus qu’une fin.`

### Le Diable (15)
**Avant — meaning_upright** :
> Le Diable montre une énergie puissante, attirante, parfois enchaînante.
> La reconnaître, c’est déjà la rendre moins dévorante.

**Après — meaning_upright** :
> Ici, Le Diable parle d’une énergie forte qui te traverse. La regarder
> en face, c’est déjà la rendre moins dévorante.

**Avant — love** :
> Une attirance forte peut être merveilleuse ou enchaîner. La question
> utile : « est-ce que cela me grandit ? »

**Après — love** :
> Une attirance forte peut être belle, ou enchaîner. Tu peux te demander,
> en douceur : est-ce que cela me grandit ?

## Résumé des changements éditoriaux

- 22 cartes passées d’un registre **descriptif tiers-personne**
  (« La Mort évoque… », « L’Empereur pose des fondations… ») à un
  registre **adresse directe à la 2ᵉ personne**
  (« Tu peux poser un cadre… », « Quelque chose en toi appelle… »).
- Suppression systématique des formulations potentiellement
  prescriptives : aucune occurrence de `tu dois`, `tu vas`,
  `il faut absolument`, `destin`, `révélation`, `danger`.
- `vérité` retiré des deux endroits où il restait dans le contenu
  éditorial (Justice inversée → `réalité simple` ; Maison-Dieu love →
  `parole enfin dite`). Il subsiste uniquement dans `keywords_upright` /
  `tags` de la Justice et de la Maison-Dieu, où il joue son rôle de
  mot-clé thématique et non d’assertion absolue.
- `share_message` réécrits sur le motif
  « Aujourd’hui, [carte] me souffle / m’invite / me rappelle … » pour
  être autonome quand l’utilisateur partagera la phrase plus tard.
- Avertissements (`warning`) reformulés comme **invitations** plutôt que
  comme alertes : « Distingue, avec douceur, ce qui t’appelle et ce que
  tu fuis. » plutôt que « Attention à confondre… ».

## Tests lancés et résultats

- `flutter analyze` : `No issues found! (ran in 1.1s)`
- `flutter test` : `+26 All tests passed!`

L’ensemble des suites passe sans modification. Les tests d’intégrité du
JSON (`major_arcana_integrity_test.dart`) continuent de garantir :
- 22 cartes présentes,
- numéros 0..21 uniques,
- ids uniques,
- tous les champs texte critiques non vides,
- listes `keywords_upright`, `keywords_reversed`, `tags` non vides.

Aucune adaptation de code ni de fixture n’a été nécessaire : les
fixtures de test embarquent leur propre contenu factice, indépendant du
contenu éditorial réel.

## Limites connues

- Pas de relecture humaine professionnelle de l’ensemble du contenu :
  une passe rédactionnelle externe reste recommandée avant publication
  publique, en particulier pour les cartes sensibles (13, 15, 16).
- Pas de test automatisé sur la voix éditoriale (recherche d’expressions
  proscrites). Possible à ajouter sous forme de test léger qui parse le
  JSON et échoue sur les chaînes prohibées (`tu dois`, `tu vas`,
  `il faut absolument`, etc.) — non inclus pour rester minimal.
- Le wording inclusif via point médian (`fatigué·e`, `tel·le`) reste
  un parti pris ; il pourra être ajusté si une lecture sur appareil
  révèle des soucis (lecteurs d’écran, polices spéciales).
- Pas de tonalité différenciée jour / soir / weekend : le ton est uniforme
  quelle que soit l’heure du tirage. À revisiter si l’usage le justifie.
- Pas d’audit accessibilité (tailles, contrastes, libellés `Semantics`)
  programmé à ce stade — distinct du périmètre éditorial.

## Prochaine étape recommandée

Lot 5 — Partage et instrumentation minimale (inchangé par rapport au
plan posé à la fin du Lot 4) :

1. Brancher un partage natif à partir de `share_message` (introduction
   éventuelle de `share_plus`).
2. Écran détail carte depuis la bibliothèque, réutilisant `love`,
   `work`, `advice`, `warning` désormais alignés sur la voix.
3. Choix d’un provider analytics respectueux de la vie privée et
   instrumentation minimale (vue daily, partage, ouverture carte).
4. Petit écran Paramètres exposant `clearToday()` et un éventuel switch
   « inclure les sens inversés ».
5. Optionnel — test linguistique automatisé qui scanne le JSON et bloque
   l’apparition future d’expressions proscrites, pour protéger l’identité
   éditoriale contre les régressions.
