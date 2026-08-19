"""add kakao_id to users, make email/password_hash nullable

Revision ID: 4c8e2a1f9b3d
Revises: b16d9c12a740
Create Date: 2026-08-15 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "4c8e2a1f9b3d"
down_revision: Union[str, None] = "b16d9c12a740"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("kakao_id", sa.BigInteger(), nullable=True))
    op.create_unique_constraint("uq_users_kakao_id", "users", ["kakao_id"])
    op.alter_column("users", "email", existing_type=sa.String(255), nullable=True)
    op.alter_column("users", "password_hash", existing_type=sa.String(255), nullable=True)


def downgrade() -> None:
    op.alter_column("users", "password_hash", existing_type=sa.String(255), nullable=False)
    op.alter_column("users", "email", existing_type=sa.String(255), nullable=False)
    op.drop_constraint("uq_users_kakao_id", "users", type_="unique")
    op.drop_column("users", "kakao_id")
