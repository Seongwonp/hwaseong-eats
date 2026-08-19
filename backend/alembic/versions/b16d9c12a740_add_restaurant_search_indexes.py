"""음식점 업종·태그 통합검색 인덱스 추가.

Revision ID: b16d9c12a740
Revises: 93bd072660e8
Create Date: 2026-08-15
"""

from typing import Sequence, Union

from alembic import op

revision: str = "b16d9c12a740"
down_revision: Union[str, None] = "93bd072660e8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_restaurants_category_trgm "
        "ON restaurants USING gin (category gin_trgm_ops)"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_restaurants_tags_gin "
        "ON restaurants USING gin (tags)"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_reviews_tags_gin "
        "ON reviews USING gin (tags)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_reviews_tags_gin")
    op.execute("DROP INDEX IF EXISTS ix_restaurants_tags_gin")
    op.execute("DROP INDEX IF EXISTS ix_restaurants_category_trgm")
