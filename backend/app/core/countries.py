import re

_ISO_ALPHA2_RE = re.compile(r"^[A-Z]{2}$")


def normalize_country_code(value: str | None) -> str | None:
    """Normalise un code pays ISO 3166-1 alpha-2 (« cm » → « CM »).

    Retourne None pour une valeur vide ; lève ValueError si le format est invalide.
    """
    if value is None:
        return None
    code = value.strip().upper()
    if not code:
        return None
    if not _ISO_ALPHA2_RE.match(code):
        raise ValueError("Code pays invalide (ISO 3166-1 alpha-2, ex. CM, FR).")
    return code
