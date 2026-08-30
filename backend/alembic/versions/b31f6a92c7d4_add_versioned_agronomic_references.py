"""add versioned agronomic reference tables

Revision ID: b31f6a92c7d4
Revises: f7b2c94a1d30
Create Date: 2026-08-30
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b31f6a92c7d4"
down_revision: Union[str, None] = "f7b2c94a1d30"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "agronomic_reference_sets",
        sa.Column("key", sa.String(length=80), nullable=False),
        sa.Column("version", sa.String(length=40), nullable=False),
        sa.Column("source", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("key", "version", name="uq_reference_set_key_version"),
    )
    op.create_index(
        "ix_agronomic_reference_sets_active",
        "agronomic_reference_sets",
        ["key"],
        unique=True,
        postgresql_where=sa.text("is_active"),
    )

    for table_name in (
        "optimal_requirements",
        "extraction_indices",
        "variety_factors",
        "stage_factors",
        "efficiency_factors",
    ):
        op.add_column(
            table_name,
            sa.Column("reference_set_id", sa.UUID(), nullable=True),
        )
        op.create_foreign_key(
            f"fk_{table_name}_reference_set_id",
            table_name,
            "agronomic_reference_sets",
            ["reference_set_id"],
            ["id"],
            ondelete="RESTRICT",
        )

    op.create_table(
        "soil_reference_ranges",
        sa.Column("reference_set_id", sa.UUID(), nullable=False),
        sa.Column("crop_id", sa.UUID(), nullable=False),
        sa.Column("parameter", sa.String(length=50), nullable=False),
        sa.Column("label_es", sa.String(length=120), nullable=False),
        sa.Column("unit", sa.String(length=40), nullable=False),
        sa.Column("method", sa.Text(), nullable=False),
        sa.Column("confidence", sa.String(length=30), nullable=False),
        sa.Column("deficient_below", sa.Float(), nullable=True),
        sa.Column("optimal_min", sa.Float(), nullable=True),
        sa.Column("optimal_max", sa.Float(), nullable=True),
        sa.Column("critical_above", sa.Float(), nullable=True),
        sa.Column("high_is_generally_favorable", sa.Boolean(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.CheckConstraint(
            "optimal_min IS NULL OR optimal_max IS NULL OR optimal_min <= optimal_max",
            name="ck_soil_range_valid_optimal_bounds",
        ),
        sa.ForeignKeyConstraint(
            ["crop_id"], ["crops.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["reference_set_id"],
            ["agronomic_reference_sets.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "reference_set_id",
            "crop_id",
            "parameter",
            name="uq_soil_range_set_crop_parameter",
        ),
    )

    op.create_table(
        "fertilizer_products",
        sa.Column("reference_set_id", sa.UUID(), nullable=False),
        sa.Column("key", sa.String(length=60), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("is_low_chloride", sa.Boolean(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.ForeignKeyConstraint(
            ["reference_set_id"],
            ["agronomic_reference_sets.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "reference_set_id", "key", name="uq_fertilizer_product_set_key"
        ),
    )

    op.create_table(
        "fertilizer_product_nutrients",
        sa.Column("product_id", sa.UUID(), nullable=False),
        sa.Column("nutrient", sa.String(length=30), nullable=False),
        sa.Column("fraction", sa.Float(), nullable=False),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.CheckConstraint(
            "fraction > 0 AND fraction <= 1",
            name="ck_product_nutrient_fraction",
        ),
        sa.ForeignKeyConstraint(
            ["product_id"], ["fertilizer_products.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("product_id", "nutrient", name="uq_product_nutrient"),
    )

    op.create_table(
        "application_schedule_rules",
        sa.Column("reference_set_id", sa.UUID(), nullable=False),
        sa.Column("crop_id", sa.UUID(), nullable=False),
        sa.Column("life_stage", sa.String(length=40), nullable=False),
        sa.Column("sequence", sa.Integer(), nullable=False),
        sa.Column("moment", sa.String(length=150), nullable=False),
        sa.Column("month_after_planting", sa.Integer(), nullable=True),
        sa.Column("fraction", sa.Float(), nullable=False),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.CheckConstraint(
            "fraction > 0 AND fraction <= 1", name="ck_application_rule_fraction"
        ),
        sa.ForeignKeyConstraint(
            ["crop_id"], ["crops.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["reference_set_id"],
            ["agronomic_reference_sets.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "reference_set_id",
            "crop_id",
            "life_stage",
            "sequence",
            name="uq_application_rule_set_crop_stage_sequence",
        ),
    )

    op.create_table(
        "agronomic_parameters",
        sa.Column("reference_set_id", sa.UUID(), nullable=False),
        sa.Column("crop_id", sa.UUID(), nullable=False),
        sa.Column("key", sa.String(length=100), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("unit", sa.String(length=40), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.ForeignKeyConstraint(
            ["crop_id"], ["crops.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["reference_set_id"],
            ["agronomic_reference_sets.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "reference_set_id",
            "crop_id",
            "key",
            name="uq_agronomic_parameter_set_crop_key",
        ),
    )


def downgrade() -> None:
    op.drop_table("agronomic_parameters")
    op.drop_table("application_schedule_rules")
    op.drop_table("fertilizer_product_nutrients")
    op.drop_table("fertilizer_products")
    op.drop_table("soil_reference_ranges")
    for table_name in (
        "efficiency_factors",
        "stage_factors",
        "variety_factors",
        "extraction_indices",
        "optimal_requirements",
    ):
        op.drop_constraint(
            f"fk_{table_name}_reference_set_id", table_name, type_="foreignkey"
        )
        op.drop_column(table_name, "reference_set_id")
    op.drop_index(
        "ix_agronomic_reference_sets_active",
        table_name="agronomic_reference_sets",
    )
    op.drop_table("agronomic_reference_sets")
