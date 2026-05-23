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
├── mobile/          # Application Flutter (Dart)
│   ├── lib/
│   │   ├── core/        # Config, thème, router, utils
│   │   ├── features/    # Modules métier (auth, déclarations, matching…)
│   │   └── shared/      # Widgets et modèles réutilisables
│   └── pubspec.yaml
├── backend/         # API REST FastAPI (Python 3.12)
│   ├── app/
│   │   ├── api/v1/      # Endpoints REST versionnés
│   │   ├── core/        # Config, sécurité, base de données
│   │   ├── models/      # Modèles SQLAlchemy
│   │   ├── schemas/     # Schémas Pydantic
│   │   └── services/    # Logique métier
│   └── Dockerfile
├── infra/           # Orchestration Docker
│   ├── docker-compose.yml       # Dev local
│   ├── docker-compose.prod.yml  # Production
│   ├── nginx/                   # Reverse proxy
│   └── postgres/                # Script d'init SQL
└── docs/api/        # Documentation OpenAPI exportée
```

---

## Variables d'environnement

Toutes les variables sont documentées dans `infra/.env.example`.  
Copiez ce fichier en `infra/.env` et adaptez les valeurs **avant** de lancer Docker.

> Ne commitez jamais `.env`. Il est dans le `.gitignore`.

---

## Commandes utiles

```powershell
# Voir les logs du backend en temps réel
docker compose -f infra/docker-compose.yml logs -f backend

# Accéder à la console MinIO
Start-Process http://localhost:9001

# Ouvrir la documentation interactive Swagger
Start-Process http://localhost:8000/docs

# Relancer uniquement le backend après modification
docker compose -f infra/docker-compose.yml restart backend

# Arrêter et supprimer les conteneurs (volumes conservés)
docker compose -f infra/docker-compose.yml down

# Arrêter ET supprimer les volumes (reset complet)
docker compose -f infra/docker-compose.yml down -v
```

---

## Sprints

| Sprint | Objectif |
|---|---|
| S0 | Structure monorepo, infrastructure Docker, squelette API |
| S1 | Authentification JWT (inscription, connexion, refresh) |
| S2 | Déclarations de documents (trouver / perdu) |
| S3 | Matching automatique et notifications |
| S4 | Messagerie temps réel et profil utilisateur |

---

## Licence

Propriétaire — © 2026 DocRetour. Tous droits réservés.
