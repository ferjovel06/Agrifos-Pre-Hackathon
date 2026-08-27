from app.models import Alert, Farm
from app.schemas.weather import WeatherForecastRead


FERTILIZATION_RISK_THRESHOLD = 0.6
HEAT_WARNING_C = 37.0
HEAT_CRITICAL_C = 42.0


def rainfall_risk(precipitation_mm: float) -> float:
    if precipitation_mm <= 10:
        return 0.0
    if precipitation_mm <= 50:
        return (precipitation_mm - 10) / 40
    return 1.0


def evaluate_climate_alerts(
    farm: Farm,
    forecast: WeatherForecastRead,
) -> list[Alert]:
    alerts: list[Alert] = []
    first_48_hours = forecast.daily[:2]
    if first_48_hours:
        precipitation = sum(day.precipitation_mm for day in first_48_hours)
        risk = rainfall_risk(precipitation)
        if risk > FERTILIZATION_RISK_THRESHOLD:
            potential_loss_pct = risk * 50
            alerts.append(
                Alert(
                    farm_id=farm.id,
                    parcel_id=None,
                    type="weather_fertilization",
                    title="Posponer fertilización",
                    message=(
                        f"Se pronostican {precipitation:.1f} mm de lluvia en "
                        "las próximas 48 horas. Evita aplicar fertilizantes "
                        "solubles; la pérdida potencial se estima en "
                        f"{potential_loss_pct:.0f}%."
                    ),
                    severity="critical" if risk >= 0.9 else "warning",
                    event_date=first_48_hours[0].date,
                    risk_score=round(risk, 3),
                    is_active=True,
                )
            )

    for day in forecast.daily:
        if day.temperature_max_c < HEAT_WARNING_C:
            continue
        critical = day.temperature_max_c >= HEAT_CRITICAL_C
        alerts.append(
            Alert(
                farm_id=farm.id,
                parcel_id=None,
                type="weather_heat",
                title=(
                    "Estrés térmico crítico"
                    if critical
                    else "Riesgo de estrés térmico"
                ),
                message=(
                    f"La temperatura máxima prevista es "
                    f"{day.temperature_max_c:.1f} °C. "
                    + (
                        "Prioriza sombra, disponibilidad de agua y evita "
                        "labores que aumenten el estrés del cultivo."
                        if critical
                        else "Vigila la humedad del suelo y la exposición del cultivo."
                    )
                ),
                severity="critical" if critical else "warning",
                event_date=day.date,
                risk_score=(
                    1.0
                    if critical
                    else round((day.temperature_max_c - HEAT_WARNING_C) / 5, 3)
                ),
                is_active=True,
            )
        )

    return alerts
