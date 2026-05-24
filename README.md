# ReTurn — DocRetour 🇨🇲

> **Plateforme de restitution sécurisée de documents perdus au Cameroun**
>
> Un citoyen trouve une pièce d'identité, la déclare dans l'app → le propriétaire
> est notifié via un algorithme de matching → les deux parties se retrouvent en
> toute sécurité pour restituer le document.

---

## Table des matières

1. [Stack technique](#stack-technique)
2. [Structure du projet](#structure-du-projet)
3. [Démarrage rapide](#démarrage-rapide)
4. [API Backend](#api-backend)
5. [Architecture mobile (Flutter)](#architecture-mobile-flutter)
6. [Migrations Alembic](#migrations-alembic)
7. [Tests](#tests)
8. [Roadmap Sprints](#roadmap-sprints)

---

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter 3.x (Dart) — Riverpod + Freezed + Go Router |
| Backend | FastAPI (Python 3.12) — SQLAlchemy async + Alembic |
| Base de données | PostgreSQL 16 |
| Cache / Files | Redis 7 |
| Stockage objets | MinIO (S3-compatible) |
| Proxy | Nginx |
| Containerisation | Docker + Docker Compose |
| Tests | pytest + pytest-asyncio + aiosqlite |

---

## Structure du projet

```
ReTurn/
├── backend/
│   ├── app/
│   │   ├── api/v1/endpoints/
│   │   │   ├── auth.py              # S1 — Inscription, connexion, refresh
│   │   │   ├── declarations.py      # S2 — CRUD déclarations
│   │   │   ├── matches.py           # S3 — Matching + notifications
│   │   │   ├── restitutions.py      # S3 — Restitution + photos + notation
│   │   │   ├── messaging.py         # S4 — Messagerie temps réel
│   │   │   └── profile.py           # S4 — Profil utilisateur
│   │   ├── core/
│   │   │   ├── config.py            # Variables d'environnement
│   │   │   ├── database.py          # Engine async SQLAlchemy
│   │   │   ├── redis_client.py      # Pool Redis
│   │   │   ├── security.py          # JWT + hashing
│   │   │   └── dependencies.py      # get_current_user
│   │   ├── models/                  # ORM SQLAlchemy
│   │   │   ├── user.py
│   │   │   ├── declaration.py
│   │   │   ├── match.py
│   │   │   ├── restitution.py
│   │   │   └── message.py
│   │   ├── schemas/                 # Pydantic v2
│   │   ├── services/
│   │   │   ├── matching_service.py  # Jaro-Winkler + Haversine
│   │   │   ├── restitution_service.py
│   │   │   ├── notification_service.py
│   │   │   └── storage_service.py   # MinIO
│   │   └── main.py
│   ├── migrations/
│   │   ├── versions/
│   │   │   ├── 001_initial_schema.py
│   │   │   ├── 002_fcm_token.py
│   │   │   └── 003_user_profile.py
│   │   └── env.py
│   ├── tests/
│   │   ├── conftest.py              # SQLite in-memory + fake Redis + mock MinIO
│   │   ├── test_auth.py             # Inscription, lookup téléphone, JWT
│   │   ├── test_declarations.py     # CRUD, pagination cursor, F-15
│   │   ├── test_matching.py         # Jaro-Winkler, Haversine, compute_score
│   │   └── test_restitution.py      # Idempotence, autorisation, rating, réputation
│   ├── pytest.ini
│   └── requirements.txt
├── mobile/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── network/
│   │   │   │   └── api_client.dart          # Dio + intercepteurs JWT
│   │   │   ├── router/
│   │   │   │   ├── app_router.dart          # Go Router complet ✅ Commit F
│   │   │   │   └── route_names.dart         # Constantes de routes ✅ Commit F
│   │   │   ├── theme/
│   │   │   │   └── app_colors.dart
│   │   │   ├── errors/
│   │   │   │   └── error_handler.dart
│   │   │   └── widgets/
│   │   │       └── scaffold_with_nav_bar.dart
│   │   └── features/
│   │       ├── auth/
│   │       │   ├── data/
│   │       │   │   ├── models/auth_model.dart
│   │       │   │   └── repositories/auth_repository.dart
│   │       │   ├── application/
│   │       │   │   ├── auth_notifier.dart
│   │       │   │   └── auth_state.dart
│   │       │   └── presentation/pages/
│   │       │       ├── login_page.dart
│   │       │       ├── register_page.dart
│   │       │       └── otp_verify_page.dart
│   │       ├── declarations/
│   │       │   ├── data/
│   │       │   │   ├── models/declaration_model.dart
│   │       │   │   └── repositories/declarations_repository.dart
│   │       │   ├── application/declarations_notifier.dart
│   │       │   └── presentation/pages/
│   │       │       ├── declarations_list_page.dart
│   │       │       ├── declaration_form_page.dart
│   │       │       └── declaration_detail_page.dart
│   │       ├── matches/                              ✅ Commit E
│   │       │   ├── data/
│   │       │   │   ├── models/
│   │       │   │   │   ├── match_model.dart
│   │       │   │   │   └── restitution_model.dart
│   │       │   │   └── repositories/matches_repository.dart
│   │       │   ├── application/matches_notifier.dart
│   │       │   └── presentation/
│   │       │       ├── pages/
│   │       │       │   ├── matches_list_page.dart
│   │       │       │   ├── match_detail_page.dart
│   │       │       │   └── restitution_detail_page.dart
│   │       │       └── widgets/match_card.dart
│   │       ├── home/
│   │       │   └── presentation/pages/home_page.dart  ✅ Commit F
│   │       └── profile/
│   │           └── presentation/pages/profile_page.dart
│   └── pubspec.yaml
├── infra/
│   ├── docker-compose.yml
│   ├── nginx/nginx.conf
│   └── .env.example
└── docs/
    └── api.md
```

---

## Démarrage rapide

### Backend

```bash
cd infra
cp .env.example .env          # remplir les variables
docker compose up -d          # PostgreSQL + Redis + MinIO + Nginx

cd ../backend
pip install -r requirements.txt
alembic upgrade head          # Appliquer toutes les migrations
uvicorn app.main:app --reload --port 8000
```

Docs interactives : <http://localhost:8000/docs>

### Mobile

```bash
cd mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Tests backend

```bash
cd backend
pytest -v
```

---

## API Backend

### Authentification

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/auth/register` | Inscription (téléphone + mot de passe) |
| `POST` | `/api/v1/auth/login` | Connexion → JWT access + refresh |
| `POST` | `/api/v1/auth/refresh` | Renouveler l'access token |
| `POST` | `/api/v1/auth/logout` | Révoquer le refresh token |

### Profil utilisateur

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/profile/me` | Profil de l'utilisateur connecté |
| `PATCH` | `/api/v1/profile/me` | Mettre à jour le profil |
| `POST` | `/api/v1/profile/me/photo` | Upload photo de profil |
| `POST` | `/api/v1/profile/fcm-token` | Enregistrer le token FCM |

### Déclarations

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/declarations/` | Lister (cursor pagination) |
| `POST` | `/api/v1/declarations/` | Créer une déclaration |
| `GET` | `/api/v1/declarations/{id}` | Détail d'une déclaration |
| `PATCH` | `/api/v1/declarations/{id}` | Modifier |
| `DELETE` | `/api/v1/declarations/{id}` | Supprimer |
| `POST` | `/api/v1/declarations/{id}/photos` | Upload une photo |

### Matchs & Correspondances

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/matches/` | Mes matchs (trié par score) |
| `GET` | `/api/v1/matches/{id}` | Détail d'un match |
| `POST` | `/api/v1/matches/{id}/action` | Confirmer ou ignorer |
| `GET` | `/api/v1/matches/notifications` | Notifications en attente |
| `DELETE` | `/api/v1/matches/notifications` | Effacer les notifications |

### Restitutions

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/restitutions/{id}` | Détail d'une restitution |
| `PATCH` | `/api/v1/restitutions/{id}` | Mettre à jour lieu / statut |
| `POST` | `/api/v1/restitutions/{id}/photos` | Upload photo de preuve |
| `POST` | `/api/v1/restitutions/{id}/rate` | Soumettre une note (1-5 ⭐) |

### Messagerie

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/messaging/{match_id}` | Historique des messages |
| `POST` | `/api/v1/messaging/{match_id}` | Envoyer un message |
| `WS` | `/api/v1/ws/chat/{match_id}` | WebSocket temps réel |

---

## Architecture mobile (Flutter)

L'app suit l'architecture **Feature-first** avec **Riverpod + Freezed + Go Router**.

```
feature/
├── data/
│   ├── models/       # Freezed (JSON serialization)
│   └── repositories/ # Appels API via ApiClient (Dio)
├── application/      # Notifiers Riverpod (state management)
└── presentation/
    ├── pages/        # Écrans complets
    └── widgets/      # Composants réutilisables
```

### Navigation (Go Router)

| Route | Nom | Page |
|-------|-----|------|
| `/splash` | `splash` | Vérification auth |
| `/login` | `login` | Connexion |
| `/register` | `register` | Inscription |
| `/otp-verify` | `otp-verify` | Vérification OTP |
| `/home` | `home` | Tableau de bord |
| `/declarations` | `declarations` | Liste des déclarations |
| `/declarations/new` | `new-declaration` | Formulaire |
| `/declarations/:id` | `declaration-detail` | Détail |
| `/matches` | `matches` | Liste matchs (3 onglets) |
| `/matches/:id` | `match-detail` | Détail + confirmer/ignorer |
| `/restitutions/:id` | `restitution-detail` | Restitution + notation |
| `/messaging` | `messaging` | Liste conversations |
| `/messaging/:matchId` | `conversation` | Chat |
| `/profile` | `profile` | Profil utilisateur |
| `/profile/edit` | `edit-profile` | Modifier le profil |

---

## Migrations Alembic

```bash
alembic upgrade head          # Appliquer toutes les migrations
alembic downgrade -1          # Revenir en arrière d'une version
alembic revision --autogenerate -m "description"  # Nouvelle migration
```

| Révision | Description |
|----------|-------------|
| `001` | Schéma initial (users, declarations, matches, restitutions, messages) |
| `002` | Ajout colonne `fcm_token` sur `users` |
| `003` | Ajout colonnes profil (`full_name`, `avatar_url`, `reputation_score`) |

---

## Tests

```bash
cd backend
pytest -v                     # Tous les tests
pytest tests/test_auth.py -v  # Tests d'un fichier
pytest -k "matching" -v       # Filtrer par nom
```

| Fichier | Tests couverts |
|---------|---------------|
| `test_auth.py` | Inscription, lookup téléphone, génération/vérification JWT |
| `test_declarations.py` | Création, lecture, pagination cursor, règle F-15 |
| `test_matching.py` | Jaro-Winkler, distance Haversine, `compute_score` |
| `test_restitution.py` | Idempotence, contrôle d'autorisation, rating, réputation |

---

## Roadmap Sprints

| Sprint | Objectif | Statut |
|--------|----------|--------|
| **S0** | Monorepo, Docker Compose, squelette FastAPI | ✅ Terminé |
| **S1** | Auth JWT (inscription, connexion, refresh, logout) | ✅ Terminé |
| **S2** | Déclarations (CRUD + photos + pagination cursor) | ✅ Terminé |
| **S3** | Matching automatique (Jaro-Winkler + Haversine) + notifications Redis | ✅ Terminé |
| **S4** | Restitutions + messagerie WebSocket + profil utilisateur | ✅ Terminé |
| **S5** | Mobile Flutter — Auth + Déclarations + profil | ✅ Terminé |
| **S6** | Mobile Flutter — Matches + Restitutions (Commits E & F) | ✅ Terminé |
| **S7** | Mobile Flutter — Messagerie temps réel (WebSocket) | 🔄 Prochain |
| **S8** | Tests Flutter (widget tests + integration tests) | ⏳ À venir |
| **S9** | CI/CD (GitHub Actions) + déploiement production | ⏳ À venir |
