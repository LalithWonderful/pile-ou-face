# Audit publication MVP — Pile ou Face

## Résumé exécutif

Le MVP est **fonctionnellement prêt** (82 tests verts, `flutter analyze`
propre, parcours utilisateur complet : message du jour, tirage par
intention, quotas freemium, partage, paramètres, politique de
confidentialité interne). Le contenu éditorial des 22 arcanes est
validé, l'app fonctionne offline, sans compte, sans analytics, sans
tracking.

En revanche, **9 points bloquants techniques** restent à régler avant
soumission aux stores. Aucun n'est lié au produit ou à l'éditorial : il
s'agit majoritairement d'assets générés par défaut par `flutter create`
qui n'ont jamais été remplacés (icône d'app, splash, libellés
techniques) et de plomberie de publication (signing Android,
URL publique de la politique de confidentialité, cohérence du bundle
identifier entre iOS et Android).

Aucune réécriture, aucune refonte. Une session de 1 à 2 jours suffit
pour lever tous les bloquants techniques.

## Verdict publication

- **Statut** : 🟠 **non publiable en l'état**, mais aucun problème de
  fond. Le MVP produit est mûr ; ce sont les "habits de scène" qui
  manquent.
- **Bloquants** : 9 points (cf. section G). Tous techniques, aucun
  produit / éditorial / contenu.
- **Points importants** : 8 points à régler avant la première bêta
  (screenshots, descriptions store, classification d'âge, droits
  illustrations, etc.).
- **Points pouvant attendre** : onboarding, mode paysage iPad, écran
  d'erreur global, localisation multi-langues, tests E2E.

---

## A. Identité app

| Élément | Valeur actuelle | Verdict |
|---|---|---|
| Nom affiché Android | `pile_ou_face` (snake_case technique) dans `AndroidManifest.xml:3` | 🔴 **Bloquant** — doit être `Pile ou Face` |
| Nom affiché iOS (`CFBundleDisplayName`) | `Pile Ou Face` ("Ou" capitalisé) | 🔴 **Bloquant** — doit être `Pile ou Face` |
| `CFBundleName` iOS | `pile_ou_face` | 🟠 Important — utilisé en fallback si display name absent, à aligner |
| Bundle ID Android | `com.lalith.pileouface` | ✅ Aligné sur iOS (commit PUB-2e) |
| Bundle ID iOS | `com.lalith.pileouface` | ✅ Aligné sur Android (commit PUB-2e) |
| Version | `1.0.0+1` (`pubspec.yaml:19`) | ✅ OK pour première publication |
| App icon Android | PNG par défaut Flutter (442 B pour mdpi, mêmes octets que la sortie de `flutter create`) | 🔴 **Bloquant** — icône F-shape par défaut, refusée par Play Store |
| App icon iOS | 1024×1024 = 10,9 KB, manifestement template Flutter | 🔴 **Bloquant** — icône par défaut, refusée par App Store |
| Splash screen Android | `launch_background.xml` = fond blanc plein, aucun branding | 🔴 **Bloquant** ressenti — l'app démarre sur un écran blanc puis bascule sur la UI ; à minima un branding (logo centré, couleur fond ivoire `#FBF7EE` cohérent avec le thème) |
| Splash screen iOS | `LaunchScreen.storyboard` pointe sur `LaunchImage.imageset` qui contient les PNG template Flutter | 🔴 **Bloquant** ressenti — même remarque que Android |
| Orientation supportées iPhone | Portrait + LandscapeLeft + LandscapeRight (`Info.plist:56-61`) | 🟠 Important — l'app n'est pas conçue pour le paysage. Verrouiller en portrait évite des UX cassées. PortraitUpsideDown absent côté iPhone : ✅ (cohérent guidelines Apple). |
| Orientation supportées iPad | 4 orientations (`Info.plist:62-68`) | 🟢 Acceptable |
| Orientation Android | Aucune restriction dans `AndroidManifest.xml` | 🟠 Important — verrouiller `android:screenOrientation="portrait"` sur la `MainActivity` pour cohérence |
| Langue principale (`CFBundleDevelopmentRegion`) | `$(DEVELOPMENT_LANGUAGE)` = `en` par défaut Flutter | 🟠 Important — l'app est 100 % FR, doit être `fr` (sinon le store la considère comme app anglaise) |

### Recommandations bundle identifier

Décision figée dans le commit PUB-2e : les deux plateformes utilisent
`com.lalith.pileouface`. Le suffixe redondant a été retiré car il nuisait
à la lisibilité côté store et n'était pas nécessaire. Le bundle ID est
désormais immuable et cohérent entre Android et iOS.

## B. Permissions et privacy

| Élément | État | Verdict |
|---|---|---|
| Permissions Android déclarées | **Aucune** `<uses-permission>` dans `AndroidManifest.xml` | ✅ Cohérent avec local-first |
| Permissions iOS déclarées | **Aucune** clé `NS*UsageDescription` dans `Info.plist` | ✅ Cohérent avec local-first |
| Permissions inutiles | Aucune | ✅ |
| Cohérence permissions ↔ politique | ✅ L'app ne demande rien, la politique reflète cette absence |
| Accès "Effacer mes données" | `SettingsScreen` → `AppDataResetService.clearAll()` | ✅ Présent et testé |
| Accès "Politique de confidentialité" | `SettingsScreen` → `PrivacyPolicyScreen` (page interne) | ✅ Présent et testé |
| Auth | ❌ aucune, conforme décision produit | ✅ |
| Analytics | ❌ aucun SDK | ✅ |
| Tracking | ❌ aucun | ✅ |

**Note `<queries>` Android** : la balise `<queries>` pour `ACTION_PROCESS_TEXT`
est ajoutée par Flutter par défaut. Inoffensive et nécessaire au moteur
Flutter. Pas à supprimer.

## C. Store readiness

### App Store privacy labels (App Store Connect questionnaire)

Tous les groupes répondent **"Data Not Collected"** :

- Contact Info, Health & Fitness, Financial Info, Location, Sensitive
  Info, Contacts, User Content, Browsing/Search History, Identifiers,
  Purchases, Usage Data, Diagnostics, Other Data.

Cas particulier : le partage natif via `share_plus` ne **collecte rien**
côté Pile ou Face (le système OS gère la cible). Aucun label à
remplir pour ce flux.

### Play Store Data Safety

Idem côté Play Console : tout déclarer **"No data collected"** et
**"No data shared"**. Cocher "All user data is encrypted in transit" et
"Users can request data deletion" → oui (via Paramètres → Effacer mes
données).

### URL politique de confidentialité

Aujourd'hui : page interne `PrivacyPolicyScreen` accessible depuis
`SettingsScreen`. Suffit pour le **contenu in-app**.

**Insuffisant pour le store** : Apple App Store Connect et Google Play
Console **exigent une URL publique accessible sans téléchargement de
l'app**. La constante `AppConstants.privacyPolicyUrl` pointe déjà sur
`https://pileouface.app/politique-de-confidentialite` qui n'existe pas
encore.

→ Héberger une page web statique reprenant le texte de
`PrivacyPolicyScreen`. Option la plus simple : GitHub Pages ou Netlify
ou hébergement à venir du domaine `pileouface.app`. Lien fournit ensuite
aux stores et conservé tel quel dans la constante in-app.

### Screenshots nécessaires

| Store | Format | Minimum |
|---|---|---|
| App Store | 6.7" iPhone (1290×2796) | 3 |
| App Store | 6.5" iPhone (1284×2778 ou 1242×2688) | 3 |
| App Store | iPad 12.9" (2048×2732) | 3 si l'app est universelle (notre `TARGETED_DEVICE_FAMILY = "1,2"` la déclare universelle) |
| Play Store | Téléphone (jusqu'à 3840×2160) | 2 minimum, 8 max |
| Play Store | Bannière "Feature graphic" 1024×500 | 1 obligatoire |
| Play Store | Icône hi-res 512×512 | 1 obligatoire |

Captures conseillées (5 écrans clés à présenter) :
1. Accueil avec les 5 entrées
2. Mon message du jour révélé (illustration + texte court)
3. Tirage 3 cartes en cours (carte 2 sur 3 par exemple, header position)
4. Détail d'une carte (illustration + sections éditoriales)
5. Paramètres ou Politique de confidentialité (rassure sur l'aspect local-first)

### Description courte / longue

À rédiger (FR principal). Squelette suggéré :

> **Pile ou Face — un message pour toi.**
> Découvre chaque jour un message symbolique inspiré du tarot des
> arcanes majeurs. Pose une question sur ta vie, l'amour, le travail
> ou l'argent, et reçois trois cartes pour y voir plus clair.
>
> Application de divertissement et d'introspection.
>
> – 22 arcanes majeurs avec illustrations originales
> – Un message du jour offert chaque journée
> – Quatre thèmes de questions
> – Fonctionne hors ligne, sans compte
> – Aucune donnée envoyée à un serveur

Reprendre exactement le ton de l'app (« bienveillant mais franc »).

### Catégorie

- **App Store** : Mode de vie (Lifestyle) ou Divertissement
  (Entertainment). Lifestyle est plus aligné sur l'usage rituel
  quotidien et donne moins de concurrence agressive.
- **Play Store** : Lifestyle.

### Classification d'âge

- App Store Connect questionnaire : "Tarot/Symbolic content" →
  classer en **12+** par prudence (le wording évoque amour, argent,
  attachement, dépendance). Pas de violence, pas d'horreur, pas de
  contenu sexuel explicite.
- Play Store questionnaire IARC : équivalent **PEGI 12** /
  **Teen** côté ESRB.

### Mention tarot / bien-être / divertissement

Déjà bien cadré dans l'app : footer "Application de divertissement et
d'introspection." présent sur l'accueil et le message du jour. Pour
Apple en particulier (qui scrute les claims spirituels), reprendre
cette formulation dans la description store et **ne jamais** utiliser
les mots "voyance", "prédiction", "destin" dans la fiche store —
cohérent avec la garde éditoriale déjà active sur le JSON.

## D. Technique build

| Élément | Valeur | Verdict |
|---|---|---|
| Android `compileSdk` | `flutter.compileSdkVersion` (= 35 avec Flutter 3.41) | ✅ |
| Android `minSdk` | `flutter.minSdkVersion` (= 21 / Android 5.0) | ✅ |
| Android `targetSdk` | `flutter.targetSdkVersion` (= 35 avec Flutter 3.41) | ✅ Conforme exigence Play Store août 2024 (≥ 34) |
| Android Java/Kotlin target | 17 / 17 | ✅ |
| Android signing release | `signingConfigs.getByName("debug")` + TODO ligne 36 | 🔴 **Bloquant** — Play Store refuse les debug keys |
| iOS deployment target | 13.0 | ✅ (Apple exige ≥ 12 ; recommandation actuelle 13 ou 14) |
| iOS signing | Géré via Xcode / App Store Connect au build | 🟠 Important — préparer le profil Distribution et certificats |
| Build release Android | Techniquement possible | ⚠️ Avec debug key → ne sera pas accepté par Play Store |
| Build iOS | À tester avec un compte Apple Developer | ⚠️ Pas validé |
| Assets déclarés | `assets/tarot/major_arcana.json` + `assets/tarot/major_arcana/` + `assets/tarot/backgrounds/` (`pubspec.yaml:62-65`) | ✅ |
| Chemins d'assets vs JSON | `image_path` JSON pointe vers `assets/tarot/major_arcana/*.webp` | ✅ Cohérent |
| Fichier parasite | `assets/tarot/major_arcana/.DS_Store` présent localement (10 KB) | 🟠 Important — non tracké par git mais inclus dans le bundle Flutter au build. À supprimer du dossier source AVANT chaque build de release |

### Détails signing Android à prévoir

1. Générer un keystore release :
   ```
   keytool -genkey -v -keystore ~/keys/pile_ou_face.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pile_ou_face
   ```
2. Créer `android/key.properties` (à mettre dans `.gitignore`)
3. Modifier `android/app/build.gradle.kts` :
   - Lire `key.properties`
   - Créer `signingConfigs.release` réel
   - Remplacer `signingConfig = signingConfigs.getByName("debug")` par `signingConfig = signingConfigs.getByName("release")`

## E. Qualité produit

| Parcours | État |
|---|---|
| Premier lancement (pas d'onboarding) | ✅ Atterrissage direct sur l'accueil. Acceptable MVP. |
| Message du jour | ✅ 1/jour persisté en local |
| Tirage avec intention (4 thèmes) | ✅ Quotas 2/jour appliqués |
| Quotas freemium | ✅ Service local `DailyQuotaService` + écran quota atteint |
| Écran quota atteint | ✅ Wording "bienveillant mais franc" (Lot 19) |
| Partage du message | ✅ via `share_plus`, texte simplifié (commit `ee1673f`) |
| Paramètres | ✅ "Effacer mes données" + lien Politique |
| Effacer mes données | ✅ `AppDataResetService.clearAll()` ciblé (pas de `prefs.clear()` global) |
| Politique de confidentialité | ✅ Page interne `PrivacyPolicyScreen` |
| Tests | ✅ 82/82 verts |
| `flutter analyze` | ✅ propre |
| États vides / erreurs | 🟠 Pas d'écran d'erreur global si JSON corrompu ou asset manquant. Mineur, acceptable MVP. |
| Edge cases (1ère carte sans illustration WebP, etc.) | 🟠 À tester manuellement avant publication |
| Tests E2E sur device réel | 🟠 Non automatisés. Smoke manuel requis avant chaque release. |

## F. Risques store / conformité

| Risque | Niveau | Note |
|---|---|---|
| Rejet pour compte obligatoire | 🟢 **Aucun** | App sans compte, conforme App Store 5.1.1(v) et Play "App functionality" |
| Politique uniquement interne (sans URL publique) | 🔴 **Élevé** | Les deux stores exigent une URL publique en plus de la page in-app |
| Promesse "tarot/voyance" | 🟢 **Faible** | Wording de l'app déjà cadré ("divertissement et introspection"). La garde éditoriale (`major_arcana_editorial_guard_test`) bloque déjà les mots `voyance`, `prédiction`, `destin`. À conserver dans la fiche store. |
| Absence de disclaimer médical/psychologique | 🟡 **Modéré** | Le footer "Application de divertissement et d'introspection." est présent partout dans l'app. Pour la fiche store, **ajouter explicitement** une phrase équivalente. Pas obligatoire en interne. |
| IAP évoqué mais non implémenté | 🟢 **Aucun** | La politique dit "Si des achats intégrés sont ajoutés plus tard". Cohérent. Aucun bouton premium dans l'app actuelle. |
| Droits d'usage des illustrations | 🟠 **Important à vérifier** | 22 .webp dans `assets/tarot/major_arcana/`. Source / licence non documentée dans le repo. **Le propriétaire produit doit confirmer** : œuvres originales propres, achetées avec licence commerciale, ou générées par IA avec droits d'utilisation. Documenter dans `docs/assets/illustrations_provenance.md` avant publication. |
| iOS 4.8 Sign in with Apple | 🟢 **Aucun** | Aucune connexion sociale → règle non déclenchée |
| iOS 5.1.1(v) suppression compte | 🟢 **Aucun** | Aucun compte → règle non déclenchée |
| iOS 2.5.1 fonctionnalité minimale | 🟢 **Faible** | L'app a un contenu éditorial réel (22 cartes avec 11 champs chacune + spread_meanings) + une vraie boucle quotidienne. Au-delà du seuil "app gabarit". |

## G. Priorisation

| Priorité | Sujet | Impact | Action recommandée |
|---|---|---|---|
| 🔴 **Bloquant** | Icône d'app par défaut Flutter | Rejet certain App Store et Play Store | Remplacer les 5 PNG Android (`mipmap-*/ic_launcher.png`) et tous les Icon-App-*.png iOS par une icône Pile ou Face (1024×1024 master). Plugin `flutter_launcher_icons` ou export manuel. |
| 🔴 **Bloquant** | Splash screen par défaut | UX inacceptable au démarrage | Personnaliser `launch_background.xml` Android (logo centré sur fond ivoire) et remplacer `LaunchImage.imageset` iOS. Plugin `flutter_native_splash` ou édition manuelle. |
| 🔴 **Bloquant** | Nom affiché Android `pile_ou_face` | Affiché tel quel sur le home screen | Modifier `AndroidManifest.xml:3` `android:label="Pile ou Face"` |
| 🔴 **Bloquant** | Nom affiché iOS `Pile Ou Face` | Capitalisation incorrecte | Modifier `Info.plist` `CFBundleDisplayName` → `Pile ou Face` |
| ✅ **Résolu** | Incohérence bundle ID Android/iOS | Risque dégradé une fois publié (réservation store) | Alignement sur `com.lalith.pileouface` pour Android et iOS (commit PUB-2e) |
| 🔴 **Bloquant** | Signing Android = debug key | Refus Play Store | Générer keystore release, configurer `signingConfigs.release` dans `build.gradle.kts` |
| 🔴 **Bloquant** | URL publique politique de confidentialité | Champ obligatoire des fiches store | Héberger une page web statique reprenant le texte de `PrivacyPolicyScreen` à l'URL `AppConstants.privacyPolicyUrl` |
| 🔴 **Bloquant** | `CFBundleDevelopmentRegion` par défaut `en` | App considérée comme anglaise par Apple alors qu'elle est 100 % FR | Forcer `<string>fr</string>` dans `Info.plist` |
| 🔴 **Bloquant** | `.DS_Store` dans `assets/tarot/major_arcana/` | Asset macOS embarqué dans le bundle | Supprimer le fichier localement avant build release ; ajouter un step `flutter clean` dans la procédure release |
| 🟠 **Important** | Verrouillage portrait Android/iPhone | UX cassée si l'utilisateur tourne le téléphone | Restreindre orientations Android (`android:screenOrientation="portrait"`) et iPhone (retirer Landscape de `UISupportedInterfaceOrientations`) |
| 🟠 **Important** | Droits d'usage des 22 illustrations | Risque légal et rejet store si modèle IA non autorisé commercialement | Documenter la provenance dans `docs/assets/illustrations_provenance.md` |
| 🟠 **Important** | Screenshots App Store / Play Store | Soumission impossible sans | Préparer 5 captures × 2 tailles iPhone + 1 iPad + 2 Android + 1 feature graphic |
| 🟠 **Important** | Description courte / longue stores | Soumission impossible sans | Rédiger FR (et EN si commercialisation hors France) |
| 🟠 **Important** | Classification d'âge stores | À déclarer à la soumission | Remplir questionnaires App Store + IARC (Play) → recommandation 12+ / PEGI 12 |
| 🟠 **Important** | Privacy labels App Store + Data Safety Play | Champs obligatoires | Déclarer "No data collected / No data shared" |
| 🟠 **Important** | `CFBundleName` iOS = `pile_ou_face` | Fallback peu lisible si display name absent | Aligner sur `Pile ou Face` |
| 🟠 **Important** | Préparer profil Distribution iOS | Build release impossible sans | Apple Developer + provisioning profile dans Xcode |
| 🟢 **Peut attendre** | Onboarding premier lancement | UX premium, pas obligatoire | Post-MVP |
| 🟢 **Peut attendre** | Écran d'erreur global | Robustesse, jamais déclenché en parcours nominal | Post-MVP |
| 🟢 **Peut attendre** | Localisation multi-langues | Hors scope MVP FR-only | Phase 2 |
| 🟢 **Peut attendre** | Mode paysage iPad | UX optimisée tablette | Phase 2 |
| 🟢 **Peut attendre** | Tests E2E automatisés | Couverture existante 82 unit/widget suffisante MVP | Phase 2 |
| 🔵 **Optionnel** | `flutter_launcher_icons` / `flutter_native_splash` en dev-dependency | Confort de génération | Si le designer fournit le master 1024 |

## Commandes lancées

```
flutter analyze   →  No issues found! (ran in 1.6s)
flutter test      →  +82 All tests passed!
```

Aucune modification de code source pour cet audit. Le seul fichier
créé est ce document.

## Limites de l'audit

- Audit basé sur **inspection statique** des fichiers source. Aucun
  build release effectif (Android ou iOS) n'a été tenté pour cet
  audit ; les remarques sur le signing et le profil Distribution iOS
  reposent sur la configuration vue dans les fichiers.
- Pas de test sur device réel pendant cet audit. Les ressentis UX
  (premier lancement, splash, icône) sont déduits des assets
  identifiés comme templates Flutter par défaut (file sizes typiques,
  pas d'inspection visuelle).
- Pas de vérification de la provenance / licence des 22 illustrations
  `.webp` — c'est une question produit/légal qui dépasse l'audit
  technique. À traiter par le propriétaire produit.
- Pas de revue de la rédaction commerciale (description store, mots-
  clés ASO) — ce travail viendra avec un lot dédié `STORE-LISTING-1`.
- Pas de simulation des questionnaires App Store Connect Privacy
  Labels ni Play Console Data Safety — les recommandations sont
  basées sur la connaissance de l'absence d'auth / analytics /
  tracking dans le code.

## Prochain lot recommandé

Lot **PUBLICATION-2 — Lever les bloquants techniques**, à découper en
4 sous-lots indépendants et commitables séparément :

1. **PUB-2a — Identité visuelle build** :
   - Icône d'app (Android + iOS) à partir d'un master 1024×1024 produit
     designer.
   - Splash screen Android + iOS avec branding minimal (logo + fond
     ivoire).
   - Outil suggéré : `flutter_launcher_icons` + `flutter_native_splash`
     en dev-dependencies (justifié car ce sont des outils de build, pas
     du runtime).

2. **PUB-2b — Métadonnées build** :
   - Renommer `android:label` Android.
   - Corriger `CFBundleDisplayName`, `CFBundleName`,
     `CFBundleDevelopmentRegion` iOS.
   - Aligner les bundle identifiers Android et iOS sur une forme
     canonique.
   - Verrouiller orientation portrait iPhone et Android.

3. **PUB-2c — Signing Android release** :
   - Génération keystore.
   - Configuration `signingConfigs.release` dans
     `android/app/build.gradle.kts` avec lecture de `key.properties`.
   - `.gitignore` mis à jour.

4. **PUB-2d — Hébergement politique publique** :
   - Page web statique reprenant `PrivacyPolicyScreen` à l'URL déjà
     déclarée dans `AppConstants.privacyPolicyUrl`.
   - Lot indépendant du code app — peut être réalisé en parallèle.

Puis lot **STORE-LISTING-1 — Préparer la fiche store** :
- Screenshots, descriptions FR, classification d'âge, privacy labels,
  Data Safety, droits illustrations documentés.

À noter : aucun lot suggéré ne nécessite d'ajouter un SDK, un backend,
une dépendance réseau, ou de toucher à la logique tirage / quotas /
freemium / éditorial.
