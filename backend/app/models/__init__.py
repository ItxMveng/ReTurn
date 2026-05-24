"""Import all models so SQLAlchemy's metadata is fully populated at startup."""
from app.models.user import User  # noqa: F401
from app.models.declaration import Declaration  # noqa: F401
from app.models.match import Match  # noqa: F401
from app.models.message import Message  # noqa: F401
from app.models.verification import IdentityVerification  # noqa: F401
from app.models.restitution import Restitution  # noqa: F401
from app.models.zone import Zone  # noqa: F401
from app.models.audit_log import AuditLog  # noqa: F401
