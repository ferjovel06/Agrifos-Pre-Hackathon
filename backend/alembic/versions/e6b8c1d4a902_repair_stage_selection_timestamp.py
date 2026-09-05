"""repair stage selection timestamp default and nullability

Revision ID: e6b8c1d4a902
Revises: d9f4a6b8c210
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e6b8c1d4a902"
down_revision: Union[str, None] = "d9f4a6b8c210"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Repair databases where the previous revision is recorded as applied but
    # selected_at still has neither its default nor its NOT NULL constraint.
    # Use the original backfill policy, preserving existing selection times.
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
          AND parcel_stage.selected_at IS NULL
        """
    )
    op.alter_column(
        "parcel_phenological_stages",
        "selected_at",
        existing_type=sa.DateTime(timezone=True),
        nullable=False,
        server_default=sa.text("now()"),
    )


def downgrade() -> None:
    # The preceding revision already requires this same default and constraint.
    # Preserve its intended schema rather than reintroducing database drift.
    pass
