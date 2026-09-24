"""Service d'extraction OCR/IA via Mistral Vision.

La clé API reste côté serveur (settings.MISTRAL_API_KEY) : elle n'est jamais
embarquée dans l'APK mobile. L'app envoie l'image à POST /api/v1/ocr/extract et
reçoit des champs structurés.

Le modèle Vision (pixtral) lit aussi bien les documents imprimés (CNI, passeport,
visa, permis) que les actes manuscrits — d'où un net gain de qualité par rapport
à l'OCR on-device (ML Kit) qui échoue sur l'écriture manuscrite.
"""
import base64
import json
import logging

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

_ENDPOINT = "https://api.mistral.ai/v1/chat/completions"
_VISION_MODEL = "pixtral-12b-2409"

_PROMPT = """Tu es un expert en lecture de documents d'identité et d'état civil \
de n'importe quel pays (ex. Cameroun, France, autres), rédigés dans n'importe \
quelle langue : carte nationale d'identité, passeport, visa, titre de séjour, \
permis de conduire, acte de naissance manuscrit ou imprimé, carte grise, \
diplôme.

Analyse l'image et extrais les informations de la PERSONNE TITULAIRE du document.

Règles importantes :
- Lis attentivement même l'écriture manuscrite et les caractères peu nets.
- N'invente jamais une valeur : mets null si l'information est absente ou illisible.
- "nom" = nom de famille / surname uniquement (en MAJUSCULES).
- "prenom" = prénom(s) / given names uniquement, sans le nom de famille.
- Ne confonds JAMAIS un libellé du formulaire (ex: "RÉPUBLIQUE", "NOM", \
"PRÉNOMS", "CARTE NATIONALE", "SURNAME", "ARRONDISSEMENT") avec une valeur.
- "numero" = numéro du document (sans espaces). Pour un passeport c'est le \
numéro type AA123456 ; pour une CNI le long numéro d'identification.
- Pour un passeport, utilise la zone MRZ (lignes en bas avec des <) si présente.
- Dates au format JJ/MM/AAAA, quelle que soit la convention d'écriture du pays \
émetteur (convertis-les si besoin ; mets null si l'ordre jour/mois est ambigu).

Réponds UNIQUEMENT avec un objet JSON valide, sans aucun texte autour :
{
  "nom": string|null,
  "prenom": string|null,
  "numero": string|null,
  "date_naissance": "JJ/MM/AAAA"|null,
  "date_expiration": "JJ/MM/AAAA"|null,
  "lieu_naissance": string|null,
  "type_document": "CNI"|"PASSEPORT"|"VISA"|"PERMIS"|"ACTE_NAISSANCE"|"CARTE_GRISE"|"DIPLOME"|"INCONNU"
}"""


class OcrUnavailable(Exception):
    """Levée quand la clé Mistral n'est pas configurée côté serveur."""


def is_available() -> bool:
    return bool(_clean_key())


def _clean_key() -> str:
    # Tolère un préfixe "sk-" collé par erreur (les clés Mistral n'en ont pas).
    key = (settings.MISTRAL_API_KEY or "").strip()
    if key.lower().startswith("sk-"):
        key = key[3:]
    return key


async def extract_fields(image_bytes: bytes, content_type: str) -> dict:
    """Envoie l'image à Mistral Vision et retourne les champs structurés.

    Retourne un dict {nom, prenom, numero, date_naissance, date_expiration,
    lieu_naissance, type_document, used_ai, raw_text}. Ne lève jamais sur une
    erreur réseau/IA : retourne des champs vides avec used_ai=False pour que
    l'utilisateur puisse saisir manuellement.
    """
    if not is_available():
        raise OcrUnavailable("Clé Mistral non configurée côté serveur.")

    mime = content_type if content_type and content_type.startswith("image/") else "image/jpeg"
    b64 = base64.b64encode(image_bytes).decode("ascii")

    body = {
        "model": _VISION_MODEL,
        "response_format": {"type": "json_object"},
        "temperature": 0,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": _PROMPT},
                    {
                        "type": "image_url",
                        "image_url": f"data:{mime};base64,{b64}",
                    },
                ],
            }
        ],
    }

    async with httpx.AsyncClient(timeout=45.0) as client:
        resp = await client.post(
            _ENDPOINT,
            json=body,
            headers={"Authorization": f"Bearer {_clean_key()}"},
        )
        resp.raise_for_status()
        data = resp.json()

    content = (
        data.get("choices", [{}])[0].get("message", {}).get("content", "")
    )
    parsed = json.loads(content)

    def _val(key: str) -> str | None:
        v = parsed.get(key)
        if v is None:
            return None
        s = str(v).strip()
        return s or None

    return {
        "nom": _val("nom"),
        "prenom": _val("prenom"),
        "numero": _val("numero"),
        "date_naissance": _val("date_naissance"),
        "date_expiration": _val("date_expiration"),
        "lieu_naissance": _val("lieu_naissance"),
        "type_document": _val("type_document"),
        "used_ai": True,
        "raw_text": None,
    }
