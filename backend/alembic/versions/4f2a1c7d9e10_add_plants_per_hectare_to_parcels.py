"""add plants per hectare to parcels

Revision ID: 4f2a1c7d9e10
Revises: 0890813f2d15
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "4f2a1c7d9e10"
down_revision: Union[str, None] = "0890813f2d15"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Nullable for legacy parcels whose historical density is unknown.
    # The create API requires this field for every new parcel.
    op.add_column(
        "parcels",
        sa.Column("plants_per_hectare", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("parcels", "plants_per_hectare")
