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
| **Vue d'ensemble** | KPIs en temps réel (utilisateurs, déclarations, matchs, restitutions, signalements, note moyenne), graphique activité 30 j dynamique, donut répartition matchs dynamique, tableau activité récente |
| **Utilisateurs** | Liste paginable, recherche, filtre (actif / banni / admin), **vue détail complète** (historique, stats), bannir / rétablir, **promouvoir admin** |
| **Déclarations** | Liste, recherche, filtre type, flag suspect, suppression, export CSV |
| **Matchs** | Score coloré (vert ≥80 %, orange ≥50 %, rouge <50 %), statut, liens déclarations |
| **Restitutions** | Statut, note, dates d'initiation et de complétion |
| **Signalements** | Résolution en 1 clic |
| **Zones certifiées** | **Formulaire de création complet** (nom, ville, lat/lon, rayon, certification), suppression |
| **Audit Logs** | Historique chronologique des actions admin |
| **Mode démo** | Double-clic sur le logo → accès immédiat sans backend |
| **Mode sombre** | Bascule clair/sombre intégrée |

### Lancer le dashboard admin

#### ✅ Option 1 — Python (recommandé, zéro dépendance)

```bash
# Depuis la racine du projet
cd admin
python3 -m http.server 3000
```

> Ouvrir **http://localhost:3000** dans le navigateur.

#### Option 2 — Node.js / npx

```bash
npx serve admin -l 3000
```

#### Option 3 — Ouvrir directement (mode démo uniquement)

```bash
open admin/index.html       # macOS
start admin/index.html      # Windows
xdg-open admin/index.html   # Linux
```

> ⚠️ En `file://`, les appels API sont bloqués par CORS. Utilisez un serveur local pour les données réelles.

---

### Se connecter en mode développement (mock data)

Pas besoin de backend. Deux options :

**Option A — Double-clic sur le logo ReTurn** dans l'écran de login
- Accès immédiat avec email `admin@return.cm`
- Toutes les sections affichent des données fictives réalistes

**Option B — Saisir n'importe quel email + mot de passe valides**
- Si l'API n'est pas joignable, le dashboard bascule automatiquement en mode mock

---

### Se connecter en mode production (API réelle)

**Étape 1 — Démarrer le backend**

```bash
# Infrastructure (PostgreSQL, Redis, MinIO)
docker compose -f infra/docker-compose.yml up -d

# Migrations
cd backend && alembic upgrade head

# API
uvicorn app.main:app --reload
# → http://localhost:8000
```

**Étape 2 — Créer votre premier compte admin**

Inscrivez-vous d'abord via l'API (ou l'app mobile), puis promouvez le compte en admin :

```sql
-- Via psql, pgAdmin ou DBeaver
UPDATE users SET is_admin = true WHERE phone = '+237XXXXXXXXX';
-- ou par email :
UPDATE users SET is_admin = true WHERE email = 'votre@email.com';
```

Alternativement, depuis le dashboard lui-même (si vous êtes déjà admin) :
> **Utilisateurs → trouver le compte → bouton "Promouvoir admin"**

**Étape 3 — Se connecter**

Ouvrir **http://localhost:3000**, saisir l'email et le mot de passe du compte admin.

---

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
| `POST` | `/auth/register` | Inscription |
| `POST` | `/auth/login` | Connexion → JWT |
| `POST` | `/auth/refresh` | Renouvellement token |
| `POST` | `/auth/logout` | Invalidation token |

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
