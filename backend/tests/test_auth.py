import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import jwt
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.core.auth import get_current_user


class CurrentUserAuthenticationTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.credentials = HTTPAuthorizationCredentials(
            scheme="Bearer",
            credentials="test-token",
        )
        self.db = AsyncMock()

    async def test_provisions_missing_application_profile_from_verified_claims(self):
        expected_user = object()
        claims = {
            "sub": "ca05a7a9-3e5b-4e11-9415-3d403634ce00",
            "email": "farmer@example.com",
            "user_metadata": {"name": "Ana Productora"},
        }

        with (
            patch(
                "app.core.auth.asyncio.to_thread",
                new=AsyncMock(return_value=SimpleNamespace(key="public-key")),
            ) as to_thread,
            patch("app.core.auth.jwt.decode", return_value=claims),
            patch(
                "app.core.auth.user_repo.get_or_create_user",
                new=AsyncMock(return_value=expected_user),
            ) as get_or_create,
        ):
            result = await get_current_user(self.credentials, self.db)

        self.assertIs(result, expected_user)
        to_thread.assert_awaited_once()
        get_or_create.assert_awaited_once_with(
            self.db,
            user_id=claims["sub"],
            email=claims["email"],
            name="Ana Productora",
        )

    async def test_reports_jwks_outage_without_blocking_the_event_loop(self):
        with patch(
            "app.core.auth.asyncio.to_thread",
            new=AsyncMock(
                side_effect=jwt.PyJWKClientConnectionError("JWKS unavailable")
            ),
        ):
            with self.assertRaises(HTTPException) as raised:
                await get_current_user(self.credentials, self.db)

        self.assertEqual(raised.exception.status_code, 503)


if __name__ == "__main__":
    unittest.main()
