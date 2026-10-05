"""add income categories

Revision ID: b2c4d6e8f901
Revises: fa91b2c3d4e5
Create Date: 2026-09-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b2c4d6e8f901"
down_revision: Union[str, None] = "fa91b2c3d4e5"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "incomes",
        sa.Column(
            "category",
            sa.String(length=50),
            nullable=False,
            server_default="Ingreso",
        ),
    )
    op.alter_column("incomes", "category", server_default=None)


def downgrade() -> None:
    op.drop_column("incomes", "category")
