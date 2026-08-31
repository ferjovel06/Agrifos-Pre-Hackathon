"""split phenological stage templates from parcel instances

Revision ID: f3c9b7a1d245
Revises: e8f4a2c7d901
Create Date: 2026-08-30
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f3c9b7a1d245"
down_revision: Union[str, None] = "e8f4a2c7d901"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM phenological_stages
                WHERE
                    (parcel_id IS NULL AND (
                        crop_id IS NULL
                        OR template_id IS NOT NULL
                        OR estimated_date IS NOT NULL
                        OR actual_date IS NOT NULL
                    ))
                    OR
                    (parcel_id IS NOT NULL AND (
                        crop_id IS NOT NULL
                        OR template_id IS NULL
                    ))
            ) THEN
                RAISE EXCEPTION
                    'Cannot split malformed phenological template or instance rows';
            END IF;

            IF EXISTS (
                SELECT 1
                FROM phenological_stages
                WHERE parcel_id IS NULL
                GROUP BY crop_id, stage_order
                HAVING COUNT(*) > 1
            ) THEN
                RAISE EXCEPTION
                    'Cannot split duplicate crop/stage-order templates';
            END IF;

            IF EXISTS (
                SELECT 1
                FROM phenological_stages
                WHERE parcel_id IS NOT NULL
                GROUP BY parcel_id, template_id
                HAVING COUNT(*) > 1
            ) THEN
                RAISE EXCEPTION
                    'Cannot split duplicate parcel/template instances';
            END IF;

            IF EXISTS (
                SELECT 1
                FROM optimal_requirements requirement
                JOIN phenological_stages stage ON stage.id = requirement.stage_id
                WHERE stage.parcel_id IS NOT NULL
            ) OR EXISTS (
                SELECT 1
                FROM stage_factors factor
                JOIN phenological_stages stage ON stage.id = factor.stage_id
                WHERE stage.parcel_id IS NOT NULL
            ) THEN
                RAISE EXCEPTION
                    'Agronomic references must point to stage templates';
            END IF;
        END $$;
        """
    )

    op.create_table(
        "phenological_stage_templates",
        sa.Column("crop_id", sa.UUID(), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("stage_order", sa.Integer(), nullable=False),
        sa.Column("duration_days", sa.Integer(), nullable=True),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.ForeignKeyConstraint(["crop_id"], ["crops.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "crop_id", "stage_order", name="uq_stage_template_crop_order"
        ),
    )
    op.execute(
        """
        INSERT INTO phenological_stage_templates (
            id, crop_id, name, stage_order, duration_days
        )
        SELECT id, crop_id, name, stage_order, duration_days
        FROM phenological_stages
        WHERE parcel_id IS NULL
        """
    )

    op.create_table(
        "parcel_phenological_stages",
        sa.Column("parcel_id", sa.UUID(), nullable=False),
        sa.Column("template_id", sa.UUID(), nullable=False),
        sa.Column("estimated_date", sa.Date(), nullable=True),
        sa.Column("actual_date", sa.Date(), nullable=True),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.ForeignKeyConstraint(
            ["parcel_id"], ["parcels.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["template_id"],
            ["phenological_stage_templates.id"],
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "parcel_id",
            "template_id",
            name="uq_parcel_phenological_stage_template",
        ),
    )
    op.execute(
        """
        INSERT INTO parcel_phenological_stages (
            id, parcel_id, template_id, estimated_date, actual_date
        )
        SELECT id, parcel_id, template_id, estimated_date, actual_date
        FROM phenological_stages
        WHERE parcel_id IS NOT NULL
        """
    )

    op.drop_constraint(
        "optimal_requirements_stage_id_fkey",
        "optimal_requirements",
        type_="foreignkey",
    )
    op.drop_constraint(
        "stage_factors_stage_id_fkey",
        "stage_factors",
        type_="foreignkey",
    )
    op.drop_table("phenological_stages")
    op.create_foreign_key(
        "fk_optimal_requirement_stage_template",
        "optimal_requirements",
        "phenological_stage_templates",
        ["stage_id"],
        ["id"],
        ondelete="RESTRICT",
    )
    op.create_foreign_key(
        "fk_stage_factor_stage_template",
        "stage_factors",
        "phenological_stage_templates",
        ["stage_id"],
        ["id"],
        ondelete="RESTRICT",
    )


def downgrade() -> None:
    op.create_table(
        "phenological_stages",
        sa.Column("template_id", sa.UUID(), nullable=True),
        sa.Column("crop_id", sa.UUID(), nullable=True),
        sa.Column("parcel_id", sa.UUID(), nullable=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("stage_order", sa.Integer(), nullable=False),
        sa.Column("duration_days", sa.Integer(), nullable=True),
        sa.Column("estimated_date", sa.Date(), nullable=True),
        sa.Column("actual_date", sa.Date(), nullable=True),
        sa.Column("id", sa.UUID(), nullable=False),
        sa.ForeignKeyConstraint(["crop_id"], ["crops.id"]),
        sa.ForeignKeyConstraint(["parcel_id"], ["parcels.id"]),
        sa.ForeignKeyConstraint(["template_id"], ["phenological_stages.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.execute(
        """
        INSERT INTO phenological_stages (
            id, template_id, crop_id, parcel_id, name, stage_order,
            duration_days, estimated_date, actual_date
        )
        SELECT
            id, NULL, crop_id, NULL, name, stage_order,
            duration_days, NULL, NULL
        FROM phenological_stage_templates
        """
    )
    op.execute(
        """
        INSERT INTO phenological_stages (
            id, template_id, crop_id, parcel_id, name, stage_order,
            duration_days, estimated_date, actual_date
        )
        SELECT
            instance.id,
            instance.template_id,
            NULL,
            instance.parcel_id,
            template.name,
            template.stage_order,
            template.duration_days,
            instance.estimated_date,
            instance.actual_date
        FROM parcel_phenological_stages instance
        JOIN phenological_stage_templates template
            ON template.id = instance.template_id
        """
    )

    op.drop_constraint(
        "fk_optimal_requirement_stage_template",
        "optimal_requirements",
        type_="foreignkey",
    )
    op.drop_constraint(
        "fk_stage_factor_stage_template",
        "stage_factors",
        type_="foreignkey",
    )
    op.drop_table("parcel_phenological_stages")
    op.drop_table("phenological_stage_templates")
    op.create_foreign_key(
        "optimal_requirements_stage_id_fkey",
        "optimal_requirements",
        "phenological_stages",
        ["stage_id"],
        ["id"],
    )
    op.create_foreign_key(
        "stage_factors_stage_id_fkey",
        "stage_factors",
        "phenological_stages",
        ["stage_id"],
        ["id"],
    )
