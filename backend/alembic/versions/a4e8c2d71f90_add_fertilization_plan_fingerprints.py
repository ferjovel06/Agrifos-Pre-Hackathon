"""add fertilization plan fingerprints

Revision ID: a4e8c2d71f90
Revises: f3c9b7a1d245
Create Date: 2026-08-31
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "a4e8c2d71f90"
down_revision: Union[str, None] = "f3c9b7a1d245"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fertilization_plans",
        sa.Column("input_fingerprint", sa.String(length=64), nullable=True),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column("recommendation_snapshot", sa.JSON(), nullable=True),
    )
    op.create_unique_constraint(
        "uq_fertilization_plan_parcel_fingerprint",
        "fertilization_plans",
        ["parcel_id", "input_fingerprint"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_fertilization_plan_parcel_fingerprint",
        "fertilization_plans",
        type_="unique",
    )
    op.drop_column("fertilization_plans", "recommendation_snapshot")
    op.drop_column("fertilization_plans", "input_fingerprint")
