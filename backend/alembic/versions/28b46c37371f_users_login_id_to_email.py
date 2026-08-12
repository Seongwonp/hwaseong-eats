"""users: login_id to email

아이디 대신 이메일로 가입받는다.

이미 가입된 계정이 있는 환경(배포 서버)에서도 깨지지 않게, 컬럼을 nullable 로 먼저 넣고
기존 login_id 를 옮겨 채운 뒤 NOT NULL 을 건다. 한 번에 NOT NULL 로 추가하면 기존 행
때문에 실패한다.

Revision ID: 28b46c37371f
Revises: ace9fc4e4a76
Create Date: 2026-08-12 05:46:28.209493

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "28b46c37371f"
down_revision: Union[str, None] = "ace9fc4e4a76"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# 기존 계정은 데모용이라 실제 이메일이 없다. 형식만 맞춰 옮겨두고 본인이 다시 가입하면 된다.
PLACEHOLDER_DOMAIN = "migrated.invalid"


def upgrade() -> None:
    op.add_column("users", sa.Column("email", sa.String(length=255), nullable=True))
    op.execute(
        f"UPDATE users SET email = login_id || '@{PLACEHOLDER_DOMAIN}' WHERE email IS NULL"
    )
    op.alter_column("users", "email", nullable=False)

    op.drop_constraint(op.f("users_login_id_key"), "users", type_="unique")
    op.create_unique_constraint("uq_users_email", "users", ["email"])
    op.drop_column("users", "login_id")


def downgrade() -> None:
    op.add_column("users", sa.Column("login_id", sa.VARCHAR(length=50), nullable=True))
    op.execute("UPDATE users SET login_id = split_part(email, '@', 1) WHERE login_id IS NULL")
    op.alter_column("users", "login_id", nullable=False)

    op.drop_constraint("uq_users_email", "users", type_="unique")
    op.create_unique_constraint(op.f("users_login_id_key"), "users", ["login_id"])
    op.drop_column("users", "email")
