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
9. [Couverture CDC](#couverture-cdc)

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
│   │   ├── api/v1/
│   │   │   ├── router.py                # Enregistrement de tous les routers
│   │   │   └── endpoints/
│   │   │       ├── auth.py              # S1 — Inscription, connexion, refresh
│   │   │       ├── declarations.py      # S2 — CRUD déclarations
│   │   │       ├── matches.py           # S3 — Matching + notifications
│   │   │       ├── restitutions.py      # S3 — Restitution + photos + notation
│   │   │       ├── messaging.py         # S4 — Messagerie WebSocket
│   │   │       ├── profile.py           # S4 — Profil utilisateur
│   │   │       └── admin.py             # ✅ Commit G — Backoffice F-40–F-44
│   │   ├── models/
│   │   │   ├── user.py
│   │   │   ├── declaration.py
│   │   │   ├── match.py
│   │   │   ├── restitution.py
│   │   │   ├── message.py
│   │   │   └── zone.py                  # ✅ Commit G — Zones de récupération
│   │   ├── schemas/
│   │   ├── services/
│   │   │   ├── matching_service.py
│   │   │   ├── restitution_service.py
│   │   │   ├── notification_service.py
│   │   │   └── storage_service.py
│   │   └── main.py
│   ├── migrations/versions/
│   │   ├── 001_initial_schema.py
│   │   ├── 002_fcm_token.py
│   │   ├── 003_user_profile.py
│   │   └── 004_admin_zones.py           # ✅ Commit G
│   ├── tests/
│   │   ├── conftest.py
│   │   ├── test_auth.py
│   │   ├── test_declarations.py
│   │   ├── test_matching.py
│   │   └── test_restitution.py
│   ├── pytest.ini
│   └── requirements.txt
├── mobile/lib/
│   ├── core/
│   │   ├── network/api_client.dart
│   │   ├── router/
│   │   │   ├── app_router.dart          # ✅ Messagerie branchée
│   │   │   └── route_names.dart
│   │   └── widgets/scaffold_with_nav_bar.dart
│   └── features/
│       ├── auth/ — declarations/ — matches/ — profile/ — home/
│       └── messaging/                    # ✅ Commit G
│           ├── data/
│           │   ├── models/message_model.dart
│           │   └── repositories/messaging_repository.dart
│           ├── application/conversation_notifier.dart
│           └── presentation/pages/
│               ├── messaging_list_page.dart
│               └── conversation_page.dart
├── infra/
└── docs/
```

---

## Démarrage rapide

### Backend

```bash
cd infra && cp .env.example .env
docker compose up -d
cd ../backend
pip install -r requirements.txt
alembic upgrade head
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

### Tests

```bash
cd backend && pytest -v
```

---

## API Backend

### Authentification

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/auth/register` | Inscription (téléphone + OTP) |
| `POST` | `/api/v1/auth/login` | Connexion → JWT |
| `POST` | `/api/v1/auth/refresh` | Renouveler l'access token |
| `POST` | `/api/v1/auth/logout` | Révoquer le refresh token |

### Profil

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/profile/me` | Profil connecté |
| `PATCH` | `/api/v1/profile/me` | Mise à jour |
| `POST` | `/api/v1/profile/me/photo` | Upload photo |
| `POST` | `/api/v1/profile/fcm-token` | Token FCM |

### Déclarations

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/declarations/` | Lister (cursor pagination) |
| `POST` | `/api/v1/declarations/` | Créer |
| `GET/PATCH/DELETE` | `/api/v1/declarations/{id}` | CRUD |
| `POST` | `/api/v1/declarations/{id}/photos` | Upload photo |

### Matchs

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/matches/` | Mes matchs |
| `GET` | `/api/v1/matches/{id}` | Détail |
| `POST` | `/api/v1/matches/{id}/action` | Confirmer / ignorer |
| `GET/DELETE` | `/api/v1/matches/notifications` | Notifications |

### Restitutions

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET/PATCH` | `/api/v1/restitutions/{id}` | Détail / mise à jour |
| `POST` | `/api/v1/restitutions/{id}/photos` | Photo de preuve |
| `POST` | `/api/v1/restitutions/{id}/rate` | Notation 1–5 ⭐ |

### Messagerie

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/messaging/{match_id}` | Historique |
| `POST` | `/api/v1/messaging/{match_id}` | Envoyer |
| `WS` | `/api/v1/ws/chat/{match_id}` | WebSocket temps réel |

### Admin (protégé is_admin=True)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/admin/stats` | Statistiques globales (F-42) |
| `GET` | `/api/v1/admin/export/declarations` | Export CSV (F-41) |
| `GET` | `/api/v1/admin/users` | Liste paginiée utilisateurs |
| `PATCH` | `/api/v1/admin/users/{id}/ban` | Bannir un compte |
| `PATCH` | `/api/v1/admin/users/{id}/unban` | Rétablir un compte |
| `PATCH` | `/api/v1/admin/users/{id}/promote` | Promouvoir en admin |
| `GET` | `/api/v1/admin/declarations` | Toutes les déclarations |
| `DELETE` | `/api/v1/admin/declarations/{id}` | Supprimer (modération) |
| `PATCH` | `/api/v1/admin/declarations/{id}/flag` | Marquer suspect |
| `GET/POST` | `/api/v1/admin/zones` | Zones de récupération (F-32, F-43) |
| `DELETE` | `/api/v1/admin/zones/{id}` | Supprimer une zone |

---

## Architecture mobile (Flutter)

### Navigation (Go Router) — 14 routes

| Route | Nom | Page |
|-------|-----|------|
| `/splash` | `splash` | Vérification auth |
| `/login` | `login` | Connexion |
| `/register` | `register` | Inscription |
| `/otp-verify` | `otp-verify` | Vérification OTP |
| `/home` | `home` | Dashboard |
| `/declarations` | `declarations` | Liste |
| `/declarations/new` | `new-declaration` | Formulaire |
| `/declarations/:id` | `declaration-detail` | Détail |
| `/matches` | `matches` | 3 onglets |
| `/matches/:id` | `match-detail` | Détail + actions |
| `/restitutions/:id` | `restitution-detail` | Restitution + notation |
| `/messaging` | `messaging` | Liste conversations ✅ G |
| `/messaging/:matchId` | `conversation` | Chat WebSocket ✅ G |
| `/profile` | `profile` | Profil |
| `/profile/edit` | `edit-profile` | Modifier |

---

## Migrations Alembic

```bash
alembic upgrade head
alembic downgrade -1
alembic revision --autogenerate -m "description"
```

| Révision | Description |
|----------|-------------|
| `001` | Schéma initial |
| `002` | Colonne `fcm_token` |
| `003` | Colonnes profil |
| `004` | `is_admin`, `is_banned`, `is_flagged`, table `zones_recuperation` ✅ G |

---

## Tests

```bash
cd backend && pytest -v
```

| Fichier | Couverture |
|---------|------------|
| `test_auth.py` | Inscription, JWT |
| `test_declarations.py` | CRUD, pagination, F-15 |
| `test_matching.py` | Jaro-Winkler, Haversine |
| `test_restitution.py` | Idempotence, rating, réputation |

---

## Roadmap Sprints

| Sprint | Objectif | Statut |
|--------|----------|--------|
| **S0** | Monorepo, Docker, squelette FastAPI | ✅ |
| **S1** | Auth JWT (OTP, refresh, logout) | ✅ |
| **S2** | Déclarations (CRUD + photos + pagination) | ✅ |
| **S3** | Matching automatique + notifications Redis | ✅ |
| **S4** | Restitutions + messagerie WebSocket + profil | ✅ |
| **S5** | Mobile — Auth + Déclarations + Profil | ✅ |
| **S6** | Mobile — Matches + Restitutions | ✅ |
| **S7** | Mobile — Messagerie WebSocket + Admin backend | ✅ |
| **S8** | Tests Flutter + widget tests | ⏳ Prochain |
| **S9** | CI/CD GitHub Actions + déploiement VPS | ⏳ À venir |

---

## Couverture CDC

| ID | Fonctionnalité | Statut |
|----|---------------|--------|
| F-01 | Inscription OTP SMS | ✅ |
| F-02 | Profil utilisateur + photo | ✅ |
| F-04 | Suppression compte CPDP | ✅ |
| F-05 | Score de réputation | ✅ |
| F-10 | Déclaration trouvé + photo | ✅ |
| F-11 | OCR (on-device Flutter) | ⏳ S8 |
| F-13 | Déclaration de perte manuelle | ✅ |
| F-14 | Géolocalisation | ✅ |
| F-15 | Offline cache | ✅ |
| F-20 | Algorithme matching Jaro-Winkler + Haversine | ✅ |
| F-21 | Notification push FCM | ✅ |
| F-23 | File matching asynchrone Redis | ✅ |
| F-30 | Vérification identité (selfie) | ⏳ S8 |
| F-31 | Messagerie chiffrée | ✅ |
| F-32 | Zones de récupération certifiées | ✅ |
| F-33 | Confirmation double restitution | ✅ |
| F-35 | Historique restitutions | ✅ |
| F-40 | Dashboard admin institution | ✅ |
| F-41 | Export CSV déclarations | ✅ |
| F-42 | Analytics + reporting | ✅ |
| F-43 | Badge point de dépôt certifié | ✅ |
| F-44 | API institutionnelle | ✅ |
