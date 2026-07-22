"""Schémas pour l'extraction OCR/IA de documents d'identité."""
from pydantic import BaseModel


class OcrExtractResponse(BaseModel):
    """Champs structurés extraits d'un document par l'IA Mistral Vision."""

    nom: str | None = None
    prenom: str | None = None
    numero: str | None = None
    date_naissance: str | None = None
    date_expiration: str | None = None
    lieu_naissance: str | None = None
    type_document: str | None = None
    # true = extraction réalisée par l'IA ; false = IA indisponible (champs vides)
    used_ai: bool = False
    # Texte brut éventuellement renvoyé par l'IA (utile pour debug / fallback)
    raw_text: str | None = None
