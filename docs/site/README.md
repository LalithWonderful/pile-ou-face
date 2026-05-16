# Site public Pile ou Face

Ce dossier contient les pages HTML statiques destinées à être publiées via **GitHub Pages**.

## Pages disponibles

| Fichier | Description |
|---------|-------------|
| `index.html` | Page d'accueil publique |
| `privacy-policy.html` | Politique de confidentialité (lien store obligatoire) |
| `support.html` | Page de contact / support |
| `style.css` | Feuille de style partagée (sans framework, sans script) |

## Prérequis

- Le dépôt GitHub doit être public (ou GitHub Pages activé sur un dépôt privé avec un plan Pro).
- Les fichiers doivent se trouver dans la branche publiée (généralement `main`).

## Comment publier

1. Ouvrir le dépôt sur GitHub.
2. Aller dans **Settings → Pages**.
3. Sous **Source**, choisir :
   - **Deploy from a branch**
   - Branch : `main`
   - Folder : `/ (root)` ou `/docs`
4. GitHub Pages ne permet pas de choisir `/docs/site` directement comme racine.
   - **Option A (recommandée)** : définir le dossier source sur `/docs`. Dans ce cas, déplacer les fichiers de `docs/site/` vers `docs/` (à la racine de `docs/`).
   - **Option B** : définir le dossier source sur `/ (root)` et ajouter une GitHub Action qui copie `docs/site/` vers la branche `gh-pages` à chaque push.
5. Une fois activé, l'URL sera de la forme `https://<utilisateur>.github.io/<repo>/`.

> **Note** : Ne pas inventer d'URL définitive tant que GitHub Pages n'est pas activé dans les paramètres du dépôt. L'URL exacte dépend du nom d'utilisateur ou d'organisation GitHub.

## Contraintes respectées

- Aucun JavaScript.
- Aucun cookie.
- Aucun tracking / analytics.
- Aucun CDN externe.
- Responsive mobile.
- Style cohérent avec l'application (crème, vert profond, or).
