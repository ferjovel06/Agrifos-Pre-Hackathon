"""use decimal finance amounts

Revision ID: fa91b2c3d4e5
Revises: e6b8c1d4a902
Create Date: 2026-09-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "fa91b2c3d4e5"
down_revision: Union[str, None] = "e6b8c1d4a902"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    for table_name in ("incomes", "expenses"):
        op.alter_column(
            table_name,
            "amount",
            existing_type=sa.Float(),
            type_=sa.Numeric(12, 2),
            existing_nullable=False,
            postgresql_using="amount::numeric(12, 2)",
        )


def downgrade() -> None:
    for table_name in ("incomes", "expenses"):
        op.alter_column(
            table_name,
            "amount",
            existing_type=sa.Numeric(12, 2),
            type_=sa.Float(),
            existing_nullable=False,
            postgresql_using="amount::double precision",
        )
