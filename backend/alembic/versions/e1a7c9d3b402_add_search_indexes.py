"""검색·정렬 인덱스 추가

상호명 검색이 ILIKE '%...%' 라 4만 행을 순차 스캔하고 있었다(실측 59ms).
pg_trgm 의 GIN 인덱스는 양쪽 와일드카드 검색에도 인덱스를 태울 수 있다.

리뷰는 음식점별로 최신순 정렬해 꺼내므로 (restaurant_id, created_at) 복합 인덱스를 건다.
지금은 행이 적어 체감되지 않지만, 정렬 대상이 늘면 매번 전체를 훑게 된다.

Revision ID: e1a7c9d3b402
Revises: cd6f6b896774
Create Date: 2026-08-12

"""

from typing import Sequence, Union

from alembic import op

revision: str = "e1a7c9d3b402"
down_revision: Union[str, None] = "cd6f6b896774"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_restaurants_name_trgm "
        "ON restaurants USING gin (name gin_trgm_ops)"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_reviews_restaurant_created "
        "ON reviews (restaurant_id, created_at DESC)"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_reviews_user_created "
        "ON reviews (user_id, created_at DESC)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_reviews_user_created")
    op.execute("DROP INDEX IF EXISTS ix_reviews_restaurant_created")
    op.execute("DROP INDEX IF EXISTS ix_restaurants_name_trgm")
    # pg_trgm 은 다른 데서 쓸 수 있으니 지우지 않는다
