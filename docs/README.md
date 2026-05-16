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
   - Folder : `/docs`
4. Cliquer sur **Save**.
5. Une fois activé, les pages seront accessibles aux URL suivantes :
   - `https://<utilisateur>.github.io/pile_ou_face/`
   - `https://<utilisateur>.github.io/pile_ou_face/privacy-policy.html`
   - `https://<utilisateur>.github.io/pile_ou_face/support.html`

> **Note** : Ne pas inventer d'URL définitive tant que GitHub Pages n'est pas activé dans les paramètres du dépôt. L'URL exacte dépend du nom d'utilisateur ou d'organisation GitHub.

## Notes internes

- Avant soumission store, vérifier que `contact@pileouface.app` existe réellement et est monitorée.

## Contraintes respectées

- Aucun JavaScript.
- Aucun cookie.
- Aucun tracking / analytics.
- Aucun CDN externe.
- Responsive mobile.
- Style cohérent avec l'application (crème, vert profond, or).
