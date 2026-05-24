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
5. [Architecture mobile Flutter](#architecture-mobile-flutter)
6. [Migrations Alembic](#migrations-alembic)
7. [Tests](#tests)
8. [Roadmap Sprints](#roadmap-sprints)
9. [Couverture CDC](#couverture-cdc)

---

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter 3.x (Dart) — Riverpod + GoRouter + Dio + Hive |
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
│   │   │   ├── router.py
│   │   │   └── endpoints/
│   │   │       ├── auth.py              # S1 — Inscription, connexion, refresh
│   │   │       ├── declarations.py      # S2 — CRUD déclarations
│   │   │       ├── matches.py           # S3 — Matching + notifications
│   │   │       ├── restitutions.py      # S3 — Restitution + photos + notation
│   │   │       ├── messaging.py         # S4 — Messagerie WebSocket
│   │   │       ├── profile.py           # S4 — Profil utilisateur
│   │   │       └── admin.py             # Backoffice complet F-40–F-44
│   │   ├── models/
│   │   │   ├── user.py
│   │   │   ├── declaration.py
│   │   │   ├── match.py
│   │   │   ├── restitution.py
│   │   │   ├── message.py
│   │   │   ├── zone.py
│   │   │   └── audit_log.py
│   │   ├── schemas/
│   │   ├── services/
│   │   │   ├── matching_service.py      # Jaro-Winkler + Haversine
│   │   │   ├── restitution_service.py
│   │   │   ├── notification_service.py
│   │   │   └── storage_service.py
│   │   └── main.py
│   ├── migrations/versions/
│   │   ├── 001_initial_schema.py
│   │   ├── 002_fcm_token.py
│   │   ├── 003_user_profile.py
│   │   ├── 004_admin_zones.py
│   │   └── 005_audit_logs.py
│   ├── tests/
│   │   ├── conftest.py
│   │   ├── test_auth.py
│   │   ├── test_declarations.py
│   │   ├── test_matching.py
│   │   ├── test_restitution.py
│   │   └── test_admin.py
│   ├── pytest.ini
│   └── requirements.txt
│
├── mobile/
│   ├── pubspec.yaml                     # Riverpod, GoRouter, Dio, Freezed, Hive
│   └── lib/
│       ├── main.dart                    # Entrypoint — ProviderScope + Hive init
│       ├── core/
│       │   ├── api/
│       │   │   └── api_client.dart      # Dio + AuthInterceptor JWT auto-refresh
│       │   ├── storage/
│       │   │   ├── auth_storage.dart    # FlutterSecureStorage (tokens)
│       │   │   └── hive_storage.dart    # Hive boxes (cache + drafts)
│       │   ├── router/
│       │   │   └── app_router.dart      # GoRouter + guard auth + ShellRoute
│       │   └── theme/
│       │       └── app_theme.dart       # ThemeData light/dark (vert ReTurn)
│       └── features/
│           ├── splash/
│           │   └── splash_page.dart     # Splash animée → redirect auth
│           ├── auth/
│           │   ├── models/auth_models.dart
│           │   ├── repositories/auth_repository.dart
│           │   ├── providers/auth_notifier.dart
│           │   └── pages/
│           │       ├── login_page.dart
│           │       └── register_page.dart
│           ├── home/
│           │   └── home_shell.dart      # NavigationBar bottom (4 onglets)
│           ├── declarations/
│           │   ├── models/declaration.dart
│           │   ├── repositories/declarations_repository.dart
│           │   ├── providers/declarations_provider.dart
│           │   ├── widgets/declaration_card.dart
│           │   └── pages/
│           │       ├── declarations_list_page.dart
│           │       ├── declaration_form_page.dart
│           │       └── declaration_detail_page.dart
│           ├── matches/
│           │   ├── models/match_model.dart
│           │   ├── repositories/matches_repository.dart
│           │   ├── providers/matches_provider.dart
│           │   └── pages/
│           │       ├── matches_list_page.dart  # Score circulaire animé
│           │       └── match_detail_page.dart  # Confirmer / Rejeter
│           ├── messaging/
│           │   ├── models/message.dart         # Conversation + ChatMessage
│           │   ├── repositories/messaging_repository.dart
│           │   └── pages/
│           │       ├── conversations_page.dart  # Liste + badge unread
│           │       └── chat_page.dart           # Bulles + envoi + scroll auto
│           ├── profile/
│           │   ├── models/user_profile.dart
│           │   ├── repositories/profile_repository.dart
│           │   └── pages/profile_page.dart      # Stats + réputation + logout
│           ├── restitution/
│           │   ├── models/restitution.dart
│           │   ├── repositories/restitution_repository.dart
│           │   └── pages/restitution_page.dart  # Code + confirmation + notation
│           └── settings/
│               └── pages/settings_page.dart    # Compte, notifs, langue
│
├── infra/
│   ├── docker-compose.yml
│   ├── nginx/
│   └── .env.example
└── docs/
    └── CDC_Complet.docx
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

> **Note :** Placer les polices Satoshi dans `mobile/assets/fonts/` avant `flutter run`.
> Téléchargement : <https://api.fontshare.com/v2/css?f[]=satoshi@400,500,700,900&display=swap>

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
| `GET` | `/api/v1/users/me` | Profil connecté |
| `PATCH` | `/api/v1/users/me` | Mise à jour |
| `POST` | `/api/v1/users/me/photo` | Upload photo |
| `POST` | `/api/v1/users/fcm-token` | Token FCM notifications |

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
| `PATCH` | `/api/v1/matches/{id}/confirm` | Confirmer |
| `PATCH` | `/api/v1/matches/{id}/reject` | Rejeter |

### Restitutions

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/restitutions` | Créer (génère code confirmation) |
| `GET` | `/api/v1/restitutions/{id}` | Détail |
| `POST` | `/api/v1/restitutions/{id}/confirm` | Confirmer avec code |
| `POST` | `/api/v1/restitutions/{id}/rate` | Notation 1–5 ⭐ |

### Messagerie

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/messages/conversations` | Liste des conversations |
| `GET` | `/api/v1/messages/{room_id}/history` | Historique messages |
| `POST` | `/api/v1/messages/{room_id}` | Envoyer un message |
| `WS` | `/api/v1/ws/chat/{room_id}` | WebSocket temps réel |

### Admin (protégé `is_admin=True`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/admin/stats` | KPIs globaux (F-42) |
| `GET` | `/api/v1/admin/stats/chart` | Séries temporelles graphiques |
| `GET` | `/api/v1/admin/export/declarations` | Export CSV (F-41) |
| `GET` | `/api/v1/admin/users` | Liste paginée utilisateurs |
| `PATCH` | `/api/v1/admin/users/{id}/ban` | Bannir un compte |
| `PATCH` | `/api/v1/admin/users/{id}/unban` | Rétablir un compte |
| `PATCH` | `/api/v1/admin/users/{id}/promote` | Promouvoir en admin |
| `GET` | `/api/v1/admin/declarations` | Toutes les déclarations |
| `DELETE` | `/api/v1/admin/declarations/{id}` | Supprimer (modération) |
| `PATCH` | `/api/v1/admin/declarations/{id}/flag` | Marquer suspect |
| `POST` | `/api/v1/admin/declarations/bulk` | Import CSV en lot (F-41) |
| `GET` | `/api/v1/admin/matches` | Tous les matchs (F-40) |
| `GET` | `/api/v1/admin/restitutions` | Toutes les restitutions |
| `GET/POST` | `/api/v1/admin/zones` | Zones de récupération (F-32, F-43) |
| `PATCH/DELETE` | `/api/v1/admin/zones/{id}` | Modifier / Supprimer une zone |
| `GET` | `/api/v1/admin/audit-logs` | Historique actions admin |

---

## Architecture mobile Flutter

### Pattern — Clean Architecture par feature

Chaque feature suit la structure :
```
feature/
├── models/         ← Entités Dart (fromJson)
├── repositories/   ← Appels API via Dio
├── providers/      ← Riverpod (FutureProvider, StateNotifier)
├── pages/          ← Écrans (ConsumerWidget)
└── widgets/        ← Composants réutilisables
```

### Navigation (GoRouter) — ShellRoute avec NavigationBar

| Route | Page | Description |
|-------|------|-------------|
| `/splash` | `SplashPage` | Vérification auth → redirect |
| `/login` | `LoginPage` | Connexion téléphone + mdp |
| `/register` | `RegisterPage` | Inscription nom/prénom/téléphone |
| `/declarations` | `DeclarationsListPage` | Liste + FAB nouvelle déclaration |
| `/declarations/new` | `DeclarationFormPage` | Formulaire type/document/lieu |
| `/declarations/:id` | `DeclarationDetailPage` | Détail complet |
| `/matches` | `MatchesListPage` | Matchs + score circulaire |
| `/matches/:id` | `MatchDetailPage` | Confirmer / Rejeter / Chat |
| `/messages` | `ConversationsPage` | Liste conversations + unread |
| `/messages/:roomId` | `ChatPage` | Bulles de chat + envoi |
| `/profile` | `ProfilePage` | Stats + réputation + logout |
| `/settings` | `SettingsPage` | Compte, notifs, langue |
| `/restitution/:matchId` | `RestitutionPage` | Code + confirmation + notation |

### Flux principal

```
Splash ──▶ Login / Register
              │
              ▼
      NavigationBar (4 onglets)
      ├── Déclarations ──▶ Nouvelle / Détail
      ├── Matchs ──▶ Détail ──▶ Confirmer ──▶ Restitution
      ├── Messages ──▶ Chat temps réel
      └── Profil ──▶ Settings
```

---

## Migrations Alembic

```bash
alembic upgrade head
alembic downgrade -1
alembic revision --autogenerate -m "description"
```

| Révision | Description |
|----------|-------------|
| `001` | Schéma initial (users, declarations, matches, messages, restitutions) |
| `002` | Colonne `fcm_token` sur users |
| `003` | Colonnes profil (date_of_birth, city, gender, avatar_url…) |
| `004` | `is_admin`, `is_banned`, `is_flagged`, table `zones_recuperation` |
| `005` | Table `audit_logs` — traçabilité CDC §11.1 |

---

## Tests

```bash
cd backend && pytest -v
```

| Fichier | Couverture |
|---------|------------|
| `test_auth.py` | Inscription, JWT, token invalide |
| `test_declarations.py` | CRUD, pagination cursor, F-15 offline |
| `test_matching.py` | Jaro-Winkler, Haversine, compute_score |
| `test_restitution.py` | Idempotence, rating, réputation, autorisation |
| `test_admin.py` | Stats, chart, ban/unban/promote, flag, delete, zones, audit-logs, CSV bulk |

---

## Roadmap Sprints

| Sprint | Objectif | Statut |
|--------|----------|--------|
| **S0** | Monorepo, Docker, squelette FastAPI | ✅ |
| **S1** | Auth JWT (OTP, refresh, logout) | ✅ |
| **S2** | Déclarations (CRUD + photos + pagination) | ✅ |
| **S3** | Matching automatique + notifications Redis | ✅ |
| **S4** | Restitutions + messagerie WebSocket + profil | ✅ |
| **S5** | Mobile — Core (theme, router, api_client, storages) | ✅ |
| **S6** | Mobile — Auth + Déclarations + Profil | ✅ |
| **S7** | Mobile — Matchs + Restitution + Chat + Settings | ✅ |
| **S8** | Admin backend complet + tests | ✅ |
| **S9** | OCR Flutter (Google ML Kit) + vérification selfie | ⏳ Prochain |
| **S10** | CI/CD GitHub Actions + déploiement VPS Hetzner | ⏳ À venir |
| **S11** | Module freemium + Mobile Money (MTN MoMo / Orange) | ⏳ À venir |

---

## Couverture CDC

| ID | Fonctionnalité | Statut |
|----|---------------|--------|
| F-01 | Inscription OTP SMS | ✅ |
| F-02 | Profil utilisateur + photo | ✅ |
| F-04 | Suppression compte CPDP | ✅ |
| F-05 | Score de réputation | ✅ |
| F-10 | Déclaration trouvé + photo | ✅ |
| F-11 | OCR on-device (Google ML Kit Flutter) | ⏳ S9 |
| F-12 | Masquage données sensibles | ⏳ S9 |
| F-13 | Déclaration de perte manuelle | ✅ |
| F-14 | Géolocalisation (PostGIS) | ✅ |
| F-15 | Offline cache (Hive Flutter) | ✅ |
| F-20 | Algorithme matching Jaro-Winkler + Haversine | ✅ |
| F-21 | Notification push FCM / ntfy.sh | ✅ |
| F-23 | File matching asynchrone Redis | ✅ |
| F-30 | Vérification identité selfie + questions | ⏳ S9 |
| F-31 | Messagerie interne chiffrée WebSocket | ✅ |
| F-32 | Zones de récupération certifiées | ✅ |
| F-33 | Confirmation double restitution + code | ✅ |
| F-35 | Historique restitutions | ✅ |
| F-40 | Dashboard admin + matchs + restitutions | ✅ |
| F-41 | Export CSV + Import CSV en lot | ✅ |
| F-42 | Analytics KPIs + séries temporelles | ✅ |
| F-43 | Badge Point de dépôt certifié | ✅ |
| F-44 | API institutionnelle (REST documentée) | ✅ |
| §11.1 | Audit logs toutes actions sensibles | ✅ |
