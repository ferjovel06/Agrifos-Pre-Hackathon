import asyncio
import logging
from typing import Any

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_db
from app.models import User
from app.repositories import user as user_repo

bearer_scheme = HTTPBearer()

GLOBAL_READ_ROLES = frozenset({"admin", "auditor"})
WRITE_ROLES = frozenset({"admin", "farmer"})

logger = logging.getLogger(__name__)

_jwks_client = jwt.PyJWKClient(
    f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json",
    cache_keys=True,
    lifespan=3600,
    timeout=5,
)


async def get_verified_claims(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict[str, Any]:
    try:
        signing_key = await asyncio.to_thread(
            _jwks_client.get_signing_key_from_jwt,
            credentials.credentials,
        )

        return jwt.decode(
            credentials.credentials,
            signing_key.key,
            algorithms=["ES256"],
            audience="authenticated",
            issuer=f"{settings.SUPABASE_URL.strip('/')}/auth/v1",
    )
    except jwt.PyJWKClientConnectionError:
        logger.warning("Supabase signing keys are temporarily unavailable.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service temporarily unavailable.",
        )

    except jwt.PyJWTError as exc:
        logger.info("JWT validation failed: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token.",
        )


async def get_current_user(
    claims: dict[str, Any] = Depends(get_verified_claims),
    db: AsyncSession = Depends(get_db),
) -> User:
    user_id = claims.get("sub")
    email = claims.get("email")
    aal = claims.get("aal", "aal1")

    if not isinstance(user_id, str) or not isinstance(email, str):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token claims.",
        )

    if aal not in ("aal1", "aal2"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication level.",
        )

    # Preserve the current opt-in MFA behavior.
    if aal != "aal2":
        result = await db.execute(
            text(
                """
                SELECT EXISTS (
                    SELECT 1
                    FROM auth.mfa_factors
                    WHERE user_id = CAST(:user_id AS uuid)
                      AND status = 'verified'
                )
                """
            ),
            {"user_id": user_id},
        )

        if result.scalar_one():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "code": "mfa_required",
                    "message": "Complete MFA verification to continue.",
                },
            )

    metadata = claims.get("user_metadata")
    raw_name = metadata.get("name") if isinstance(metadata, dict) else None
    fallback_name = email.partition("@")[0] or "Usuario"
    name = (
        raw_name.strip()
        if isinstance(raw_name, str) and raw_name.strip()
        else fallback_name
    )

    return await user_repo.get_or_create_user(
        db,
        user_id=user_id,
        email=email,
        name=name[:150],
    )


def require_role(*roles: str):
    async def dependency(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not enough permissions.",
            )
        return user

    return dependency


def has_global_read_access(user: User) -> bool:
    """Return whether a user may inspect records owned by any farmer."""
    return user.role in GLOBAL_READ_ROLES


async def require_write_access(user: User = Depends(get_current_user)) -> User:
    """Reject read-only accounts before an endpoint can mutate domain data."""
    if user.role not in WRITE_ROLES:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This role has read-only access.",
        )
    return user
