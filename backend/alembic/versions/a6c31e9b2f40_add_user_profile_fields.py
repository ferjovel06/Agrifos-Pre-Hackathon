"""add user profile fields

Revision ID: a6c31e9b2f40
Revises: 4f2a1c7d9e10
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "a6c31e9b2f40"
down_revision: Union[str, None] = "4f2a1c7d9e10"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("username", sa.String(100), nullable=True))
    op.add_column("users", sa.Column("birth_date", sa.Date(), nullable=True))
    op.add_column("users", sa.Column("gender", sa.String(30), nullable=True))
    op.add_column("users", sa.Column("phone", sa.String(30), nullable=True))
    op.add_column("users", sa.Column("country", sa.String(80), nullable=True))
    op.add_column("users", sa.Column("department", sa.String(100), nullable=True))
    op.add_column("users", sa.Column("address", sa.String(255), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "address")
    op.drop_column("users", "department")
    op.drop_column("users", "country")
    op.drop_column("users", "phone")
    op.drop_column("users", "gender")
    op.drop_column("users", "birth_date")
    op.drop_column("users", "username")
