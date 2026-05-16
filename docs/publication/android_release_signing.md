# Android — Signing release pour Pile ou Face

Ce document décrit la procédure complète pour générer un build Android
release signé, prêt pour le Play Store, sans jamais exposer les secrets
dans le repository.

## Principe

- Le repo **ne contient ni keystore (`.jks`) ni mot de passe**.
- Un fichier local non-tracké `android/key.properties` fournit les
  références au keystore et à ses mots de passe.
- Gradle lit ce fichier au moment du build via
  [android/app/build.gradle.kts](../../android/app/build.gradle.kts).
- Si le fichier est absent, le build `release` retombe sur la clé debug
  avec un avertissement explicite. L'artefact existe mais **ne sera pas
  accepté par le Play Store**.

## 1. Pré-requis

- Un JDK ≥ 17 disponible dans le `PATH` (déjà requis par Gradle 8 / AGP 8).
- L'utilitaire `keytool` (livré avec le JDK).
- Un gestionnaire de mots de passe pour archiver le keystore et les
  passphrases (1Password, Bitwarden, KeePassXC, etc.).

## 2. Génération de l'upload key locale

À exécuter **une seule fois**, depuis la racine du projet :

```bash
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

`keytool` posera quelques questions :

- mot de passe du keystore (à retenir) ;
- mot de passe de la clé (peut être identique à celui du keystore) ;
- nom, organisation, ville, pays — ces champs apparaissent dans le
  certificat. Mettre des valeurs cohérentes ; ils ne sont jamais affichés
  côté utilisateur final.

Le fichier `android/app/upload-keystore.jks` est généré localement. Il
est **déjà gitignoré** par `android/.gitignore` (pattern `**/*.jks`) :
aucune action supplémentaire à faire.

> Validité 10 000 jours ≈ 27 ans. Play Store exige une validité au
> minimum jusqu'au 22 octobre 2033 pour les nouvelles applications. La
> valeur ci-dessus largement au-delà.

## 3. Création de `android/key.properties`

À côté de `android/settings.gradle.kts`, créer le fichier
`android/key.properties` :

```properties
storePassword=<mot de passe du keystore>
keyPassword=<mot de passe de la clé>
keyAlias=upload
storeFile=../app/upload-keystore.jks
```

Le chemin `storeFile` est relatif au module `app/` ; `../app/...`
résout bien vers `android/app/upload-keystore.jks`.

Le fichier est **déjà gitignoré** par `android/.gitignore` (pattern
`key.properties`).

Un gabarit existe dans le repo :
[android/key.properties.example](../../android/key.properties.example).
Le copier sans les valeurs réelles ne suffit pas — il faut bien renseigner
les vrais mots de passe.

## 4. Construire un AAB release

```bash
flutter build appbundle --release
```

Sortie :
```
build/app/outputs/bundle/release/app-release.aab
```

C'est ce fichier qui doit être uploadé sur Google Play Console.

### Pourquoi l'AAB plutôt que l'APK

Depuis août 2021, Google Play exige le format **Android App Bundle**
(`.aab`) pour les nouvelles applications. Le bundle contient tout le
code et toutes les ressources ; Google Play génère ensuite des APK
optimisés pour chaque appareil (densité d'écran, langue, architecture
CPU), ce qui réduit la taille de téléchargement effectif pour
l'utilisateur.

Un APK release reste générable (`flutter build apk --release`) si on
veut un fichier installable directement (sideload, distribution
interne), mais il n'est plus le format de référence pour le store.

## 5. Différence upload key vs app signing key

Quand on enrôle l'app dans **Google Play App Signing** (vivement
recommandé, activé par défaut depuis 2021) :

- la clé qu'on génère localement (`upload-keystore.jks`) est l'**upload
  key**, utilisée pour **signer les artefacts envoyés à Play Console**.
- Google Play conserve la véritable **app signing key** et l'utilise
  pour signer les APK distribués aux utilisateurs.

Conséquences :

- Si on perd l'upload key, on peut en redemander une nouvelle à Google
  via le support Play Console — c'est désagréable mais non bloquant.
- Si on perd la clé Google (gérée par eux), Google la gère pour nous.
- Pas de chaîne d'attestation côté utilisateur : l'app signing key sert
  côté Google, l'upload key sert seulement à prouver à Google que c'est
  bien nous qui poussons une nouvelle version.

Si Play App Signing **n'est pas activé**, l'upload key et l'app signing
key sont confondues, et perdre le keystore = ne plus jamais pouvoir
mettre à jour l'app. C'est pour ça qu'on active Play App Signing à la
première publication.

## 6. Sauvegarder les secrets dans un gestionnaire de mots de passe

À mettre dans le coffre-fort (1Password / Bitwarden / KeePassXC) :

- une **copie binaire** du fichier `upload-keystore.jks` (pièce jointe,
  ou base64 dans une note sécurisée) ;
- le **mot de passe du keystore** ;
- le **mot de passe de la clé** ;
- l'**alias** (`upload`) ;
- la **date de génération** et la **date d'expiration** (validity).

Sans le keystore et son mot de passe, plus aucune nouvelle version
**signée par cette upload key** ne pourra être publiée. Avec Play App
Signing, Google peut nous fournir une procédure de rotation, mais
elle est manuelle et lente. La sauvegarde évite ce détour.

## 7. Vérifier qu'aucun secret n'est suivi par Git

À tout moment, on peut s'assurer que les fichiers sensibles ne sont
pas trackés :

```bash
git ls-files | grep -E '\.(jks|keystore)$'
git ls-files | grep -E '(^|/)key\.properties$'
```

Les deux commandes doivent renvoyer **zéro ligne**.

Si jamais l'une d'elles renvoie quelque chose, c'est un incident :
retirer immédiatement le fichier du suivi (`git rm --cached <file>`),
amender le `.gitignore` si besoin, **forcer la rotation de tous les
mots de passe et regénérer le keystore**. Un secret ayant été poussé
ne peut pas être considéré comme privé même après suppression de
l'historique.

## 8. Récapitulatif rapide

| Quoi | Où | Tracké par Git ? |
|---|---|---|
| `upload-keystore.jks` | `android/app/` | ❌ ignoré (`**/*.jks`) |
| `key.properties` | `android/` | ❌ ignoré |
| `key.properties.example` | `android/` | ✅ tracké, ne contient que des placeholders |
| `build.gradle.kts` | `android/app/` | ✅ tracké, lit `key.properties` au build |
| Sauvegarde keystore + mots de passe | password manager | hors repo |

Avec cette configuration en place, `flutter build appbundle --release`
produit un AAB signé prêt à être envoyé à Google Play Console.
