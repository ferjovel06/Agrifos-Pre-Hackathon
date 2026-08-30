import unittest
import uuid

from app.models import (
    AgronomicParameter,
    AgronomicReferenceSet,
    ApplicationScheduleRule,
    EfficiencyFactor,
    ExtractionIndex,
    FertilizerProduct,
    FertilizerProductNutrient,
    SoilReferenceRange,
    SoilType,
)
from app.repositories.agronomic_reference import build_engine_config
from app.services.agronomic_config import (
    IncompleteAgronomicConfigError,
    REQUIRED_EXTRACTION_INDICES,
    REQUIRED_PARAMETERS,
    REQUIRED_PRODUCTS,
    REQUIRED_SOIL_PARAMETERS,
)


def make_complete_records():
    crop_id = uuid.uuid4()
    reference_set = AgronomicReferenceSet(
        id=uuid.uuid4(),
        key="coffee-nicaragua",
        version="1.0.0",
        source="documented sources",
        is_active=True,
    )
    soil_ranges = [
        SoilReferenceRange(
            parameter=parameter,
            label_es=parameter,
            unit="unit",
            method="method",
            confidence="High",
            deficient_below=1,
            optimal_min=1,
            optimal_max=2,
            critical_above=3,
            high_is_generally_favorable=False,
            notes="notes",
        )
        for parameter in REQUIRED_SOIL_PARAMETERS
    ]
    products = []
    for key in REQUIRED_PRODUCTS:
        product = FertilizerProduct(
            key=key,
            name=key,
            is_low_chloride=False,
            is_active=True,
        )
        product.nutrients = [
            FertilizerProductNutrient(nutrient="N", fraction=0.5)
        ]
        products.append(product)
    parameters = [
        AgronomicParameter(key=key, value=1, unit="ratio")
        for key in REQUIRED_PARAMETERS
    ]
    schedules = [
        ApplicationScheduleRule(
            life_stage=life_stage,
            sequence=sequence,
            moment=f"{life_stage}-{sequence}",
            month_after_planting=None,
            fraction=1 / count,
        )
        for life_stage, count in (("production", 4), ("young_crop", 5))
        for sequence in range(1, count + 1)
    ]
    extraction_indices = [
        ExtractionIndex(nutrient=nutrient, ie_value=1)
        for nutrient in REQUIRED_EXTRACTION_INDICES
    ]
    soil_type = SoilType(name="Regional reference")
    efficiency_factors = [
        EfficiencyFactor(
            nutrient=nutrient,
            ef_min=0.4,
            ef_max=0.7,
            soil_type=soil_type,
        )
        for nutrient in REQUIRED_EXTRACTION_INDICES
    ]
    return {
        "reference_set": reference_set,
        "crop_id": crop_id,
        "soil_ranges": soil_ranges,
        "products": products,
        "parameters": parameters,
        "schedules": schedules,
        "extraction_indices": extraction_indices,
        "efficiency_factors": efficiency_factors,
        "variety_factors": [],
    }


class AgronomicReferenceRepositoryTests(unittest.TestCase):
    def test_builds_an_immutable_complete_configuration(self):
        records = make_complete_records()

        config = build_engine_config(**records)

        self.assertEqual(config.reference_version, "1.0.0")
        self.assertEqual(len(config.soil_ranges), 27)
        self.assertEqual(len(config.products), 7)
        self.assertEqual(len(config.schedules["production"]), 4)
        self.assertEqual(len(config.schedules["young_crop"]), 5)
        with self.assertRaises(TypeError):
            config.parameters["maintenance_factor"] = 0.5
        with self.assertRaises(TypeError):
            config.products["urea"].nutrients["N"] = 0.1

    def test_rejects_an_incomplete_active_dataset(self):
        records = make_complete_records()
        records["products"] = [
            product for product in records["products"] if product.key != "urea"
        ]

        with self.assertRaises(IncompleteAgronomicConfigError) as raised:
            build_engine_config(**records)

        self.assertIn("product:urea", raised.exception.missing)

    def test_rejects_a_product_without_a_composition(self):
        records = make_complete_records()
        urea = next(product for product in records["products"] if product.key == "urea")
        urea.nutrients = []

        with self.assertRaises(IncompleteAgronomicConfigError) as raised:
            build_engine_config(**records)

        self.assertIn("product_composition:urea", raised.exception.missing)


if __name__ == "__main__":
    unittest.main()
