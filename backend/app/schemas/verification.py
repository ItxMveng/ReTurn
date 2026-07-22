import uuid
from datetime import date, datetime

from pydantic import BaseModel


class VerificationRead(BaseModel):
    id: uuid.UUID
    match_id: uuid.UUID
    user_id: uuid.UUID
    selfie_url: str | None
    doc_photo_url: str | None = None
    status: str
    verification_level: int = 1
    questions_passed: bool = False
    rejection_reason: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ControlAnswers(BaseModel):
    """Réponses aux questions de contrôle (preuve de propriété).

    Le nom + la date de naissance sont la base ; le numéro de document
    n'est exigé qu'au niveau 3 (vérification renforcée).
    """

    full_name: str | None = None
    date_of_birth: date | None = None
    document_number: str | None = None
