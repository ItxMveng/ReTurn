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
│   │   │   └── router/
│   │   │       └── app_router.dart    # GoRouter complet — toutes routes
│   │   ├── features/
│   │   │   ├── auth/              # Authentification OTP + JWT
│   │   │   ├── declarations/
│   │   │   │   └── repositories/
│   │   │   │       └── declaration_repository.dart  # +getById, +searchDeclarations
│   │   │   ├── home/
│   │   │   │   └── screens/
│   │   │   │       └── home_screen.dart  # +carte Restitutions + badge compteur
│   │   │   ├── matching/
│   │   │   │   └── repositories/
│   │   │   │       └── match_repository.dart  # listMatches, actOnMatch, notifications
│   │   │   ├── messaging/          # Chat WebSocket + vérification identité
│   │   │   ├── profile/
│   │   │   │   └── repositories/
│   │   │   │       └── profile_repository.dart  # fetchProfile, updateAvatar, FCM
│   │   │   └── restitution/          # 🔵 NOUVEAU — cycle complet de restitution
│   │   │       ├── repositories/
│   │   │       │   └── restitution_repository.dart
│   │   │       ├── providers/
│   │   │       │   └── restitution_provider.dart
│   │   │       └── screens/
│   │   │           ├── restitutions_list_screen.dart
│   │   │           └── restitution_detail_screen.dart
│   │   └── shared/
│   │       ├── models/
│   │       │   ├── restitution.dart      # +isActive, +canRate, +statusLabel
│   │       │   └── user_profile.dart     # Source of truth + reputationScore
│   │       └── widgets/                  # Widgets réutilisables
│   └── pubspec.yaml
├── backend/                  # API REST FastAPI (Python 3.12)
│   ├── alembic.ini
│   ├── alembic/
│   │   ├── env.py
│   │   └── versions/
│   │       ├── 001_initial_schema.py
│   │       ├── 002_add_event_date_reputation.py
│   │       └── 003_add_restitutions_table.py
│   ├── app/
│   │   ├── api/v1/
│   │   │   ├── router.py
│   │   │   └── endpoints/
│   │   │       ├── auth.py
│   │   │       ├── declarations.py
│   │   │       ├── matches.py
│   │   │       ├── messaging.py
│   │   │       ├── profile.py
│   │   │       └── restitutions.py
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── dependencies.py
│   │   │   └── redis_client.py
│   │   ├── models/
│   │   │   ├── user.py | declaration.py | match.py
│   │   │   ├── message.py | restitution.py | verification.py
│   │   │   └── __init__.py
│   │   ├── schemas/
│   │   │   ├── auth.py | declaration.py | match.py
│   │   │   └── message.py | restitution.py | user.py | verification.py
│   │   └── services/
│   │       ├── auth_service.py | declaration_service.py | matching_service.py
│   │       └── messaging_service.py | notification_service.py | otp_service.py
│   │           restitution_service.py | storage_service.py | verification_service.py
│   ├── tests/
│   │   ├── conftest.py
│   │   ├── test_auth.py
│   │   ├── test_declarations.py
│   │   ├── test_matching.py
│   │   └── test_restitution.py
│   ├── pytest.ini
│   ├── requirements.txt
│   └── Dockerfile
├── infra/
│   ├── docker-compose.yml
│   ├── docker-compose.prod.yml
│   ├── nginx/
│   └── postgres/
└── docs/api/
```

---

## Mobile Flutter — Fonctionnalités

| Feature | Écran(s) | Statut |
|---------|----------|--------|
| Authentification OTP | `PhoneInputScreen`, `OtpVerifyScreen` | ✅ |
| Configuration profil | `ProfileSetupScreen` | ✅ |
| Accueil | `HomeScreen` (+carte Restitutions, badge) | ✅ |
| Déclarations | `DeclarationsListScreen`, `DeclarationFormScreen`, `DeclarationDetailScreen` | ✅ |
| Matching | `MatchesListScreen`, `MatchDetailScreen` | ✅ |
| Messagerie | `ChatScreen`, `IdentityVerificationScreen` | ✅ |
| Restitutions | `RestitutionsListScreen`, `RestitutionDetailScreen` | ✅ |
| Paramètres / Support | `SettingsScreen`, `SupportScreen` | ✅ |

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
| DELETE | `/` | Suppression compte (RGPD F-04) |

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
| POST | `/{id}/action` | Confirmer ou ignorer (double-confirmation, crée la restitution) |
| GET | `/notifications` | Notifications en attente |
| DELETE | `/notifications` | Vider les notifications |

### Restitutions (`/api/v1/restitutions`)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/` | Lister ses restitutions |
| GET | `/{id}` | Détail d'une restitution |
| PATCH | `/{id}` | Modifier lieu de RDV / statut |
| POST | `/{id}/photos` | Uploader une photo preuve |
| POST | `/{id}/rate` | Noter la restitution (1–5★ → met à jour score_reputation) |
| POST | `/{id}/dispute` | Signaler un litige |

### Messagerie (`/api/v1/messaging`)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/{match_id}/history` | Historique des messages |
| WS | `/ws/{match_id}` | WebSocket temps réel |
| POST | `/{match_id}/mark-read` | Marquer comme lu |

---

## Routes Flutter (GoRouter)

| Route | Écran | Auth requise |
|-------|-------|--------------|
| `/splash` | `SplashScreen` | Non |
| `/onboarding` | `OnboardingScreen` | Non |
| `/auth/phone` | `PhoneInputScreen` | Non |
| `/auth/otp` | `OtpVerifyScreen` | Non |
| `/profile/setup` | `ProfileSetupScreen` | Oui |
| `/home` | `HomeScreen` | Oui |
| `/declarations` | `DeclarationsListScreen` | Oui |
| `/declarations/new/:type` | `DeclarationFormScreen` | Oui |
| `/declarations/:id` | `DeclarationDetailScreen` | Oui |
| `/matches` | `MatchesListScreen` | Oui |
| `/matches/:id` | `MatchDetailScreen` | Oui |
| `/matches/:id/chat` | `ChatScreen` | Oui |
| `/matches/:id/verify` | `IdentityVerificationScreen` | Oui |
| `/restitutions` | `RestitutionsListScreen` | Oui |
| `/restitutions/:id` | `RestitutionDetailScreen` | Oui |
| `/settings` | `SettingsScreen` | Oui |
| `/support` | `SupportScreen` | Oui |

---

## Migrations de base de données (Alembic)

```bash
# Appliquer toutes les migrations
alembic upgrade head

# Voir l'état actuel
alembic current

# Créer une nouvelle migration
alembic revision --autogenerate -m "description"

# Rollback
alembic downgrade -1
```

| Révision | Description |
|----------|-------------|
| `001` | Schéma initial : users, declarations, matches, messages, identity_verifications |
| `002` | Ajout `event_date`, `score_reputation`, `confirmed_by_owner/finder` |
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
|---------|----------------|
| `test_auth.py` | Création utilisateur, lookup téléphone, génération JWT |
| `test_declarations.py` | Limite F-15, pagination cursor, CRUD complet |
| `test_matching.py` | Score Jaro-Winkler, Haversine, compute_score |
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
| S5 | Mobile Flutter complet (repositories, providers, screens, router) | ✅ |

---

## Licence

Propriétaire — © 2026 DocRetour. Tous droits réservés.
