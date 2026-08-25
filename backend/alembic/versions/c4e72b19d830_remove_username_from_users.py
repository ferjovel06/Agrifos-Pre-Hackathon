"""remove username from users

Revision ID: c4e72b19d830
Revises: a6c31e9b2f40
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c4e72b19d830"
down_revision: Union[str, None] = "a6c31e9b2f40"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column("users", "username")


def downgrade() -> None:
    op.add_column("users", sa.Column("username", sa.String(100), nullable=True))
