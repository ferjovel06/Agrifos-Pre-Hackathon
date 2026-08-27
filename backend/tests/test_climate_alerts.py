import unittest
import uuid
from datetime import date, datetime, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

from fastapi import HTTPException

from app.routers import alerts as router
from app.models import Alert
from app.repositories.alert import sync_weather_alerts
from app.schemas.weather import (
    CurrentWeatherRead,
    DailyWeatherRead,
    WeatherForecastRead,
)
from app.services.climate_alert_service import (
    evaluate_climate_alerts,
    rainfall_risk,
)


def daily_weather(
    day: date,
    precipitation_mm: float = 0,
    temperature_max_c: float = 30,
) -> DailyWeatherRead:
    return DailyWeatherRead(
        date=day,
        weather_code=0,
        condition="Despejado",
        temperature_max_c=temperature_max_c,
        temperature_min_c=20,
        precipitation_mm=precipitation_mm,
        precipitation_probability_pct=20,
        reference_evapotranspiration_mm=3,
    )


def forecast(*days: DailyWeatherRead, farm_id=None) -> WeatherForecastRead:
    return WeatherForecastRead(
        farm_id=farm_id or uuid.uuid4(),
        farm_name="Finca El Edén",
        provider="Open-Meteo",
        latitude=12.1,
        longitude=-86.2,
        timezone="America/Managua",
        current=CurrentWeatherRead(
            observed_at=datetime(2026, 9, 1, 10),
            temperature_c=28,
            relative_humidity_pct=75,
            precipitation_mm=0,
            weather_code=0,
            condition="Despejado",
            wind_speed_kmh=8,
        ),
        daily=list(days),
    )


class ClimateAlertRuleTests(unittest.TestCase):
    def setUp(self):
        self.farm = SimpleNamespace(id=uuid.uuid4())
        self.first = date(2026, 9, 1)
        self.second = date(2026, 9, 2)

    def test_rainfall_risk_matches_documented_formula(self):
        self.assertEqual(rainfall_risk(10), 0)
        self.assertEqual(rainfall_risk(30), 0.5)
        self.assertEqual(rainfall_risk(50), 1)
        self.assertEqual(rainfall_risk(60), 1)

    def test_fertilization_alert_triggers_only_above_point_six(self):
        safe = forecast(
            daily_weather(self.first, precipitation_mm=17),
            daily_weather(self.second, precipitation_mm=17),
        )
        risky = forecast(
            daily_weather(self.first, precipitation_mm=20),
            daily_weather(self.second, precipitation_mm=15),
        )

        self.assertEqual(evaluate_climate_alerts(self.farm, safe), [])
        alerts = evaluate_climate_alerts(self.farm, risky)

        self.assertEqual(len(alerts), 1)
        self.assertEqual(alerts[0].type, "weather_fertilization")
        self.assertEqual(alerts[0].risk_score, 0.625)
        self.assertIn("35.0 mm", alerts[0].message)

    def test_heat_warning_and_critical_thresholds(self):
        result = evaluate_climate_alerts(
            self.farm,
            forecast(
                daily_weather(self.first, temperature_max_c=37),
                daily_weather(self.second, temperature_max_c=42),
            ),
        )

        self.assertEqual([alert.type for alert in result], [
            "weather_heat",
            "weather_heat",
        ])
        self.assertEqual(result[0].severity, "warning")
        self.assertEqual(result[1].severity, "critical")


class ClimateAlertRouterTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.user = SimpleNamespace(id=uuid.uuid4(), role="farmer")
        self.farm = SimpleNamespace(
            id=uuid.uuid4(),
            user_id=self.user.id,
            name="Finca El Edén",
            latitude=12.1,
            longitude=-86.2,
        )
        self.db = AsyncMock()
        self.forecast = forecast(
            daily_weather(date(2026, 9, 1), precipitation_mm=20),
            daily_weather(date(2026, 9, 2), precipitation_mm=15),
            farm_id=self.farm.id,
        )

    async def test_evaluates_and_persists_owned_farm_alerts(self):
        weather_service = SimpleNamespace(
            forecast=AsyncMock(return_value=self.forecast)
        )
        stored = SimpleNamespace(
            id=uuid.uuid4(),
            farm_id=self.farm.id,
            parcel_id=None,
            type="weather_fertilization",
            title="Posponer fertilización",
            message="Lluvia intensa",
            severity="warning",
            event_date=date(2026, 9, 1),
            risk_score=0.625,
            is_active=True,
            created_at=datetime.now(timezone.utc),
        )
        with (
            patch.object(
                router.farm_repo,
                "get_farm",
                AsyncMock(return_value=self.farm),
            ),
            patch.object(
                router.alert_repo,
                "sync_weather_alerts",
                AsyncMock(return_value=[stored]),
            ) as sync_mock,
        ):
            result = await router.evaluate_farm_alerts(
                farm_id=self.farm.id,
                days=7,
                current_user=self.user,
                db=self.db,
                weather_service=weather_service,
            )

        self.assertEqual(result.farm_id, self.farm.id)
        self.assertEqual(len(result.active_alerts), 1)
        weather_service.forecast.assert_awaited_once_with(self.farm, 7)
        sync_mock.assert_awaited_once()

    async def test_rejects_foreign_farm_before_requesting_weather(self):
        foreign_farm = SimpleNamespace(
            **{**self.farm.__dict__, "user_id": uuid.uuid4()}
        )
        weather_service = SimpleNamespace(forecast=AsyncMock())
        with patch.object(
            router.farm_repo,
            "get_farm",
            AsyncMock(return_value=foreign_farm),
        ):
            with self.assertRaises(HTTPException) as raised:
                await router.evaluate_farm_alerts(
                    farm_id=self.farm.id,
                    days=7,
                    current_user=self.user,
                    db=self.db,
                    weather_service=weather_service,
                )

        self.assertEqual(raised.exception.status_code, 403)
        weather_service.forecast.assert_not_awaited()


class ClimateAlertRepositoryTests(unittest.IsolatedAsyncioTestCase):
    async def test_updates_duplicate_and_deactivates_stale_alert(self):
        farm_id = uuid.uuid4()
        event_date = date(2026, 9, 1)
        existing = SimpleNamespace(
            type="weather_fertilization",
            event_date=event_date,
            title="Anterior",
            message="Anterior",
            severity="warning",
            risk_score=0.7,
            is_active=True,
        )
        stale = SimpleNamespace(
            type="weather_heat",
            event_date=date(2026, 9, 2),
            is_active=True,
        )
        candidate = Alert(
            farm_id=farm_id,
            parcel_id=None,
            type="weather_fertilization",
            title="Posponer fertilización",
            message="Pronóstico actualizado",
            severity="critical",
            event_date=event_date,
            risk_score=1,
            is_active=True,
        )
        result = MagicMock()
        result.scalars.return_value.all.return_value = [existing, stale]
        db = MagicMock()
        db.execute = AsyncMock(return_value=result)
        db.commit = AsyncMock()
        db.refresh = AsyncMock()

        synced = await sync_weather_alerts(db, farm_id, [candidate])

        self.assertEqual(synced, [existing])
        self.assertEqual(existing.title, "Posponer fertilización")
        self.assertEqual(existing.severity, "critical")
        self.assertFalse(stale.is_active)
        db.add.assert_not_called()
        db.commit.assert_awaited_once()


if __name__ == "__main__":
    unittest.main()
