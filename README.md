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
│   │   │   └── router.py             # Agrégation de tous les routers
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── dependencies.py       # get_current_user, require_admin (source unique)
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
│   │   └── 004_add_admin_tables.py   # zones, reports, audit_logs, connection_logs
│   ├── tests/
│   │   ├── conftest.py
│   │   ├── test_auth.py
│   │   ├── test_declarations.py
│   │   ├── test_matching.py
│   │   └── test_restitution.py
│   ├── Dockerfile
│   ├── pytest.ini
│   └── requirements.txt
├── mobile/                           # Application Flutter (en cours)
├── infra/                            # Docker Compose, Nginx, scripts
└── docs/
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

### Signalements
| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/my-reports` | Mes signalements |
| `GET` | `/admin/reports` | [Admin] Tous les signalements |
| `PATCH` | `/admin/reports/{id}` | [Admin] Résoudre / rejeter |

### Admin (F-40 → F-44)
| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/admin/stats` | KPIs globaux |
| `GET` | `/admin/stats/users` | DAU / MAU |
| `GET` | `/admin/stats/reports` | Stats signalements |
| `GET` | `/admin/stats/chart` | Séries temporelles |
| `GET` | `/admin/export/declarations` | Export CSV |
| `GET` | `/admin/users` | Liste utilisateurs |
| `GET` | `/admin/users/{id}` | Profil complet |
| `PATCH` | `/admin/users/{id}` | Éditer |
| `DELETE` | `/admin/users/{id}` | Suppression CPDP |
| `GET` | `/admin/users/{id}/sessions` | Historique connexions |
| `GET` | `/admin/users/{id}/export` | Export légal JSON |
| `PATCH` | `/admin/users/{id}/ban` | Bannir |
| `PATCH` | `/admin/users/{id}/unban` | Rétablir |
| `PATCH` | `/admin/users/{id}/promote` | Promouvoir admin |
| `GET` | `/admin/declarations` | Toutes les déclarations |
| `DELETE` | `/admin/declarations/{id}` | Supprimer (modération) |
| `PATCH` | `/admin/declarations/{id}/flag` | Marquer suspect |
| `POST` | `/admin/declarations/bulk` | Import CSV |
| `GET` | `/admin/matches` | Tous les matchs |
| `GET` | `/admin/restitutions` | Toutes les restitutions |
| `GET` | `/admin/zones` | Liste zones |
| `POST` | `/admin/zones` | Créer zone certifiée |
| `PATCH` | `/admin/zones/{id}` | Modifier zone |
| `DELETE` | `/admin/zones/{id}` | Supprimer zone |
| `GET` | `/admin/audit-logs` | Historique actions admin |
| `GET` | `/admin/connection-logs` | Logs connexions globaux |

---

## 🗄️ Migrations Alembic

| # | Fichier | Contenu |
|---|---------|----------|
| 001 | `001_initial_schema.py` | Tables : `users`, `declarations`, `matches`, `messages`, `verifications` |
| 002 | `002_add_event_date_reputation.py` | Colonnes `event_date`, `score_reputation` |
| 003 | `003_add_restitutions_table.py` | Table `restitutions` |
| 004 | `004_add_admin_tables.py` | Tables : `zones`, `reports`, `audit_logs`, `connection_logs` + colonne `is_flagged` sur `declarations` |

```bash
# Appliquer toutes les migrations
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

# 2. Démarrer l'infrastructure
docker compose -f infra/docker-compose.yml up -d

# 3. Appliquer les migrations
cd backend && alembic upgrade head

# 4. Lancer l'API
uvicorn app.main:app --reload
```

Documentation interactive : `http://localhost:8000/docs`

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
| S7 | Application mobile Flutter | 🔄 En cours |
