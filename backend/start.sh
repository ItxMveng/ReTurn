#!/usr/bin/env sh
# Démarrage production : applique les migrations puis lance le serveur.
# reconcile_schema() (au lifespan) rattrape tout écart résiduel de schéma.
set -e

echo "→ Application des migrations Alembic…"
alembic upgrade head || echo "⚠ alembic upgrade a échoué — reconcile_schema prendra le relais."

echo "→ Démarrage d'Uvicorn sur le port ${PORT:-8000}…"
exec uvicorn app.main:app \
  --host 0.0.0.0 \
  --port "${PORT:-8000}" \
  --workers 1 \
  --proxy-headers \
  --forwarded-allow-ips="*"
