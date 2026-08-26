import unicodedata
from collections.abc import Mapping
from typing import Any

from app.schemas.diagnostic import (
    DiagnosticParameterRead,
    DiagnosticRangeRead,
    SensorContextRead,
    SensorDiagnosticRead,
)
from app.services.soil_reference_ranges import (
    READING_FIELD_MAP,
    SOIL_REFERENCE_RANGES,
    SoilLevel,
    classify,
)


ENGINE_VERSION = "sensor-diagnostic-1.0.0"
REFERENCE_SOURCE = "Parametros_laboratorio_cafe_APA7"

_SUPPORTED_COFFEE_NAMES = {
    "cafe",
    "cafe arabica",
    "coffea arabica",
    "coffee",
}

_LEVEL_MESSAGES: Mapping[SoilLevel, str] = {
    SoilLevel.DEFICIENT: "Nivel deficiente",
    SoilLevel.OPTIMAL: "Rango adecuado",
    SoilLevel.HIGH: "Aceptable, con seguimiento",
    SoilLevel.CRITICAL: "Nivel crítico",
}

_NUTRIENT_NAMES = {
    "nitrogen": "Nitrógeno",
    "phosphorus": "Fósforo",
    "potassium": "Potasio",
}


class UnsupportedDiagnosticCropError(ValueError):
    pass


class InvalidDiagnosticReadingError(ValueError):
    pass


def _normalize_crop_name(name: str) -> str:
    normalized = unicodedata.normalize("NFKD", name.strip().lower())
    return "".join(char for char in normalized if not unicodedata.combining(char))


def ensure_supported_crop(crop_name: str) -> None:
    if _normalize_crop_name(crop_name) not in _SUPPORTED_COFFEE_NAMES:
        raise UnsupportedDiagnosticCropError(
            f"Sensor diagnosis is not configured for crop '{crop_name}'."
        )


def _validate_reading(reading: Any) -> None:
    limits = {
        "nitrogen": (0, 1000),
        "phosphorus": (0, 1000),
        "potassium": (0, 1000),
        "ec": (0, 20),
        "ph": (2, 10),
        "temperature": (-10, 60),
        "humidity": (0, 100),
    }
    for field, (minimum, maximum) in limits.items():
        value = getattr(reading, field)
        if value < minimum or value > maximum:
            raise InvalidDiagnosticReadingError(
                f"{field} must be between {minimum} and {maximum}."
            )


def _parameter_warnings(parameter: str, level: SoilLevel) -> list[str]:
    warnings: list[str] = []

    if parameter in _NUTRIENT_NAMES and level == SoilLevel.DEFICIENT:
        warnings.append(f"{_NUTRIENT_NAMES[parameter]} bajo.")
    if parameter == "ec" and level in {SoilLevel.HIGH, SoilLevel.CRITICAL}:
        warnings.append("Conductividad eléctrica elevada; evitar aumentar sales.")
    if parameter == "ph" and level == SoilLevel.DEFICIENT:
        warnings.append(
            "pH ácido; solicitar acidez de reserva y aluminio intercambiable "
            "antes de recomendar encalado."
        )
    elif parameter == "ph" and level in {SoilLevel.HIGH, SoilLevel.CRITICAL}:
        warnings.append("pH elevado para café.")

    return warnings


def diagnose_sensor_reading(reading: Any, crop_name: str) -> SensorDiagnosticRead:
    """Classify a seven-in-one sensor reading using coffee reference ranges.

    Sensor results are intentionally preliminary. They never produce fertilizer
    or liming doses and remain low-confidence until calibration, repeatability,
    and laboratory-comparison data are available.
    """
    ensure_supported_crop(crop_name)
    _validate_reading(reading)

    parameters: list[DiagnosticParameterRead] = []
    warnings = [
        "Diagnóstico preliminar de sensor con confianza baja; no sustituye un "
        "análisis de laboratorio.",
        "No recomendar cal, Ca, Mg, S, micronutrientes u orgánicos únicamente "
        "con esta lectura.",
    ]

    for field, parameter_id in READING_FIELD_MAP.items():
        value = float(getattr(reading, field))
        reference = SOIL_REFERENCE_RANGES[parameter_id]
        level = classify(parameter_id, value)
        parameters.append(
            DiagnosticParameterRead(
                parameter=field,
                label=reference.label_es,
                value=value,
                unit=reference.unit,
                level=level,
                message=_LEVEL_MESSAGES[level],
                reference=DiagnosticRangeRead(
                    optimal_min=reference.optimal_min,
                    optimal_max=reference.optimal_max,
                    deficient_below=reference.deficient_below,
                    critical_above=reference.critical_above,
                    reference_method=reference.method,
                    reference_confidence=reference.confidence,
                ),
            )
        )
        warnings.extend(_parameter_warnings(field, level))

    return SensorDiagnosticRead(
        reading_id=reading.id,
        parcel_id=reading.parcel_id,
        recorded_at=reading.recorded_at,
        crop=crop_name,
        engine_version=ENGINE_VERSION,
        reference_source=REFERENCE_SOURCE,
        context=SensorContextRead(
            temperature_c=float(reading.temperature),
            humidity_pct=float(reading.humidity),
        ),
        parameters=parameters,
        warnings=list(dict.fromkeys(warnings)),
    )
