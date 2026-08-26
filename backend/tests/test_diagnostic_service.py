import unittest
import uuid
from datetime import datetime, timezone
from types import SimpleNamespace

from pydantic import ValidationError

from app.schemas.reading import ReadingCreate
from app.services.diagnostic_service import (
    ENGINE_VERSION,
    InvalidDiagnosticReadingError,
    UnsupportedDiagnosticCropError,
    diagnose_sensor_reading,
)
from app.services.soil_reference_ranges import SoilLevel


def make_reading(**overrides):
    values = {
        "id": uuid.uuid4(),
        "parcel_id": uuid.uuid4(),
        "nitrogen": 20.0,
        "phosphorus": 15.0,
        "potassium": 100.0,
        "ec": 0.5,
        "ph": 5.2,
        "temperature": 24.0,
        "humidity": 72.0,
        "recorded_at": datetime.now(timezone.utc),
    }
    values.update(overrides)
    return SimpleNamespace(**values)


class DiagnoseSensorReadingTests(unittest.TestCase):
    def test_classifies_all_supported_sensor_parameters(self):
        result = diagnose_sensor_reading(make_reading(), "Café")

        self.assertEqual(result.engine_version, ENGINE_VERSION)
        self.assertEqual(result.overall_confidence, "low")
        self.assertEqual(result.reference_status, "transferred_reference")
        self.assertEqual(result.measurement_method, "seven_in_one_sensor")
        self.assertEqual(len(result.parameters), 5)
        self.assertEqual(
            {parameter.parameter: parameter.level for parameter in result.parameters},
            {
                "nitrogen": SoilLevel.OPTIMAL,
                "phosphorus": SoilLevel.OPTIMAL,
                "potassium": SoilLevel.OPTIMAL,
                "ec": SoilLevel.OPTIMAL,
                "ph": SoilLevel.OPTIMAL,
            },
        )

    def test_adds_safety_warnings_for_low_nutrients_and_high_ec(self):
        result = diagnose_sensor_reading(
            make_reading(nitrogen=5, phosphorus=5, potassium=50, ec=1.2),
            "Coffea arabica",
        )

        self.assertIn("Nitrógeno bajo.", result.warnings)
        self.assertIn("Fósforo bajo.", result.warnings)
        self.assertIn("Potasio bajo.", result.warnings)
        self.assertFalse(any("laboratorio" in warning for warning in result.warnings[2:]))
        self.assertTrue(any("sales" in warning for warning in result.warnings))

    def test_describes_high_noncritical_values_as_acceptable_with_follow_up(self):
        result = diagnose_sensor_reading(make_reading(nitrogen=40), "Café")

        nitrogen = next(
            parameter
            for parameter in result.parameters
            if parameter.parameter == "nitrogen"
        )
        self.assertEqual(nitrogen.level, SoilLevel.HIGH)
        self.assertEqual(nitrogen.message, "Aceptable, con seguimiento")

    def test_rejects_crop_without_reference_ranges(self):
        with self.assertRaises(UnsupportedDiagnosticCropError):
            diagnose_sensor_reading(make_reading(), "Maíz")

    def test_rejects_reading_outside_physical_limits(self):
        with self.assertRaises(InvalidDiagnosticReadingError):
            diagnose_sensor_reading(make_reading(ph=1.9), "Café")

    def test_request_schema_rejects_ph_outside_diagnostic_limits(self):
        reading = make_reading(ph=10.1)
        with self.assertRaises(ValidationError):
            ReadingCreate(
                parcel_id=reading.parcel_id,
                nitrogen=reading.nitrogen,
                phosphorus=reading.phosphorus,
                potassium=reading.potassium,
                ec=reading.ec,
                ph=reading.ph,
                temperature=reading.temperature,
                humidity=reading.humidity,
            )


if __name__ == "__main__":
    unittest.main()
