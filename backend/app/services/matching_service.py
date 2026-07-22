"""Matching service — weighted multi-criteria algorithm.

Score breakdown (max 1.0):
  - Document number exact match : 0.35 (hard gate if both provided)
  - Owner name Jaro-Winkler      : 0.35
  - Geographic proximity         : 0.20  (haversine, 50 km = full score)
  - Temporal coherence           : 0.10  (found_date >= lost_date)

Minimum score to create a Match: 0.45
"""
import math
import uuid
from datetime import date

import jellyfish
from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.declaration import Declaration
from app.models.match import Match
from app.models.user import User
from app.services import config_service
from app.services.notification_service import push_match_notification

# Valeurs par défaut — surchargées dynamiquement par la table app_config.
MIN_SCORE = 0.45
_GEO_MAX_KM = 50.0  # distance beyond which geo score = 0


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Return the great-circle distance in kilometres between two coordinates."""
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _name_score(name_a: str | None, name_b: str | None) -> float:
    """Jaro-Winkler similarity between two names, normalised to [0, 1]."""
    if not name_a or not name_b:
        return 0.0
    a = name_a.upper().strip()
    b = name_b.upper().strip()
    return jellyfish.jaro_winkler_similarity(a, b)


def _geo_score(d: Declaration, c: Declaration, geo_max_km: float = _GEO_MAX_KM) -> float:
    """Geographic proximity score in [0, 1]. Returns 0 if coords are missing."""
    if None in (d.latitude, d.longitude, c.latitude, c.longitude):
        return 0.0
    km = _haversine_km(d.latitude, d.longitude, c.latitude, c.longitude)
    # Linear decay: 0 km -> 1.0, GEO_MAX_KM -> 0.0
    return max(0.0, 1.0 - km / geo_max_km)


def _temporal_score(found: Declaration, lost: Declaration) -> float:
    """Return 1.0 if found_date >= lost_date (coherent), else 0.0."""
    fd: date | None = found.event_date
    ld: date | None = lost.event_date
    if fd is None or ld is None:
        return 0.5  # neutral when data is missing
    return 1.0 if fd >= ld else 0.0


def _compute_score(
    new: Declaration,
    candidate: Declaration,
    geo_max_km: float = _GEO_MAX_KM,
) -> float:
    """
    Weighted multi-criteria score.
    Returns 0.0 immediately when a hard gate fails.
    """
    # Determine which declaration is found/lost for temporal check
    if new.declaration_type == "found":
        decl_found, decl_lost = new, candidate
    else:
        decl_found, decl_lost = candidate, new

    # -- (1) Document number: hard gate + 0.35 weight ----------------------
    doc_num_score = 0.0
    if new.document_number and candidate.document_number:
        n1 = new.document_number.upper().strip()
        n2 = candidate.document_number.upper().strip()
        if n1 != n2:
            return 0.0  # hard disqualification
        doc_num_score = 1.0
    # If only one side has a document number, give partial credit
    elif new.document_number or candidate.document_number:
        doc_num_score = 0.3

    # -- (2) Owner name: Jaro-Winkler, 0.35 weight -------------------------
    name_sim = _name_score(new.owner_name, candidate.owner_name)

    # -- (3) Geographic proximity: haversine, 0.20 weight ------------------
    geo_sim = _geo_score(new, candidate, geo_max_km)

    # -- (4) Temporal coherence: 0.10 weight --------------------------------
    temporal_sim = _temporal_score(decl_found, decl_lost)

    score = (
        doc_num_score * 0.35
        + name_sim * 0.35
        + geo_sim * 0.20
        + temporal_sim * 0.10
    )
    return round(score, 4)


async def _match_already_exists(
    db: AsyncSession,
    found_id: uuid.UUID,
    lost_id: uuid.UUID,
) -> bool:
    result = await db.execute(
        select(Match).where(
            Match.declaration_found_id == found_id,
            Match.declaration_lost_id == lost_id,
        )
    )
    return result.scalar_one_or_none() is not None


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

async def run_matching(
    db: AsyncSession,
    redis: Redis,
    new_declaration: Declaration,
) -> list[Match]:
    """Find matching candidates and create Match rows for high-confidence pairs."""
    opposite_type = "lost" if new_declaration.declaration_type == "found" else "found"

    result = await db.execute(
        select(Declaration).where(
            Declaration.declaration_type == opposite_type,
            Declaration.document_type == new_declaration.document_type,
            Declaration.status == "active",
            Declaration.user_id != new_declaration.user_id,
        )
    )
    candidates = list(result.scalars().all())

    config = await config_service.get_config(db)
    min_score = config["min_score"]
    geo_max_km = config["geo_max_km"]

    created_matches: list[Match] = []

    # Meilleur candidat d'abord : dès qu'un match est créé, les déclarations
    # passent à "matched" et ne doivent plus générer de matchs redondants.
    scored = sorted(
        (
            (_compute_score(new_declaration, c, geo_max_km), c)
            for c in candidates
        ),
        key=lambda pair: pair[0],
        reverse=True,
    )

    for score, candidate in scored:
        if score < min_score:
            continue
        # Une déclaration déjà matchée dans cette boucle ne doit pas
        # produire un second match.
        if new_declaration.status != "active" or candidate.status != "active":
            continue

        found_id = (
            new_declaration.id
            if new_declaration.declaration_type == "found"
            else candidate.id
        )
        lost_id = (
            new_declaration.id
            if new_declaration.declaration_type == "lost"
            else candidate.id
        )

        if await _match_already_exists(db, found_id, lost_id):
            continue

        user_found_id = (
            new_declaration.user_id
            if new_declaration.declaration_type == "found"
            else candidate.user_id
        )
        user_lost_id = (
            new_declaration.user_id
            if new_declaration.declaration_type == "lost"
            else candidate.user_id
        )

        match = Match(
            declaration_found_id=found_id,
            declaration_lost_id=lost_id,
            user_found_id=user_found_id,
            user_lost_id=user_lost_id,
            score=score,
        )
        db.add(match)
        await db.flush()

        # Les déclarations impliquées quittent l'état "active" : cela évite
        # les matchs redondants et garde un état cohérent (FIX matching).
        decl_found = new_declaration if new_declaration.id == found_id else candidate
        decl_lost = new_declaration if new_declaration.id == lost_id else candidate
        decl_found.status = "matched"
        decl_lost.status = "matched"
        db.add(decl_found)
        db.add(decl_lost)
        await db.flush()

        res_found = await db.execute(select(User).where(User.id == user_found_id))
        user_found = res_found.scalar_one_or_none()
        res_lost = await db.execute(select(User).where(User.id == user_lost_id))
        user_lost = res_lost.scalar_one_or_none()

        await push_match_notification(
            redis, user_found_id, match.id, score, new_declaration.document_type,
            fcm_token=user_found.fcm_token if user_found else None,
        )
        await push_match_notification(
            redis, user_lost_id, match.id, score, new_declaration.document_type,
            fcm_token=user_lost.fcm_token if user_lost else None,
        )

        created_matches.append(match)

    return created_matches


async def release_declarations(db: AsyncSession, match: Match) -> None:
    """Rollback d'un match ignoré/fermé : remet les déclarations à "active"
    si aucun autre match encore ouvert (pending/confirmed) ne les référence."""
    for decl_id in (match.declaration_found_id, match.declaration_lost_id):
        other_active = (
            await db.execute(
                select(Match).where(
                    Match.id != match.id,
                    Match.status.in_(("pending", "confirmed")),
                    (Match.declaration_found_id == decl_id)
                    | (Match.declaration_lost_id == decl_id),
                )
            )
        ).scalars().first()
        if other_active is not None:
            continue
        decl = (
            await db.execute(select(Declaration).where(Declaration.id == decl_id))
        ).scalar_one_or_none()
        if decl is not None and decl.status == "matched":
            decl.status = "active"
            db.add(decl)
    await db.flush()
