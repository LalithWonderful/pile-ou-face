# Lot 6 — Test de protection éditoriale

## Objectif

Garantir que le contenu des arcanes majeurs (`assets/tarot/major_arcana.json`) reste aligné sur l'identité éditoriale de Pile ou Face : bienveillante mais franche, sans prédiction, sans voyance, sans culpabilité et sans anxiogénèse.

## Expressions bloquées

Le test échoue si l'une des expressions suivantes est détectée dans les champs éditoriaux :

| Expression | Raison |
|---|---|
| `tu vas` | Prédiction directe |
| `vous allez` | Prédiction directe (vouvoiement) |
| `cela va arriver` | Promesse d'avenir |
| `ça va arriver` | Promesse d'avenir |
| `c'est certain` | Affirmation trop forte |
| `ton destin` | Voyance / fatalisme |
| `votre destin` | Voyance / fatalisme (vouvoiement) |
| `mauvais présage` | Anxiogène / prédiction négative |
| `les cartes disent` | Personnification prédicative |
| `les cartes savent` | Personnification prédicative |
| `tu dois absolument` | Ordre directif |
| `il faut absolument` | Ordre directif |
| `prédit` | Prédiction explicite |
| `prédiction certaine` | Prédiction explicite |
| `voyance` | Terme interdit store |

## Expressions volontairement autorisées

Les mots forts suivants ne déclenchent **pas** le test, car ils peuvent être nécessaires au sens de la carte :

- vérité
- peur
- désir
- rupture
- blocage
- limite
- fin
- attachement
- effondrement
- lucidité

## Champs surveillés

- `meaning_upright`
- `meaning_reversed`
- `love`
- `work`
- `advice`
- `warning`
- `short_message`
- `share_message`

## Limites du test

- Le test ne juge pas la qualité littéraire, seulement la présence d'expressions explicitement interdites.
- Il ne détecte pas les formulations ambiguës ou les contournements créatifs des règles.
- Il ne protège pas les textes de l'interface (Dart) — seulement le JSON des cartes.
- Les apostrophes typographiques (`'`) sont normalisées en apostrophes droites (`'`) avant la vérification.

## Commandes

```bash
flutter test test/features/tarot/assets/major_arcana_editorial_guard_test.dart
```

## Prochaine étape recommandée

- Intégrer ce test à la CI (GitHub Actions / GitLab CI) pour bloquer toute PR qui introduirait une expression interdite.
- Envisager un deuxième test de "mollesse" (détection d'excès de formulations vides) si l'identité éditoriale évolue.
