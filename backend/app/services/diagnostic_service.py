from collections.abc import Mapping
from typing import Any

from app.schemas.diagnostic import (
    DiagnosticParameterRead,
    DiagnosticRangeRead,
    SensorContextRead,
    SensorDiagnosticRead,
    SoilLevel,
)
from app.services.agronomic_config import AgronomicEngineConfig, SoilRangeConfig


ENGINE_VERSION = "sensor-diagnostic-1.0.0"
_READING_FIELD_MAP = {
    "nitrogen": "nitrate_n",
    "phosphorus": "phosphate_p",
    "potassium": "potassium",
    "ec": "ec",
    "ph": "ph",
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


class InvalidDiagnosticReadingError(ValueError):
    pass


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


def _classify(reference: SoilRangeConfig, value: float) -> SoilLevel:
    if reference.deficient_below is not None and value < reference.deficient_below:
        return SoilLevel.DEFICIENT
    if reference.critical_above is not None and value >= reference.critical_above:
        return SoilLevel.CRITICAL
    if reference.optimal_max is not None and value > reference.optimal_max:
        return SoilLevel.HIGH
    if reference.optimal_min is not None and value < reference.optimal_min:
        return SoilLevel.DEFICIENT
    return SoilLevel.OPTIMAL


def diagnose_sensor_reading(
    reading: Any,
    crop_name: str,
    config: AgronomicEngineConfig,
) -> SensorDiagnosticRead:
    """Classify a seven-in-one sensor reading using coffee reference ranges.

    Sensor results are intentionally preliminary. They never produce fertilizer
    or liming doses and remain low-confidence until calibration, repeatability,
    and laboratory-comparison data are available.
    """
    _validate_reading(reading)

    parameters: list[DiagnosticParameterRead] = []
    warnings = [
        "Diagnóstico preliminar de sensor con confianza baja; no sustituye un "
        "análisis de laboratorio.",
        "No recomendar cal, Ca, Mg, S, micronutrientes u orgánicos únicamente "
        "con esta lectura.",
    ]

    for field, parameter_id in _READING_FIELD_MAP.items():
        value = float(getattr(reading, field))
        reference = config.soil_ranges[parameter_id]
        level = _classify(reference, value)
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
        reference_source=(
            f"{config.reference_source} ({config.reference_key} "
            f"v{config.reference_version})"
        ),
        context=SensorContextRead(
            temperature_c=float(reading.temperature),
            humidity_pct=float(reading.humidity),
        ),
        parameters=parameters,
        warnings=list(dict.fromkeys(warnings)),
    )
