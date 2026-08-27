"""add climate alert metadata

Revision ID: f7b2c94a1d30
Revises: d2e8a61f3b74
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f7b2c94a1d30"
down_revision: Union[str, None] = "d2e8a61f3b74"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "alerts",
        sa.Column(
            "title",
            sa.String(length=150),
            nullable=False,
            server_default="Alerta",
        ),
    )
    op.add_column(
        "alerts",
        sa.Column(
            "severity",
            sa.String(length=20),
            nullable=False,
            server_default="warning",
        ),
    )
    op.add_column("alerts", sa.Column("event_date", sa.Date(), nullable=True))
    op.add_column("alerts", sa.Column("risk_score", sa.Float(), nullable=True))
    op.add_column(
        "alerts",
        sa.Column(
            "is_active",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
    )
    op.create_unique_constraint(
        "uq_alert_farm_type_event_date",
        "alerts",
        ["farm_id", "type", "event_date"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_alert_farm_type_event_date",
        "alerts",
        type_="unique",
    )
    op.drop_column("alerts", "is_active")
    op.drop_column("alerts", "risk_score")
    op.drop_column("alerts", "event_date")
    op.drop_column("alerts", "severity")
    op.drop_column("alerts", "title")
