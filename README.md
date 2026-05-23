# DocRetour

Application mobile de **restitution sécurisée de documents perdus au Cameroun**.

Un citoyen qui trouve un document peut le déclarer ; le propriétaire est notifié et peut le récupérer via un processus vérifié et sécurisé.

---

## Prérequis

| Outil | Version minimale |
|---|---|
| [Flutter](https://flutter.dev/docs/get-started/install) | 3.19+ |
| [Python](https://www.python.org/downloads/) | 3.12+ |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | 4.x (avec Docker Compose v2) |

---

## Démarrage rapide (5 commandes)

```powershell
# 1. Copier les variables d'environnement
Copy-Item infra\.env.example infra\.env

# 2. Lancer l'infrastructure (Postgres, Redis, MinIO, Backend)
cd infra
docker compose up -d

# 3. Vérifier que le backend répond
Invoke-RestMethod http://localhost:8000/health

# 4. Installer les dépendances Flutter
cd ..\mobile
flutter pub get

# 5. Lancer l'application Flutter (émulateur ou appareil connecté)
flutter run
```

---

## Structure du projet

```
docretour/
├── mobile/                   # Application Flutter (Dart)
│   ├── lib/
│   │   ├── core/             # Config, thème, router, utils
│   │   ├── features/         # Modules métier (auth, déclarations, matching…)
│   │   └── shared/           # Widgets et modèles réutilisables
│   └── pubspec.yaml
├── backend/                  # API REST FastAPI (Python 3.12)
│   ├── alembic.ini           # Config Alembic (migrations)
│   ├── alembic/
│   │   ├── env.py            # Environnement async Alembic
│   │   └── versions/
│   │       ├── 001_initial_schema.py          # Schéma initial complet
│   │       ├── 002_add_event_date_reputation.py  # event_date, score_reputation, confirmed_by_*
│   │       └── 003_add_restitutions_table.py  # Table restitutions
│   ├── app/
│   │   ├── api/v1/
│   │   │   ├── router.py     # Routeur principal (tous les endpoints enregistrés)
│   │   │   └── endpoints/
│   │   │       ├── auth.py          # S1 — Authentification OTP + JWT
│   │   │       ├── declarations.py  # S2 — Déclarations (+ event_date, F-15, pagination cursor)
│   │   │       ├── matches.py       # S3 — Matching + double-confirmation + création restitution
│   │   │       ├── messaging.py     # S4 — Messagerie temps réel (WebSocket + Redis pub/sub)
│   │   │       ├── profile.py       # S4 — Profil utilisateur + DELETE RGPD (F-04)
│   │   │       └── restitutions.py  # S4 — Cycle de restitution complet (nouveau)
│   │   ├── core/
│   │   │   ├── config.py     # Variables d'environnement (pydantic-settings)
│   │   │   ├── database.py   # Engine async SQLAlchemy + Base
│   │   │   ├── dependencies.py # get_current_user, JWT decode
│   │   │   └── redis_client.py # Connexion Redis async
│   │   ├── models/
│   │   │   ├── __init__.py   # Import de tous les modèles (requis pour Alembic)
│   │   │   ├── user.py       # +score_reputation (float, défaut 5.0)
│   │   │   ├── declaration.py # +event_date (date)
│   │   │   ├── match.py      # +confirmed_by_owner, +confirmed_by_finder
│   │   │   ├── message.py
│   │   │   ├── restitution.py # Nouveau — cycle complet de remise physique
│   │   │   └── verification.py
│   │   ├── schemas/
│   │   │   ├── auth.py
│   │   │   ├── declaration.py  # +event_date dans Create/Update/Read
│   │   │   ├── match.py        # +MatchConfirmResponse (confirmed_by_*, restitution_id)
│   │   │   ├── message.py
│   │   │   ├── restitution.py  # Nouveau — RestitutionRead, RestitutionUpdate, RestitutionRating
│   │   │   ├── user.py         # +score_reputation dans UserRead
│   │   │   └── verification.py
│   │   └── services/
│   │       ├── auth_service.py
│   │       ├── declaration_service.py  # +count_active(), +list_declarations_cursor()
│   │       ├── matching_service.py     # Algorithme Jaro-Winkler + Haversine
│   │       ├── messaging_service.py
│   │       ├── notification_service.py
│   │       ├── otp_service.py
│   │       ├── restitution_service.py  # Nouveau — lifecycle complet + réputation
│   │       ├── storage_service.py      # MinIO upload/delete
│   │       └── verification_service.py
│   ├── tests/
│   │   ├── conftest.py         # Fixtures partagées (SQLite in-memory, fake Redis, mock MinIO)
│   │   ├── test_auth.py        # Tests auth_service
│   │   ├── test_declarations.py # Tests F-15, pagination cursor, CRUD
│   │   ├── test_matching.py    # Tests score components + compute_score
│   │   └── test_restitution.py # Tests cycle restitution + réputation
│   ├── pytest.ini
│   ├── requirements.txt
│   └── Dockerfile
├── infra/                     # Orchestration Docker
│   ├── docker-compose.yml       # Dev local
│   ├── docker-compose.prod.yml  # Production
│   ├── nginx/                   # Reverse proxy
│   └── postgres/                # Script d'init SQL
└── docs/api/                  # Documentation OpenAPI exportée
```

---

## API — Endpoints disponibles

### Auth (`/api/v1/auth`)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/send-otp` | Envoi OTP par SMS |
| POST | `/verify-otp` | Vérification OTP → tokens JWT |
| POST | `/refresh` | Renouvellement access token |
| POST | `/logout` | Révocation refresh token |

### Profil (`/api/v1/profile`)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/` | Récupérer son profil |
| PATCH | `/` | Modifier son profil |
| PATCH | `/avatar` | Mettre à jour l'avatar |
| **DELETE** | **`/`** | **Suppression compte (RGPD F-04)** |

### Déclarations (`/api/v1/declarations`)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/` | Créer une déclaration (max 3 actives — F-15) |
| GET | `/` | Lister ses déclarations (pagination cursor) |
| GET | `/{id}` | Détail d'une déclaration |
| PATCH | `/{id}` | Modifier une déclaration |
| DELETE | `/{id}` | Supprimer une déclaration |
| POST | `/{id}/photos` | Ajouter une photo (max 3) |

### Matchs (`/api/v1/matches`)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/` | Lister ses matchs |
| GET | `/{id}` | Détail d'un match |
| POST | `/{id}/action` | Confirmer ou ignorer (double-confirmation, crée la restitution automatiquement) |
| GET | `/notifications` | Notifications en attente |
| DELETE | `/notifications` | Vider les notifications |

### Restitutions (`/api/v1/restitutions`) — *nouveau*
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/{id}` | Détail d'une restitution |
| PATCH | `/{id}` | Modifier lieu de RDV / statut |
| POST | `/{id}/photos` | Uploader une photo preuve |
| POST | `/{id}/rate` | Noter la restitution (1-5★ → met à jour score_reputation) |

### Messagerie (`/api/v1/messaging`)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/{match_id}/history` | Historique des messages |
| WS | `/ws/{match_id}` | WebSocket temps réel |
| POST | `/{match_id}/mark-read` | Marquer comme lu |

---

## Migrations de base de données (Alembic)

```bash
# Depuis le dossier backend/ (ou dans le conteneur Docker)

# Appliquer toutes les migrations
alembic upgrade head

# Voir l'état actuel
alembic current

# Créer une nouvelle migration automatique
alembic revision --autogenerate -m "description"

# Rollback d'une migration
alembic downgrade -1
```

### Historique des migrations

| Révision | Description |
|----------|-------------|
| `001` | Schéma initial : users, declarations, matches, messages, identity_verifications |
| `002` | Ajout `event_date` (declarations), `score_reputation` (users), `confirmed_by_owner/finder` (matches) |
| `003` | Nouvelle table `restitutions` |

---

## Tests

```bash
# Depuis backend/
pip install -r requirements.txt
pytest

# Avec rapport de couverture
pytest --cov=app --cov-report=term-missing

# Un test spécifique
pytest tests/test_matching.py -v
```

Les tests utilisent **SQLite in-memory** + mocks MinIO/Redis : aucun service externe requis.

| Fichier | Ce qui est testé |
|---------|-----------------|
| `test_auth.py` | Création utilisateur, lookup téléphone, génération JWT |
| `test_declarations.py` | Limite F-15, pagination cursor, CRUD complet |
| `test_matching.py` | Score Jaro-Winkler, Haversine, compute_score parfait/nul |
| `test_restitution.py` | Création idempotente, autorisation, notation, réputation |

---

## Variables d'environnement

Toutes les variables sont documentées dans `infra/.env.example` et `backend/.env.example`.
Copiez `infra/.env.example` → `infra/.env` et adaptez avant de lancer Docker.

> Ne commitez jamais `.env`. Il est dans le `.gitignore`.

---

## Commandes utiles

```powershell
# Logs backend en temps réel
docker compose -f infra/docker-compose.yml logs -f backend

# Console MinIO
Start-Process http://localhost:9001

# Documentation Swagger interactive
Start-Process http://localhost:8000/docs

# Relancer le backend après modification
docker compose -f infra/docker-compose.yml restart backend

# Arrêter (volumes conservés)
docker compose -f infra/docker-compose.yml down

# Reset complet (supprime les volumes)
docker compose -f infra/docker-compose.yml down -v
```

---

## Sprints

| Sprint | Objectif | Statut |
|--------|----------|--------|
| S0 | Structure monorepo, infrastructure Docker, squelette API | ✅ |
| S1 | Authentification JWT (inscription, connexion, refresh) | ✅ |
| S2 | Déclarations de documents (trouver / perdu) | ✅ |
| S3 | Matching automatique Jaro-Winkler + Haversine, notifications | ✅ |
| S4 | Messagerie temps réel, profil, restitution, tests, migrations | ✅ |

---

## Licence

Propriétaire — © 2026 DocRetour. Tous droits réservés.
