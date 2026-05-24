"""
005 — Table audit_logs pour traçabilité des actions admin (CDC §11.1)

Revision ID: 005
Down revision: 004
"""
from alembic import op
import sqlalchemy as sa

revision = "005"
down_revision = "004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "audit_logs",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column(
            "admin_id",
            sa.UUID(),
            sa.ForeignKey("docretour.users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("action_type", sa.String(80), nullable=False),
        sa.Column("target_type", sa.String(50), nullable=True),
        sa.Column("target_id",   sa.String(100), nullable=True),
        sa.Column("ip_address",  sa.String(45), nullable=True),
        sa.Column("extra",       sa.JSON(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.PrimaryKeyConstraint("id"),
        schema="docretour",
    )
    op.create_index(
        "ix_audit_logs_action_type",
        "audit_logs",
        ["action_type"],
        schema="docretour",
    )
    op.create_index(
        "ix_audit_logs_admin_id",
        "audit_logs",
        ["admin_id"],
        schema="docretour",
    )
    op.create_index(
        "ix_audit_logs_created_at",
        "audit_logs",
        ["created_at"],
        schema="docretour",
    )


def downgrade() -> None:
    op.drop_index("ix_audit_logs_created_at", "audit_logs", schema="docretour")
    op.drop_index("ix_audit_logs_admin_id",   "audit_logs", schema="docretour")
    op.drop_index("ix_audit_logs_action_type", "audit_logs", schema="docretour")
    op.drop_table("audit_logs", schema="docretour")
