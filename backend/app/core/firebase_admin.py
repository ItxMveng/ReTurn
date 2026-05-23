import base64
import json
import logging

import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials

from app.core.config import settings

logger = logging.getLogger(__name__)

_app: firebase_admin.App | None = None


def init_firebase() -> None:
    global _app
    if _app is not None:
        return

    # Sécurité : le mock ne doit jamais tourner en production
    if settings.FIREBASE_MOCK_MODE and settings.ENVIRONMENT == "production":
        raise RuntimeError(
            "FIREBASE_MOCK_MODE=true est interdit en ENVIRONMENT=production."
        )

    if settings.FIREBASE_MOCK_MODE:
        logger.warning("Firebase mock mode actif — ne jamais utiliser en production.")
        return

    if not settings.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64:
        raise ValueError(
            "FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 est vide. "
            "Ajoutez le service account Firebase encodé en base64 dans infra/.env."
        )

    raw = base64.b64decode(settings.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64)
    service_account = json.loads(raw)
    cred = credentials.Certificate(service_account)
    _app = firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin SDK initialisé (projet: %s)", service_account.get("project_id"))


def verify_firebase_token(id_token: str) -> dict:
    """Vérifie un idToken Firebase et retourne le decoded token.

    En mock mode, accepte uniquement le token de test configuré.
    """
    if settings.FIREBASE_MOCK_MODE:
        # Token mock = numéro de test en clair pour les tests dev
        if id_token == f"mock_{settings.FIREBASE_MOCK_TEST_PHONE}":
            return {
                "uid": f"mock_uid_{settings.FIREBASE_MOCK_TEST_PHONE}",
                "phone_number": settings.FIREBASE_MOCK_TEST_PHONE,
            }
        raise ValueError("Token mock invalide.")

    try:
        decoded = firebase_auth.verify_id_token(id_token, app=_app)
        return decoded
    except firebase_auth.InvalidIdTokenError as e:
        logger.warning("Token Firebase invalide: %s", str(e))
        raise ValueError(f"Token Firebase invalide: {e}") from e
    except firebase_auth.ExpiredIdTokenError as e:
        logger.warning("Token Firebase expiré")
        raise ValueError("Token Firebase expiré.") from e
    except Exception as e:
        logger.error("Erreur vérification Firebase: %s", str(e))
        raise ValueError("Erreur de vérification du token Firebase.") from e
