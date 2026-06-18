# ReTurn — DocRetour 🇨🇲

> Plateforme de restitution sécurisée de documents perdus au Cameroun.

[![FastAPI](https://img.shields.io/badge/FastAPI-0.111-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql)](https://www.postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docs.docker.com/compose)

---

## 📁 Structure du projet

```
ReTurn/
├── backend/
│   ├── app/
│   │   ├── api/v1/
│   │   │   ├── endpoints/
│   │   │   │   ├── admin.py          # Backoffice — 27 routes (F-40→F-44)
│   │   │   │   ├── auth.py           # Inscription, connexion, refresh JWT
│   │   │   │   ├── declarations.py   # CRUD déclarations (trouvé / perdu)
│   │   │   │   ├── matches.py        # Matchs automatiques
│   │   │   │   ├── messaging.py      # Messagerie WebSocket + REST
│   │   │   │   ├── profile.py        # Profil utilisateur
│   │   │   │   ├── reports.py        # Signalements utilisateurs
│   │   │   │   └── restitutions.py   # Processus de restitution
│   │   │   └── router.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── dependencies.py
│   │   │   ├── firebase_admin.py
│   │   │   ├── redis_client.py
│   │   │   ├── security.py
│   │   │   └── ws_manager.py
│   │   ├── models/
│   │   │   ├── audit_log.py
│   │   │   ├── connection_log.py
│   │   │   ├── declaration.py
│   │   │   ├── match.py
│   │   │   ├── message.py
│   │   │   ├── report.py
│   │   │   ├── restitution.py
│   │   │   ├── user.py
│   │   │   ├── verification.py
│   │   │   └── zone.py
│   │   ├── schemas/
│   │   ├── services/
│   │   ├── workers/
│   │   └── main.py
│   ├── alembic/versions/
│   │   ├── 001_initial_schema.py
│   │   ├── 002_add_event_date_reputation.py
│   │   ├── 003_add_restitutions_table.py
│   │   └── 004_add_admin_tables.py
│   ├── tests/
│   │   ├── conftest.py
│   │   ├── test_auth.py
│   │   ├── test_declarations.py
│   │   ├── test_matching.py
│   │   └── test_restitution.py
│   ├── Dockerfile
│   ├── pytest.ini
│   └── requirements.txt
├── mobile/
│   └── lib/
│       ├── core/
│       │   ├── network/
│       │   │   ├── api_client.dart
│       │   │   ├── auth_interceptor.dart
│       │   │   ├── dio_provider.dart
│       │   │   └── interceptors.dart
│       │   ├── errors/
│       │   │   ├── app_exception.dart
│       │   │   └── error_handler.dart
│       │   ├── providers/
│       │   │   ├── app_providers.dart
│       │   │   └── settings_provider.dart
│       │   ├── router/
│       │   │   └── app_router.dart
│       │   ├── services/
│       │   │   ├── biometric_service.dart
│       │   │   └── notification_service.dart
│       │   └── widgets/
│       │       ├── app_button.dart
│       │       ├── app_empty_state.dart
│       │       ├── app_error_widget.dart
│       │       ├── app_loader.dart
│       │       ├── app_text_field.dart
│       │       ├── error_view.dart
│       │       └── scaffold_with_nav_bar.dart
│       └── features/
│           ├── auth/
│           ├── declarations/
│           │   ├── models/declaration.dart
│           │   ├── pages/
│           │   │   ├── declarations_list_page.dart
│           │   │   ├── declaration_form_page.dart
│           │   │   └── declaration_detail_page.dart
│           │   ├── providers/
│           │   │   ├── declaration_provider.dart
│           │   │   └── declarations_provider.dart
│           │   └── widgets/declaration_card.dart
│           ├── matches/
│           │   ├── models/match.dart
│           │   ├── pages/
│           │   │   ├── matches_list_page.dart
│           │   │   └── match_detail_page.dart
│           │   ├── providers/matches_provider.dart
│           │   └── repositories/matches_repository.dart
│           ├── matching/
│           │   ├── providers/matching_provider.dart
│           │   ├── repositories/matching_repository.dart
│           │   └── screens/matching_screen.dart
│           ├── messaging/pages/
│           │   ├── conversations_page.dart
│           │   └── chat_page.dart
│           ├── ocr/pages/
│           │   ├── ocr_scan_page.dart
│           │   └── ocr_review_page.dart
│           ├── profile/pages/profile_page.dart
│           ├── restitution/pages/restitution_page.dart
│           ├── settings/pages/settings_page.dart
│           ├── splash/
│           └── support/support_screen.dart
├── admin/
│   └── index.html                    # Dashboard admin web (standalone)
├── infra/
└── docs/
```

---

## 🖥️ Dashboard Admin Web

Interface d'administration **100 % statique** (`admin/index.html`) — aucun build, aucune dépendance Node.js.

### Fonctionnalités

| Section | Capacités |
|---------|----------|
| **Vue d'ensemble** | KPIs en temps réel (utilisateurs, déclarations, matchs, restitutions, signalements, délai moyen de résolution), graphique activité 30 j dynamique, synthèse du flux récent, tableau activité récente |
| **Utilisateurs** | Liste paginable, recherche, filtre (actif / banni / admin), **vue détail complète** (historique, stats), bannir / rétablir, **promouvoir admin** |
| **Déclarations** | Liste, recherche, filtre type, flag suspect, suppression, export CSV |
| **Matchs** | Score coloré (vert ≥80 %, orange ≥50 %, rouge <50 %), statut, liens déclarations |
| **Restitutions** | Statut, note, dates d'initiation et de complétion |
| **Signalements** | Résolution en 1 clic |
| **Zones certifiées** | Création et suppression de zones réelles (nom, type, adresse, latitude, longitude, certification) |
| **Audit Logs** | Historique chronologique des actions admin |
| **Mode sombre** | Bascule clair/sombre intégrée |

### Important

- Le backoffice admin n'utilise plus de données fictives.
- Il n'y a plus de connexion email/mot de passe locale.
- La connexion admin passe par le **même backend réel** que le mobile, via **OTP**.
- Le numéro utilisé dans l'écran admin doit exister en base et avoir `is_admin = true`.

### Lancement complet en données réelles

#### 1. Démarrer Docker proprement

Depuis la racine du projet :

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d postgres redis minio
```

Si Docker retourne une erreur du type :

```text
dockerDesktopLinuxEngine ... request returned 500 Internal Server Error
```

faites ceci avant de relancer :

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml down
docker compose --env-file infra/.env -f infra/docker-compose.yml pull
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d postgres redis minio
```

Si l'erreur persiste, le problème vient de Docker Desktop et non du projet :
- redémarrer Docker Desktop
- vérifier que Docker Desktop est bien en mode conteneurs Linux
- relancer ensuite la commande `docker compose ... up -d`

#### 2. Appliquer les migrations backend

Le backend lit maintenant automatiquement `infra/.env`, donc il n'est plus nécessaire de dupliquer la configuration dans `backend/.env`.

```bash
cd backend
alembic upgrade head
```

Si vous voyez encore `ModuleNotFoundError: No module named 'app'`, assurez-vous simplement d'être bien dans le dossier `backend` avant d'exécuter la commande.

#### 3. Démarrer l'API

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API disponible sur `http://localhost:8000`

#### 4. Créer ou activer le compte administrateur

Le compte admin est un **vrai utilisateur** de la plateforme, promu côté base.

Étape A : créez le compte utilisateur avec le flux OTP réel.

PowerShell :

```powershell
Invoke-RestMethod `
  -Method Post `
  -Uri http://localhost:8000/api/v1/auth/otp/request `
  -ContentType 'application/json' `
  -Body '{"phone_number":"+237600000000"}'
```

En environnement local avec `DEBUG=true`, l'API renvoie aussi `debug_code`. Utilisez ce code pour vérifier l'OTP :

```powershell
Invoke-RestMethod `
  -Method Post `
  -Uri http://localhost:8000/api/v1/auth/otp/verify `
  -ContentType 'application/json' `
  -Body '{"phone_number":"+237600000000","otp_code":"123456"}'
```

Cette vérification crée l'utilisateur en base s'il n'existe pas encore.

Étape B : promouvez ensuite ce compte en administrateur.

Exemple avec les valeurs par défaut de `infra/.env` :

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml exec postgres psql -U docretour_user -d docretour_db -c "UPDATE docretour.users SET is_admin = true WHERE phone_number = '+237600000000';"
```

Si vous avez changé `POSTGRES_USER` ou `POSTGRES_DB` dans `infra/.env`, remplacez ces valeurs dans la commande ci-dessus.

Vous pouvez vérifier :

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml exec postgres psql -U docretour_user -d docretour_db -c "SELECT phone_number, is_admin FROM docretour.users ORDER BY created_at DESC;"
```

#### 5. Lancer le backoffice admin

Option recommandée :

```bash
cd admin
python -m http.server 3000
```

Ouvrir ensuite `http://localhost:3000`

#### 6. Connexion au panneau admin

1. Saisir le **numéro de téléphone** du compte promu administrateur.
2. Cliquer sur `Recevoir le code`.
3. En local, si `DEBUG=true`, le code renvoyé par l'API est automatiquement injecté dans le champ OTP.
4. Cliquer sur `Se connecter`.

Si la connexion retourne `403`, cela signifie généralement :
- que le compte existe mais n'a pas encore `is_admin = true`
- ou que l'OTP a bien été validé mais avec le mauvais numéro

### Configurer l'URL de l'API

Par défaut le dashboard pointe vers `http://localhost:8000`. Pour changer :

```html
<!-- Ajouter avant </body> dans admin/index.html -->
<script>window.RETURN_API_URL = 'https://api.return.cm';</script>
```

Ou via Nginx en production :

```nginx
location /admin {
  root /var/www/return;
  try_files $uri $uri/ /admin/index.html;
  add_header Content-Security-Policy
    "default-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net";
}
```

---

## 🔌 API Endpoints `/api/v1`

### Auth
| Méthode | Route | Description |
|---------|-------|-------------|
| `POST` | `/auth/otp/request` | Demande un code OTP |
| `POST` | `/auth/otp/verify` | Vérifie l'OTP et retourne les JWT |
| `POST` | `/auth/verify-firebase-token` | Connexion via token Firebase |
| `POST` | `/auth/refresh` | Renouvelle les tokens |
| `GET` | `/auth/me` | Retourne l'utilisateur connecté |

### Profil
| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/profile/me` | Mon profil |
| `PATCH` | `/profile/me` | Mettre à jour mon profil |
| `POST` | `/profile/me/fcm-token` | Enregistrer token FCM |

### Déclarations
| Méthode | Route | Description |
|---------|-------|-------------|
| `POST` | `/declarations` | Créer une déclaration |
| `GET` | `/declarations` | Lister mes déclarations |
| `GET` | `/declarations/{id}` | Détail d'une déclaration |
| `PATCH` | `/declarations/{id}` | Modifier une déclaration |
| `DELETE` | `/declarations/{id}` | Supprimer |

### Matchs
| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/matches` | Mes matchs |
| `GET` | `/matches/{id}` | Détail d'un match |
| `PATCH` | `/matches/{id}/confirm` | Confirmer un match |

### Restitutions
| Méthode | Route | Description |
|---------|-------|-------------|
| `POST` | `/restitutions` | Initier une restitution |
| `GET` | `/restitutions/{id}` | Détail |
| `PATCH` | `/restitutions/{id}/complete` | Marquer comme terminée |
| `POST` | `/restitutions/{id}/rate` | Laisser une note |

### Messagerie
| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/messaging/conversations` | Liste des conversations |
| `GET` | `/messaging/conversations/{id}/messages` | Messages d'une conversation |
| `POST` | `/messaging/conversations/{id}/messages` | Envoyer un message |
| `WS` | `/messaging/ws/{conversation_id}` | WebSocket temps réel |

### Admin (F-40 → F-44)
| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/admin/stats` | KPIs globaux |
| `GET` | `/admin/export/declarations` | Export CSV |
| `GET/PATCH/DELETE` | `/admin/users/{id}` | Gestion utilisateurs |
| `PATCH` | `/admin/users/{id}/ban` | Bannir |
| `PATCH` | `/admin/users/{id}/unban` | Rétablir |
| `PATCH` | `/admin/users/{id}/promote` | Promouvoir admin |
| `GET/DELETE/PATCH` | `/admin/declarations/{id}` | Modération déclarations |
| `GET` | `/admin/matches` | Tous les matchs |
| `GET` | `/admin/restitutions` | Toutes les restitutions |
| `GET/POST/PATCH/DELETE` | `/admin/zones` | Zones certifiées |
| `GET` | `/admin/audit-logs` | Historique actions |
| `PATCH` | `/admin/reports/{id}` | Résoudre signalement |

---

## 🗄️ Migrations Alembic

| # | Fichier | Contenu |
|---|---------|----------|
| 001 | `001_initial_schema.py` | Tables : `users`, `declarations`, `matches`, `messages`, `verifications` |
| 002 | `002_add_event_date_reputation.py` | Colonnes `event_date`, `score_reputation` |
| 003 | `003_add_restitutions_table.py` | Table `restitutions` |
| 004 | `004_add_admin_tables.py` | Tables : `zones`, `reports`, `audit_logs`, `connection_logs` |

```bash
cd backend && alembic upgrade head
```

---

## 🧪 Tests

| Fichier | Couvre |
|---------|--------|
| `tests/test_auth.py` | Inscription, login, JWT |
| `tests/test_declarations.py` | CRUD, pagination cursor |
| `tests/test_matching.py` | Jaro-Winkler, Haversine, scoring |
| `tests/test_restitution.py` | Idempotence, rating, réputation |

```bash
cd backend
pip install -r requirements.txt
pytest -v
```

---

## 🚀 Démarrage rapide

```bash
# 1. Variables d'environnement
cp backend/.env.example backend/.env

# 2. Infrastructure (PostgreSQL, Redis, MinIO)
docker compose -f infra/docker-compose.yml up -d

# 3. Migrations
cd backend && alembic upgrade head

# 4. API FastAPI
uvicorn app.main:app --reload

# 5. Dashboard Admin
cd ../admin && python3 -m http.server 3000
```

| Service | URL |
|---------|-----|
| API FastAPI | http://localhost:8000 |
| Swagger UI | http://localhost:8000/docs |
| Dashboard Admin | http://localhost:3000 |
| MinIO Console | http://localhost:9001 |

---

## 📋 Sprints

| Sprint | Objectif | Statut |
|--------|----------|--------|
| S0 | Structure monorepo, Docker, squelette API | ✅ |
| S1 | Auth JWT (OTP, inscription, connexion, refresh) | ✅ |
| S2 | Déclarations (CRUD, upload photo, géolocalisation) | ✅ |
| S3 | Matching automatique (Jaro-Winkler + Haversine) | ✅ |
| S4 | Messagerie temps réel (WebSocket + profil) | ✅ |
| S5 | Restitutions, signalements, réputation | ✅ |
| S6 | Backoffice admin (F-40→F-44, audit, zones, stats) | ✅ |
| S7 | Application mobile Flutter | ✅ |
| S8 | Dashboard admin web — complet (modal zone, détail user, promouvoir, graphiques dynamiques) | ✅ |
