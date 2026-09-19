import unittest
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import jwt
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.core.auth import get_current_user, get_verified_claims


class VerifiedClaimsTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.credentials = HTTPAuthorizationCredentials(
            scheme="Bearer",
            credentials="test-token",
        )

    async def test_returns_claims_from_a_valid_supabase_token(self):
        claims = {
            "sub": "ca05a7a9-3e5b-4e11-9415-3d403634ce00",
            "email": "farmer@example.com",
            "aal": "aal2",
        }

        with (
            patch(
                "app.core.auth.settings.SUPABASE_URL",
                "https://example.supabase.co/",
            ),
            patch(
                "app.core.auth.asyncio.to_thread",
                new=AsyncMock(return_value=SimpleNamespace(key="public-key")),
            ) as to_thread,
            patch("app.core.auth.jwt.decode", return_value=claims) as decode,
        ):
            result = await get_verified_claims(self.credentials)

        self.assertIs(result, claims)
        to_thread.assert_awaited_once()
        decode.assert_called_once_with(
            "test-token",
            "public-key",
            algorithms=["ES256"],
            audience="authenticated",
            issuer="https://example.supabase.co/auth/v1",
        )

    async def test_reports_jwks_outage_without_blocking_the_event_loop(self):
        with patch(
            "app.core.auth.asyncio.to_thread",
            new=AsyncMock(
                side_effect=jwt.PyJWKClientConnectionError("JWKS unavailable")
            ),
        ):
            with self.assertRaises(HTTPException) as raised:
                await get_verified_claims(self.credentials)

        self.assertEqual(raised.exception.status_code, 503)

    async def test_rejects_a_token_that_fails_jwt_validation(self):
        with (
            patch(
                "app.core.auth.asyncio.to_thread",
                new=AsyncMock(return_value=SimpleNamespace(key="public-key")),
            ),
            patch(
                "app.core.auth.jwt.decode",
                side_effect=jwt.InvalidTokenError("bad token"),
            ),
        ):
            with self.assertRaises(HTTPException) as raised:
                await get_verified_claims(self.credentials)

        self.assertEqual(raised.exception.status_code, 401)
        self.assertEqual(raised.exception.detail, "Invalid token.")


class CurrentUserAuthenticationTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.db = AsyncMock()
        self.user_id = "ca05a7a9-3e5b-4e11-9415-3d403634ce00"
        self.claims = {
            "sub": self.user_id,
            "email": "farmer@example.com",
            "aal": "aal1",
            "user_metadata": {"name": "Ana Productora"},
        }

    def set_verified_factor_exists(self, exists: bool) -> None:
        self.db.execute.return_value = SimpleNamespace(
            scalar_one=lambda: exists,
        )

    async def test_allows_aal1_when_user_has_not_enrolled_mfa(self):
        expected_user = object()
        self.set_verified_factor_exists(False)

        with patch(
            "app.core.auth.user_repo.get_or_create_user",
            new=AsyncMock(return_value=expected_user),
        ) as get_or_create:
            result = await get_current_user(self.claims, self.db)

        self.assertIs(result, expected_user)
        self.db.execute.assert_awaited_once()
        get_or_create.assert_awaited_once_with(
            self.db,
            user_id=self.user_id,
            email="farmer@example.com",
            name="Ana Productora",
        )

    async def test_missing_aal_is_treated_as_aal1(self):
        expected_user = object()
        claims = {key: value for key, value in self.claims.items() if key != "aal"}
        self.set_verified_factor_exists(False)

        with patch(
            "app.core.auth.user_repo.get_or_create_user",
            new=AsyncMock(return_value=expected_user),
        ):
            result = await get_current_user(claims, self.db)

        self.assertIs(result, expected_user)
        self.db.execute.assert_awaited_once()

    async def test_requires_mfa_for_aal1_user_with_verified_factor(self):
        self.set_verified_factor_exists(True)

        with patch(
            "app.core.auth.user_repo.get_or_create_user",
            new=AsyncMock(),
        ) as get_or_create:
            with self.assertRaises(HTTPException) as raised:
                await get_current_user(self.claims, self.db)

        self.assertEqual(raised.exception.status_code, 403)
        self.assertEqual(
            raised.exception.detail,
            {
                "code": "mfa_required",
                "message": "Complete MFA verification to continue.",
            },
        )
        get_or_create.assert_not_awaited()

    async def test_allows_aal2_without_querying_mfa_factors(self):
        expected_user = object()
        claims = {**self.claims, "aal": "aal2"}

        with patch(
            "app.core.auth.user_repo.get_or_create_user",
            new=AsyncMock(return_value=expected_user),
        ) as get_or_create:
            result = await get_current_user(claims, self.db)

        self.assertIs(result, expected_user)
        self.db.execute.assert_not_awaited()
        get_or_create.assert_awaited_once()

    async def test_rejects_unknown_authentication_level(self):
        claims = {**self.claims, "aal": "aal3"}

        with patch(
            "app.core.auth.user_repo.get_or_create_user",
            new=AsyncMock(),
        ) as get_or_create:
            with self.assertRaises(HTTPException) as raised:
                await get_current_user(claims, self.db)

        self.assertEqual(raised.exception.status_code, 401)
        self.db.execute.assert_not_awaited()
        get_or_create.assert_not_awaited()

    async def test_rejects_missing_identity_claims(self):
        claims = {"sub": self.user_id, "aal": "aal2"}

        with self.assertRaises(HTTPException) as raised:
            await get_current_user(claims, self.db)

        self.assertEqual(raised.exception.status_code, 401)
        self.db.execute.assert_not_awaited()


if __name__ == "__main__":
    unittest.main()
