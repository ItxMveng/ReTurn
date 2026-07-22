"""Vérification d'identité adaptative (F-30).

Le niveau d'exigence dépend du score de confiance du match :
  1 — Rapide    (score >= 0.75)  : nom + date de naissance → approbation auto
  2 — Standard  (0.50 - 0.74)    : + selfie → approbation auto
  3 — Renforcé  (0.45 - 0.49)    : + numéro doc + photo du document → revue admin
"""
import re
import uuid
from datetime import date, datetime, timezone

import jellyfish
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.match import Match
from app.models.user import User
from app.models.verification import IdentityVerification
from app.services import restitution_service
from app.services.storage_service import ensure_bucket, upload_photo

_NAME_SIMILARITY_MIN = 0.85  # Jaro-Winkler minimal entre deux noms/tokens


def compute_level(match_score: float) -> int:
    """Niveau de vérification exigé selon le score de confiance du match."""
    if match_score >= 0.75:
        return 1
    if match_score >= 0.50:
        return 2
    return 3


def _norm(s: str | None) -> str:
    return re.sub(r"[^a-z0-9]", "", (s or "").lower())


def _norm_name(s: str | None) -> str:
    return re.sub(r"\s+", " ", (s or "").upper().strip())


def _name_matches(decl_name: str | None, input_name: str) -> bool:
    """Comparaison TOLÉRANTE entre le nom saisi et le nom relevé sur le document.

    Le nom du document est souvent PARTIEL (saisie du trouveur, OCR incomplet) :
    on accepte donc, dans l'ordre :
      1. similarité Jaro-Winkler globale >= 0.85 ;
      2. inclusion : l'un contient l'autre (ex. « MBARGA » ⊂ « JEAN MBARGA ») ;
      3. sous-ensemble de tokens : chaque mot du nom LE PLUS COURT trouve un
         mot correspondant (JW >= 0.85 ou préfixe) dans le nom le plus long —
         « J. MBARGA » valide « Jean Claude Mbarga ».
    Si le document n'a AUCUN nom, on ne bloque pas : le selfie, la photo du
    document et la revue admin prennent le relais selon le niveau.
    """
    decl = _norm_name(decl_name)
    inp = _norm_name(input_name)
    if not decl:
        return True
    if jellyfish.jaro_winkler_similarity(decl, inp) >= _NAME_SIMILARITY_MIN:
        return True
    if decl in inp or inp in decl:
        return True

    decl_tokens = [t for t in decl.split(" ") if t]
    inp_tokens = [t for t in inp.split(" ") if t]
    short, long_ = (
        (decl_tokens, inp_tokens)
        if len(decl_tokens) <= len(inp_tokens)
        else (inp_tokens, decl_tokens)
    )

    def token_found(token: str) -> bool:
        for other in long_:
            if jellyfish.jaro_winkler_similarity(token, other) >= _NAME_SIMILARITY_MIN:
                return True
            # Initiale ou préfixe (« J. » / « JEA » valide « JEAN »)
            stripped = token.rstrip(".")
            if stripped and other.startswith(stripped):
                return True
        return False

    return bool(short) and all(token_found(t) for t in short)


class AnswersCheckResult:
    """Résultat détaillé de la vérification des réponses de contrôle."""

    def __init__(self, passed: bool, message: str | None = None):
        self.passed = passed
        self.message = message


async def check_answers(
    db: AsyncSession,
    verif: IdentityVerification,
    declaration,
    requester: User,
    full_name: str | None,
    date_of_birth: date | None,
    document_number: str | None,
) -> AnswersCheckResult:
    """Vérifie les réponses de contrôle selon le niveau exigé (anti-usurpation).

    - Nom : Jaro-Winkler >= 0.85 contre le nom porté sur le document trouvé.
    - Date de naissance : correspondance exacte avec le profil du demandeur.
    - Numéro de document (niveau 3 uniquement) : correspondance avec le
      numéro relevé sur le document, tolérance sur les 5 derniers caractères.
    """
    level = verif.verification_level

    # -- Nom (tous niveaux, comparaison TOLÉRANTE aux noms partiels) -----------
    inp_name = _norm_name(full_name)
    if not inp_name:
        return AnswersCheckResult(False, "Veuillez indiquer le nom figurant sur le document.")
    if not _name_matches(getattr(declaration, "owner_name", None), inp_name):
        return AnswersCheckResult(
            False,
            "Le nom saisi ne correspond pas à celui relevé sur le document. "
            "Écrivez-le tel qu'il figure sur le document.",
        )

    # -- Date de naissance (tous niveaux) ---------------------------------------
    if date_of_birth is None:
        return AnswersCheckResult(False, "Veuillez indiquer votre date de naissance.")
    if requester.date_of_birth is None:
        return AnswersCheckResult(
            False,
            "Complétez d'abord votre date de naissance dans votre profil pour pouvoir vérifier votre identité.",
        )
    if date_of_birth != requester.date_of_birth:
        return AnswersCheckResult(
            False,
            "La date de naissance ne correspond pas à celle de votre profil.",
        )

    # -- Numéro de document : FACULTATIF à tous les niveaux ---------------------
    # Beaucoup de propriétaires ne connaissent pas leur numéro par cœur (et
    # certains documents n'en ont pas d'exploitable, ex. acte de naissance).
    # S'il est FOURNI, il doit correspondre (preuve forte) ; sinon le selfie,
    # la photo du document et la revue admin (niveau 3) prennent le relais.
    decl_num = _norm(getattr(declaration, "document_number", None))
    inp_num = _norm(document_number)
    if inp_num and decl_num:
        if decl_num != inp_num and not (
            len(inp_num) >= 5 and inp_num[-5:] == decl_num[-5:]
        ):
            return AnswersCheckResult(
                False,
                "Le numéro saisi ne correspond pas au document. "
                "Si vous ne le connaissez pas, laissez ce champ vide.",
            )

    # -- Réponses valides : progression selon le niveau ---------------------------
    verif.questions_passed = True
    if level == 1:
        # Niveau rapide : les réponses suffisent, approbation immédiate.
        verif.status = "approved"
        await _on_approved(db, verif)
    db.add(verif)
    await db.flush()
    return AnswersCheckResult(True)


async def _on_approved(db: AsyncSession, verif: IdentityVerification) -> None:
    """Vérification approuvée = le propriétaire a prouvé son identité.

    Le match passe en « confirmé » (la vérification VAUT confirmation, il n'y
    a plus d'étape d'acceptation manuelle) et la restitution est préparée —
    c'est ce qui débloque la conversation des deux côtés.
    """
    match = (
        await db.execute(select(Match).where(Match.id == verif.match_id))
    ).scalar_one_or_none()
    if match is None:
        return
    match.accepted_by_owner = True
    match.accepted_by_finder = True
    if match.status == "pending":
        match.status = "confirmed"
    db.add(match)
    await db.flush()
    await restitution_service.create_restitution(db, match.id)


async def request_verification(
    db: AsyncSession,
    match_id: uuid.UUID,
    user_id: uuid.UUID,
    match_score: float | None = None,
) -> IdentityVerification:
    result = await db.execute(
        select(IdentityVerification).where(
            IdentityVerification.match_id == match_id,
            IdentityVerification.user_id == user_id,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        # Réaligne le niveau si le score du match est connu (sécurité).
        if match_score is not None:
            level = compute_level(match_score)
            if existing.verification_level != level and existing.status == "pending":
                existing.verification_level = level
                db.add(existing)
                await db.flush()
        return existing

    verif = IdentityVerification(
        match_id=match_id,
        user_id=user_id,
        verification_level=compute_level(match_score) if match_score is not None else 1,
    )
    db.add(verif)
    await db.flush()
    return verif


async def submit_selfie(
    db: AsyncSession,
    verif: IdentityVerification,
    selfie_bytes: bytes,
    content_type: str,
) -> IdentityVerification:
    await ensure_bucket()
    url = await upload_photo(
        selfie_bytes,
        str(verif.user_id),
        f"verif_{verif.match_id}",
        content_type,
    )
    verif.selfie_url = url
    if verif.verification_level >= 3:
        # Niveau renforcé : jamais d'auto-approbation, revue admin obligatoire.
        verif.status = "pending"
    else:
        # Niveau standard : approuvé si les questions de contrôle sont validées.
        verif.status = "approved" if verif.questions_passed else "pending"
        if verif.status == "approved":
            await _on_approved(db, verif)
    db.add(verif)
    await db.flush()
    return verif


async def submit_doc_photo(
    db: AsyncSession,
    verif: IdentityVerification,
    photo_bytes: bytes,
    content_type: str,
) -> IdentityVerification:
    """Photo du document (niveau 3) — jointe au dossier pour la revue admin."""
    await ensure_bucket()
    url = await upload_photo(
        photo_bytes,
        str(verif.user_id),
        f"verif_doc_{verif.match_id}",
        content_type,
    )
    verif.doc_photo_url = url
    db.add(verif)
    await db.flush()
    return verif


async def admin_review(
    db: AsyncSession,
    verif: IdentityVerification,
    approve: bool,
    reason: str | None = None,
) -> IdentityVerification:
    """Décision admin sur une vérification (niveau 3 ou litige)."""
    verif.status = "approved" if approve else "rejected"
    verif.rejection_reason = None if approve else (reason or "Non conforme")
    verif.reviewed_at = datetime.now(timezone.utc)
    if approve:
        await _on_approved(db, verif)
    db.add(verif)
    await db.flush()
    return verif


async def get_verification(
    db: AsyncSession,
    match_id: uuid.UUID,
    user_id: uuid.UUID,
) -> IdentityVerification | None:
    result = await db.execute(
        select(IdentityVerification).where(
            IdentityVerification.match_id == match_id,
            IdentityVerification.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()
