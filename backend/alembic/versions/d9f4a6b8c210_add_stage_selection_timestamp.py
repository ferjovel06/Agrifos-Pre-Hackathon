"""add stage selection timestamp

Revision ID: d9f4a6b8c210
Revises: a4e8c2d71f90
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d9f4a6b8c210"
down_revision: Union[str, None] = "a4e8c2d71f90"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "parcel_phenological_stages",
        sa.Column("selected_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.execute(
        """
        UPDATE parcel_phenological_stages AS parcel_stage
        SET selected_at =
            COALESCE(
                parcel_stage.actual_date::timestamp AT TIME ZONE 'UTC',
                TIMESTAMPTZ '1970-01-01 00:00:00+00'
            ) + stage.stage_order * INTERVAL '1 microsecond'
        FROM phenological_stage_templates AS stage
        WHERE stage.id = parcel_stage.template_id
        """
    )
    op.alter_column(
        "parcel_phenological_stages",
        "selected_at",
        nullable=False,
        server_default=sa.text("now()"),
    )


def downgrade() -> None:
    op.drop_column("parcel_phenological_stages", "selected_at")
