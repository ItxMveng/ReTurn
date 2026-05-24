"""add connection_logs table

Revision ID: 005
Revises: 004
Create Date: 2026-05-24
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "005"
down_revision = "004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    connection_status = postgresql.ENUM(
        "success", "failed", "banned",
        name="connectionstatus",
    )
    connection_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "connection_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("phone_number", sa.String(30), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.String(500), nullable=True),
        sa.Column("device_id", sa.String(200), nullable=True),
        sa.Column("auth_method", sa.String(20), nullable=False, server_default="otp"),
        sa.Column(
            "status",
            sa.Enum(name="connectionstatus"),
            nullable=False,
            server_default="success",
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    # Index composites pour les requêtes fréquentes
    op.create_index("ix_conn_logs_user_id", "connection_logs", ["user_id"])
    op.create_index("ix_conn_logs_ip", "connection_logs", ["ip_address"])
    op.create_index("ix_conn_logs_phone", "connection_logs", ["phone_number"])
    op.create_index("ix_conn_logs_status", "connection_logs", ["status"])
    op.create_index("ix_conn_logs_created", "connection_logs", ["created_at"])
    # Index composite (user_id, created_at) pour la requête sessions d'un user
    op.create_index(
        "ix_conn_logs_user_date",
        "connection_logs",
        ["user_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_table("connection_logs")
    op.execute("DROP TYPE IF EXISTS connectionstatus")
