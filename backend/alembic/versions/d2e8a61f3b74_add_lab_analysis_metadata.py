"""add laboratory analysis metadata

Revision ID: d2e8a61f3b74
Revises: c4e72b19d830
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d2e8a61f3b74"
down_revision: Union[str, None] = "c4e72b19d830"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "lab_analyses",
        sa.Column("sample_code", sa.String(100), nullable=True),
    )
    op.add_column(
        "lab_analyses",
        sa.Column("sampled_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "lab_analyses",
        sa.Column("depth_start_cm", sa.Float(), nullable=True),
    )
    op.add_column(
        "lab_analyses",
        sa.Column("depth_end_cm", sa.Float(), nullable=True),
    )
    op.add_column("lab_analyses", sa.Column("ec", sa.Float(), nullable=True))
    op.add_column(
        "lab_analyses",
        sa.Column("ph_method", sa.String(100), nullable=True),
    )
    op.add_column(
        "lab_analyses",
        sa.Column("ec_method", sa.String(100), nullable=True),
    )
    op.add_column(
        "lab_analyses",
        sa.Column("phosphorus_method", sa.String(100), nullable=True),
    )
    op.add_column(
        "lab_analyses",
        sa.Column("potassium_method", sa.String(100), nullable=True),
    )
    op.create_unique_constraint(
        "uq_lab_analyses_parcel_sample_code",
        "lab_analyses",
        ["parcel_id", "sample_code"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_lab_analyses_parcel_sample_code",
        "lab_analyses",
        type_="unique",
    )
    op.drop_column("lab_analyses", "potassium_method")
    op.drop_column("lab_analyses", "phosphorus_method")
    op.drop_column("lab_analyses", "ec_method")
    op.drop_column("lab_analyses", "ph_method")
    op.drop_column("lab_analyses", "ec")
    op.drop_column("lab_analyses", "depth_end_cm")
    op.drop_column("lab_analyses", "depth_start_cm")
    op.drop_column("lab_analyses", "sampled_at")
    op.drop_column("lab_analyses", "sample_code")
