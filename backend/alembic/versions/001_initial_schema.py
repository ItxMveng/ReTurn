"""001 — initial schema: users, declarations, matches, messages, identity_verifications

Revision ID: 001
Revises: 
Create Date: 2026-05-24
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = "001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE SCHEMA IF NOT EXISTS docretour")

    op.create_table(
        "users",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("firebase_uid", sa.String(128), unique=True, nullable=True),
        sa.Column("phone_number", sa.String(100), unique=True, nullable=False),
        sa.Column("email", sa.String(254), unique=True, nullable=True),
        sa.Column("full_name", sa.String(100), nullable=False, server_default=""),
        sa.Column("date_of_birth", sa.Date, nullable=True),
        sa.Column("national_id_number", sa.String(50), nullable=True),
        sa.Column("gender", sa.String(20), nullable=True),
        sa.Column("city", sa.String(100), nullable=True),
        sa.Column("region", sa.String(100), nullable=True),
        sa.Column("address", sa.String(255), nullable=True),
        sa.Column("avatar_url", sa.String(512), nullable=True),
        sa.Column("fcm_token", sa.String(512), nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("is_verified", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        schema="docretour",
    )
    op.create_index("ix_users_firebase_uid", "users", ["firebase_uid"], schema="docretour")
    op.create_index("ix_users_phone_number", "users", ["phone_number"], schema="docretour")

    op.create_table(
        "declarations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("docretour.users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("declaration_type", sa.String(10), nullable=False),
        sa.Column("document_type", sa.String(30), nullable=False),
        sa.Column("document_number", sa.String(50), nullable=True),
        sa.Column("owner_name", sa.String(100), nullable=True),
        sa.Column("description", sa.String(500), nullable=True),
        sa.Column("latitude", sa.Float, nullable=True),
        sa.Column("longitude", sa.Float, nullable=True),
        sa.Column("location_description", sa.String(200), nullable=True),
        sa.Column("photo_urls", sa.JSON, nullable=False, server_default="[]"),
        sa.Column("status", sa.String(20), nullable=False, server_default="active"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        schema="docretour",
    )
    op.create_index("ix_declarations_user_id", "declarations", ["user_id"], schema="docretour")
    op.create_index("ix_declarations_document_type", "declarations", ["document_type"], schema="docretour")
    op.create_index("ix_declarations_status", "declarations", ["status"], schema="docretour")

    op.create_table(
        "matches",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("declaration_found_id", UUID(as_uuid=True), sa.ForeignKey("docretour.declarations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("declaration_lost_id", UUID(as_uuid=True), sa.ForeignKey("docretour.declarations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_found_id", UUID(as_uuid=True), sa.ForeignKey("docretour.users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_lost_id", UUID(as_uuid=True), sa.ForeignKey("docretour.users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("score", sa.Float, nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        schema="docretour",
    )
    op.create_index("ix_matches_user_found_id", "matches", ["user_found_id"], schema="docretour")
    op.create_index("ix_matches_user_lost_id", "matches", ["user_lost_id"], schema="docretour")
    op.create_index("ix_matches_status", "matches", ["status"], schema="docretour")

    op.create_table(
        "messages",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("match_id", UUID(as_uuid=True), sa.ForeignKey("docretour.matches.id", ondelete="CASCADE"), nullable=False),
        sa.Column("sender_id", UUID(as_uuid=True), sa.ForeignKey("docretour.users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("content", sa.Text, nullable=False),
        sa.Column("message_type", sa.String(20), nullable=False, server_default="text"),
        sa.Column("is_read", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        schema="docretour",
    )
    op.create_index("ix_messages_match_id", "messages", ["match_id"], schema="docretour")

    op.create_table(
        "identity_verifications",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("match_id", UUID(as_uuid=True), sa.ForeignKey("docretour.matches.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("docretour.users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("selfie_url", sa.String(500), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        schema="docretour",
    )
    op.create_index("ix_identity_verifications_match_id", "identity_verifications", ["match_id"], schema="docretour")


def downgrade() -> None:
    op.drop_table("identity_verifications", schema="docretour")
    op.drop_table("messages", schema="docretour")
    op.drop_table("matches", schema="docretour")
    op.drop_table("declarations", schema="docretour")
    op.drop_table("users", schema="docretour")
    op.execute("DROP SCHEMA IF EXISTS docretour CASCADE")
