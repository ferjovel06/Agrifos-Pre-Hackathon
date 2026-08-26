import unittest
import uuid

from pydantic import ValidationError

from app.schemas.fertilization import (
    FertilizationRecommendationRequest,
    FruitStage,
    NutrientStatus,
    SoilAssessmentInput,
    SoilSource,
    YieldUnit,
)
from app.services.fertilization_service import (
    FertilizationInputError,
    calculate_fertilization_recommendation,
)


def make_request(**overrides):
    values = {
        "parcel_id": uuid.uuid4(),
        "target_yield": 20,
        "yield_unit": YieldUnit.QQ_GOLD_HA,
        "fruit_stage": FruitStage.EXPANSION,
        "soil": SoilAssessmentInput(
            source=SoilSource.LABORATORY,
            nitrogen=NutrientStatus.DEFICIENT,
            phosphorus=NutrientStatus.DEFICIENT,
            potassium=NutrientStatus.DEFICIENT,
            phosphorus_method="Bray II",
            potassium_method="Ammonium acetate",
            ph=5.2,
            ec_ds_m=0.5,
        ),
    }
    values.update(overrides)
    return FertilizationRecommendationRequest(**values)


def calculate(request):
    return calculate_fertilization_recommendation(
        request,
        crop_name="Café",
        variety_name="Caturra",
        plant_age_months=32,
        area_hectares=1.5,
        plants_per_hectare=5000,
    )


class FertilizationServiceTests(unittest.TestCase):
    def test_calculates_the_central_twenty_quintal_scenario(self):
        result = calculate(make_request())

        self.assertEqual(result.target_green_kg_ha, 920)
        requirements = {
            row.nutrient: row.fertilizer_requirement_kg_ha
            for row in result.nutrient_requirements
        }
        self.assertAlmostEqual(requirements["N"], 71.07, places=2)
        self.assertAlmostEqual(requirements["P2O5"], 20.20, places=2)
        self.assertAlmostEqual(requirements["K2O"], 92.97, places=2)
        self.assertEqual(result.limiting_nutrients, ["N", "P", "K"])
        self.assertTrue(
            all(
                scenario.is_mathematically_valid
                for scenario in result.fertilizer_scenarios
            )
        )
        self.assertEqual(
            [
                application.fraction
                for application in result.fertilizer_scenarios[0].application_schedule
            ],
            [0.25, 0.30, 0.30, 0.15],
        )

    def test_converts_every_product_to_manzanas_and_grams_per_plant(self):
        result = calculate(make_request())
        product = result.fertilizer_scenarios[0].products[0]

        self.assertAlmostEqual(product.kg_manzana, product.kg_ha * 0.7042, delta=0.02)
        self.assertAlmostEqual(product.g_plant, product.kg_ha / 5, delta=0.02)

    def test_converts_cherry_quintals_to_green_coffee(self):
        result = calculate(
            make_request(target_yield=100, yield_unit=YieldUnit.QQ_CHERRY_HA)
        )

        self.assertEqual(result.target_green_kg_ha, 920)

    def test_high_nutrient_status_blocks_that_nutrient(self):
        request = make_request(
            soil=SoilAssessmentInput(
                source=SoilSource.LABORATORY,
                nitrogen=NutrientStatus.ADEQUATE,
                phosphorus=NutrientStatus.HIGH,
                potassium=NutrientStatus.HIGH,
                phosphorus_method="Bray II",
                potassium_method="Ammonium acetate",
            )
        )
        result = calculate(request)
        requirements = {
            row.nutrient: row.fertilizer_requirement_kg_ha
            for row in result.nutrient_requirements
        }

        self.assertEqual(requirements["P2O5"], 0)
        self.assertEqual(requirements["K2O"], 0)
        self.assertEqual(
            [product.product for product in result.fertilizer_scenarios[0].products],
            ["Urea"],
        )

    def test_high_ec_uses_a_low_chloride_source(self):
        request = make_request(
            soil=SoilAssessmentInput(
                source=SoilSource.LABORATORY,
                nitrogen=NutrientStatus.DEFICIENT,
                phosphorus=NutrientStatus.DEFICIENT,
                potassium=NutrientStatus.DEFICIENT,
                phosphorus_method="Bray II",
                potassium_method="Ammonium acetate",
                ec_ds_m=0.9,
            )
        )
        result = calculate(request)
        names = {
            product.product for product in result.fertilizer_scenarios[0].products
        }

        self.assertIn("Sulfato de potasio", names)
        self.assertNotIn("KCl", names)

    def test_splits_large_n_demand_below_the_per_application_limit(self):
        request = make_request(target_yield=50)
        result = calculate(request)
        schedule = result.fertilizer_scenarios[0].application_schedule

        self.assertGreaterEqual(len(schedule), 5)
        for application in schedule:
            supplied_n = sum(
                product.nutrient_contributions_kg_ha.get("N", 0)
                for product in application.products
            )
            self.assertLessEqual(supplied_n, 40.02)

    def test_rejects_sensor_only_and_critical_ec_inputs(self):
        sensor_request = make_request(
            soil=SoilAssessmentInput(
                source=SoilSource.SENSOR,
                nitrogen=NutrientStatus.DEFICIENT,
                phosphorus=NutrientStatus.DEFICIENT,
                potassium=NutrientStatus.DEFICIENT,
            )
        )
        with self.assertRaises(FertilizationInputError):
            calculate(sensor_request)

        high_ec_request = make_request(
            soil=SoilAssessmentInput(
                source=SoilSource.LABORATORY,
                nitrogen=NutrientStatus.DEFICIENT,
                phosphorus=NutrientStatus.DEFICIENT,
                potassium=NutrientStatus.DEFICIENT,
                phosphorus_method="Bray II",
                potassium_method="Ammonium acetate",
                ec_ds_m=1.1,
            )
        )
        with self.assertRaises(FertilizationInputError):
            calculate(high_ec_request)

    def test_requires_methods_for_laboratory_assessments(self):
        with self.assertRaises(ValidationError):
            SoilAssessmentInput(
                source=SoilSource.LABORATORY,
                nitrogen=NutrientStatus.DEFICIENT,
                phosphorus=NutrientStatus.DEFICIENT,
                potassium=NutrientStatus.DEFICIENT,
            )


if __name__ == "__main__":
    unittest.main()
