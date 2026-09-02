"""persist fertilization recommendation details

Revision ID: e8f4a2c7d901
Revises: c42d9e18a6f1
Create Date: 2026-08-30
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e8f4a2c7d901"
down_revision: Union[str, None] = "c42d9e18a6f1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "fertilization_plans",
        sa.Column("reference_set_id", sa.UUID(), nullable=True),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column("target_green_kg_ha", sa.Float(), server_default="0", nullable=False),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column("plant_age_months", sa.Integer(), server_default="0", nullable=False),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column(
            "life_stage",
            sa.String(length=40),
            server_default="legacy",
            nullable=False,
        ),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column(
            "fruit_stage",
            sa.String(length=40),
            server_default="legacy",
            nullable=False,
        ),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column(
            "engine_version",
            sa.String(length=40),
            server_default="legacy",
            nullable=False,
        ),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column(
            "recommendation_status",
            sa.String(length=60),
            server_default="legacy",
            nullable=False,
        ),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column(
            "nutrient_requirements",
            sa.JSON(),
            server_default="[]",
            nullable=False,
        ),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column("limiting_nutrients", sa.JSON(), server_default="[]", nullable=False),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column("warnings", sa.JSON(), server_default="[]", nullable=False),
    )
    op.add_column(
        "fertilization_plans",
        sa.Column("assumptions", sa.JSON(), server_default="[]", nullable=False),
    )
    op.create_foreign_key(
        "fk_fertilization_plan_reference_set",
        "fertilization_plans",
        "agronomic_reference_sets",
        ["reference_set_id"],
        ["id"],
        ondelete="RESTRICT",
    )
    op.execute(
        """
        UPDATE fertilization_plans
        SET reference_set_id = (
            SELECT id
            FROM agronomic_reference_sets
            WHERE is_active IS TRUE
            ORDER BY created_at DESC
            LIMIT 1
        )
        WHERE reference_set_id IS NULL
        """
    )
    op.alter_column("fertilization_plans", "reference_set_id", nullable=False)

    for column in (
        "target_green_kg_ha",
        "plant_age_months",
        "life_stage",
        "fruit_stage",
        "engine_version",
        "recommendation_status",
        "nutrient_requirements",
        "limiting_nutrients",
        "warnings",
        "assumptions",
    ):
        op.alter_column("fertilization_plans", column, server_default=None)

    op.create_table(
        "fertilization_plan_items",
        sa.Column("plan_id", sa.UUID(), nullable=False),
        sa.Column("fertilizer_product_id", sa.UUID(), nullable=False),
        sa.Column("scenario_name", sa.String(length=100), nullable=False),
        sa.Column("selection_method", sa.String(length=255), nullable=False),
        sa.Column("scenario_is_valid", sa.Boolean(), nullable=False),
        sa.Column("application_number", sa.Integer(), nullable=False),
        sa.Column("moment", sa.String(length=150), nullable=False),
        sa.Column("fraction", sa.Float(), nullable=False),
        sa.Column("kg_ha", sa.Float(), nullable=False),
        sa.Column("kg_manzana", sa.Float(), nullable=False),
        sa.Column("g_plant", sa.Float(), nullable=False),
        sa.Column("guaranteed_analysis_pct", sa.JSON(), nullable=False),
        sa.Column("nutrient_contributions_kg_ha", sa.JSON(), nullable=False),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.CheckConstraint(
            "fraction > 0 AND fraction <= 1", name="ck_plan_item_fraction"
        ),
        sa.CheckConstraint(
            "kg_ha >= 0 AND kg_manzana >= 0 AND g_plant >= 0",
            name="ck_plan_item_nonnegative_doses",
        ),
        sa.ForeignKeyConstraint(
            ["fertilizer_product_id"],
            ["fertilizer_products.id"],
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["plan_id"], ["fertilization_plans.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "plan_id",
            "scenario_name",
            "application_number",
            "fertilizer_product_id",
            name="uq_plan_item_scenario_application_product",
        ),
    )


def downgrade() -> None:
    op.drop_table("fertilization_plan_items")
    op.drop_constraint(
        "fk_fertilization_plan_reference_set",
        "fertilization_plans",
        type_="foreignkey",
    )
    for column in (
        "assumptions",
        "warnings",
        "limiting_nutrients",
        "nutrient_requirements",
        "recommendation_status",
        "engine_version",
        "fruit_stage",
        "life_stage",
        "plant_age_months",
        "target_green_kg_ha",
        "reference_set_id",
    ):
        op.drop_column("fertilization_plans", column)
