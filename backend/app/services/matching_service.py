"""Matching service — weighted multi-criteria algorithm.

Poids relatifs (renormalisés sur les critères RÉELLEMENT présents) :
  - Numéro de document (match exact) : 0.45  (porte dure si les deux fournis)
  - Nom du propriétaire (tolérant)   : 0.40  (tokens + accents + noms partiels)
  - Proximité géographique           : 0.20  (haversine, 50 km = plein score)
  - Cohérence temporelle             : 0.10  (found_date >= lost_date)

Un critère absent (pas de GPS, pas de date, un seul numéro) n'est pas compté
et ne pénalise pas le score. Score minimum pour créer un Match : 0.45.
"""
import math
import unicodedata
import uuid
from datetime import date

import jellyfish
from redis.asyncio import Redis
from sqlalchemy import or_, select
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


def _normalize_name(s: str) -> str:
    """Majuscules + suppression des accents/ponctuation → comparaison robuste
    à la casse et aux variantes ('Mbárga' == 'MBARGA')."""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    # Ne garder que lettres/chiffres/espaces
    s = "".join(c if c.isalnum() or c.isspace() else " " for c in s)
    return " ".join(s.upper().split())


def _name_score(name_a: str | None, name_b: str | None) -> float:
    """Similarité de noms dans [0, 1], tolérante à la casse, aux accents et
    aux noms PARTIELS ('Jean' vs 'Jean Mbarga' → score élevé).

    On combine deux mesures et on garde la meilleure :
      - Jaro-Winkler sur la chaîne complète (ordre des mots).
      - Score par tokens : chaque mot du nom le plus court est apparié au
        meilleur mot de l'autre nom (gère prénom seul, mots manquants,
        ordre inversé).
    """
    if not name_a or not name_b:
        return 0.0
    a = _normalize_name(name_a)
    b = _normalize_name(name_b)
    if not a or not b:
        return 0.0

    full = jellyfish.jaro_winkler_similarity(a, b)

    ta = a.split()
    tb = b.split()
    if ta and tb:
        small, large = (ta, tb) if len(ta) <= len(tb) else (tb, ta)
        per_token = [
            max(jellyfish.jaro_winkler_similarity(t, u) for u in large)
            for t in small
        ]
        token_score = sum(per_token) / len(per_token)
    else:
        token_score = full

    return max(full, token_score)


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
    Score multi-critères pondéré, ROBUSTE aux signaux manquants.

    Chaque critère n'est compté que s'il est réellement disponible, et le score
    final est renormalisé sur la somme des poids présents. Ainsi un nom très
    concordant n'est pas pénalisé par l'absence de GPS ou de date — ce qui
    évitait injustement des matchs (ex : deux CNI au même nom sans coordonnées).
    Retourne 0.0 immédiatement si une porte dure échoue.
    """
    # Determine which declaration is found/lost for temporal check
    if new.declaration_type == "found":
        decl_found, decl_lost = new, candidate
    else:
        decl_found, decl_lost = candidate, new

    # (poids, score) accumulés uniquement pour les critères disponibles.
    parts: list[tuple[float, float]] = []

    # -- (1) Numéro de document : porte dure + poids fort ------------------
    if new.document_number and candidate.document_number:
        n1 = new.document_number.upper().strip()
        n2 = candidate.document_number.upper().strip()
        if n1 != n2:
            return 0.0  # disqualification dure : deux numéros différents
        parts.append((0.45, 1.0))  # match exact = très fort signal
    # Un seul côté a un numéro → signal faible, on ne pénalise pas l'absence.

    # -- (2) Nom du propriétaire : tolérant (tokens + accents) -------------
    if new.owner_name and candidate.owner_name:
        parts.append((0.40, _name_score(new.owner_name, candidate.owner_name)))

    # -- (3) Proximité géographique : seulement si coords des deux côtés ---
    if None not in (new.latitude, new.longitude,
                    candidate.latitude, candidate.longitude):
        parts.append((0.20, _geo_score(new, candidate, geo_max_km)))

    # -- (4) Cohérence temporelle : seulement si les deux dates existent ---
    if decl_found.event_date is not None and decl_lost.event_date is not None:
        parts.append((0.10, _temporal_score(decl_found, decl_lost)))

    if not parts:
        return 0.0
    total_weight = sum(w for w, _ in parts)
    score = sum(w * s for w, s in parts) / total_weight
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

    conditions = [
        Declaration.declaration_type == opposite_type,
        Declaration.document_type == new_declaration.document_type,
        Declaration.status == "active",
        Declaration.user_id != new_declaration.user_id,
    ]
    # Un document perdu à Douala ne se retrouve pas à Paris : on ne rapproche que
    # des déclarations du même pays. Pays inconnu (anciennes données) = tolérant.
    if new_declaration.country_code:
        conditions.append(
            or_(
                Declaration.country_code.is_(None),
                Declaration.country_code == new_declaration.country_code,
            )
        )

    result = await db.execute(select(Declaration).where(*conditions))
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
