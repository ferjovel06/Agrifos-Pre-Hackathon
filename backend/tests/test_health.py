import unittest
from unittest.mock import AsyncMock, Mock

from fastapi.testclient import TestClient

from app.db.session import get_db
from app.main import app


class HealthEndpointTests(unittest.TestCase):
    def test_root_endpoint_presents_api_resources(self):
        response = TestClient(app).get("/")

        self.assertEqual(response.status_code, 200)
        self.assertIn("text/html", response.headers["content-type"])
        self.assertIn("Agrifos API", response.text)
        self.assertIn('href="/docs"', response.text)
        self.assertIn('href="/health"', response.text)
        self.assertIn('href="/health/db"', response.text)
        self.assertIn("Authorization: Bearer", response.text)

    def test_health_endpoint_reports_service_is_running(self):
        response = TestClient(app).get("/health")

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["status"], "healthy")
        self.assertEqual(payload["service"], "agrifos-api")
        self.assertEqual(payload["version"], app.version)
        self.assertIn("timestamp", payload)

    def test_database_health_reports_latency(self):
        database = AsyncMock()
        result = Mock()
        result.scalar.return_value = 1
        database.execute.return_value = result

        async def override_database():
            yield database

        app.dependency_overrides[get_db] = override_database
        try:
            response = TestClient(app).get("/health/db")
        finally:
            app.dependency_overrides.clear()

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["status"], "healthy")
        self.assertEqual(payload["database"], "postgresql")
        self.assertIn("latency_ms", payload)
        self.assertIn("timestamp", payload)

    def test_database_health_returns_sanitized_service_unavailable(self):
        database = AsyncMock()
        database.execute.side_effect = RuntimeError("database credentials")

        async def override_database():
            yield database

        app.dependency_overrides[get_db] = override_database
        try:
            response = TestClient(app).get("/health/db")
        finally:
            app.dependency_overrides.clear()

        self.assertEqual(response.status_code, 503)
        payload = response.json()
        self.assertEqual(payload["status"], "unhealthy")
        self.assertEqual(payload["database"], "postgresql")
        self.assertNotIn("credentials", response.text)


if __name__ == "__main__":
    unittest.main()
