# 🚀 Déploiement ReTurn — Guide DevOps

Pipeline complète, 100 % gratuit, sans carte bancaire obligatoire.

```
                 git push main
   ┌──────────────────┴───────────────────┐
   │            GitHub (ItxMveng/ReTurn)   │
   │   ┌─────────────┐   ┌──────────────┐  │
   │   │  Actions CI │   │   Pages      │  │
   │   └──────┬──────┘   └──────┬───────┘  │
   └──────────┼─────────────────┼──────────┘
              │ (tests OK)      │ landing/
              ▼                 ▼
      ┌──────────────┐   Landing page publique
      │   RENDER     │   + bouton ⬇ APK (Release)
      │  API + PG +  │
      │    Redis     │──── images ───► Cloudflare R2 (S3)
      └──────────────┘
```

| Brique | Service | Gratuit | Carte requise |
|--------|---------|---------|---------------|
| Code, CI/CD, APK, Landing | GitHub | ✅ | non |
| API + Redis | Render | ✅ | non |
| PostgreSQL | Neon | ✅ 512 Mo, données conservées | non |
| Stockage images | Cloudflare R2 | ✅ 10 Go | oui (non débitée sous 10 Go) |

> 💡 **Alternative sans carte pour le stockage** : Backblaze B2 (10 Go gratuits, pas de carte). Mêmes réglages, `MINIO_REGION` = la région B2 (ex. `us-east-005`) et `MINIO_ENDPOINT` = `s3.us-east-005.backblazeb2.com`.

---

## Étape 1 — Stockage images (Cloudflare R2)

1. Crée un compte sur https://dash.cloudflare.com → **R2**.
2. **Create bucket** → nom : `docretour-documents`.
3. **Manage R2 API Tokens** → **Create API token** → *Object Read & Write*. Note :
   - **Access Key ID** → deviendra `MINIO_ROOT_USER`
   - **Secret Access Key** → deviendra `MINIO_ROOT_PASSWORD`
   - **Endpoint** (`https://<ACCOUNT_ID>.r2.cloudflarestorage.com`) → `MINIO_ENDPOINT` = `<ACCOUNT_ID>.r2.cloudflarestorage.com` (⚠ sans `https://`)
4. Rends le bucket public en lecture : bucket → **Settings** → **Public access** (ou laisse privé : le proxy `/media` du backend sert déjà les images, donc **public non obligatoire**).

## Étape 2 — Backend (Render)

1. Compte sur https://render.com → **New** → **Blueprint** → connecte le dépôt `ItxMveng/ReTurn`.
2. Render lit `render.yaml` et propose de créer **l'API + Redis**. Valide. (La base PostgreSQL est chez Neon, voir ci-dessous.)
3. **Base de données (Neon)** : crée un compte sur https://neon.tech → nouveau projet (région Frankfurt) → bouton **Connect** → copie la connection string (`postgresql://…?sslmode=require&channel_binding=require`). Elle se colle **telle quelle** dans `DATABASE_URL` : le backend adapte le driver et les paramètres SSL. Les tables sont créées au démarrage par `alembic upgrade head`.
4. Ouvre le service **docretour-api** → **Environment** → renseigne les secrets `sync: false` :

   | Variable | Valeur |
   |----------|--------|
   | `DATABASE_URL` | connection string Neon (étape 3) |
   | `MINIO_ENDPOINT` | `<ACCOUNT_ID>.r2.cloudflarestorage.com` |
   | `MINIO_ROOT_USER` | Access Key ID R2 |
   | `MINIO_ROOT_PASSWORD` | Secret Access Key R2 |
   | `MISTRAL_API_KEY` | ta clé Mistral (OCR) |
   | `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` | ton compte de service Firebase encodé en base64 |
   | `CORS_ORIGINS` | `["https://itxmveng.github.io"]` (URL de ta landing) |

   > Base64 du compte Firebase (PowerShell) :
   > `[Convert]::ToBase64String([IO.File]::ReadAllBytes("firebase-service-account.json"))`

5. Premier déploiement : Render build l'image (`backend/Dockerfile.prod`), applique les migrations (`alembic upgrade head`) et démarre. Vérifie `https://docretour-api.onrender.com/health`.
6. **Deploy Hook** : service → **Settings** → **Deploy Hook** → copie l'URL (elle contient un secret).

## Étape 3 — Déploiement automatique gated (GitHub → Render)

1. Dépôt GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret** :
   - `RENDER_DEPLOY_HOOK_URL` = l'URL du Deploy Hook (étape 2.5)
2. Désormais : **chaque `git push` sur `main`** touchant `backend/**` lance les tests CI ; **s'ils passent**, le déploiement Render est déclenché automatiquement. Si les tests échouent, **la prod n'est pas touchée**. ✅

## Étape 4 — Landing page (GitHub Pages)

1. Dépôt → **Settings** → **Pages** → *Source* : **GitHub Actions**.
2. Un push sur `landing/**` publie la page sur `https://itxmveng.github.io/ReTurn/`.
3. Le bouton de téléchargement pointe déjà vers `releases/latest/download/return.apk`.

## Étape 5 — APK mobile (signature stable + Release)

1. **Génère un keystore** (une seule fois, garde-le précieusement) :
   ```bash
   keytool -genkey -v -keystore return-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias return
   ```
2. Encode-le en base64 :
   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("return-release.jks"))
   ```
3. Ajoute ces **secrets GitHub Actions** :

   | Secret | Valeur |
   |--------|--------|
   | `ANDROID_KEYSTORE_BASE64` | le base64 du keystore |
   | `ANDROID_KEYSTORE_PASSWORD` | mot de passe du store |
   | `ANDROID_KEY_PASSWORD` | mot de passe de la clé |
   | `ANDROID_KEY_ALIAS` | `return` |
   | `PROD_API_BASE_URL` | `https://docretour-api.onrender.com` |
   | `GOOGLE_SERVER_CLIENT_ID` | `774092129161-...apps.googleusercontent.com` |

4. **Publie une version** :
   ```bash
   git tag v1.0.0 && git push origin v1.0.0
   ```
   → Actions build l'APK (lié au backend en ligne), le signe et l'attache à la **Release**. La landing sert alors ce fichier.

> ⚠ Garde le **même keystore** pour toutes les versions : c'est ce qui permet aux bêta-testeurs d'installer les mises à jour **par-dessus** sans désinstaller.

---

## 🔁 Ton flux de travail quotidien

```bash
# 1. Tu corriges / améliores en local, tu testes (run_device.ps1, docker compose)
# 2. Tu valides :
git add -A
git commit -m "fix: ..."
git push                     # → backend redéployé automatiquement SI les tests passent

# 3. Nouvelle version de l'app à distribuer :
git tag v1.0.1 && git push origin v1.0.1   # → nouvel APK sur la Release + landing
```

- **Backend** : `push main` → CI → (si vert) → Render migre + redémarre, **zéro downtime perçu**, **jamais cassé** par un push fautif.
- **Mobile** : `git tag vX.Y.Z` → APK signé publié. Les utilisateurs re-téléchargent depuis la landing.
- **Landing / admin** : `push` sur `landing/**` → mise en ligne automatique.

## 🩺 Dépannage

| Symptôme | Cause probable | Solution |
|----------|----------------|----------|
| Images ne s'affichent pas | `MINIO_*` mal réglés | vérifier endpoint (sans `https://`), `MINIO_SECURE=true`, `MINIO_REGION=auto` |
| API « spin down » lente au 1ᵉʳ appel | plan gratuit Render dort après 15 min | normal ; 1ᵉʳ appel ~30 s puis rapide. Passe au plan payant pour éviter. |
| Déploiement non déclenché | secret `RENDER_DEPLOY_HOOK_URL` absent | l'ajouter dans Actions secrets |
| APK ne s'installe pas en MAJ | keystore différent | toujours réutiliser le même keystore |
| API en crash-loop (« Exited with status 3 ») | base injoignable | vérifier `DATABASE_URL` (Neon) et que le projet Neon existe. (Le PostgreSQL gratuit de Render est supprimé après ~30 j : c'est pourquoi la base est chez Neon.) |

## 🔐 Rappels sécurité
- Aucun secret n'est commité : tout vit dans Render Environment ou GitHub Actions Secrets.
- `key.properties` et `*.jks` sont déjà dans `.gitignore`.
- Sauvegarde ton keystore hors du dépôt (perte = impossible de publier des MAJ).
