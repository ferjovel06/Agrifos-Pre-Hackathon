import uuid

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User


async def get_user(db: AsyncSession, user_id: uuid.UUID | str) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def list_users(db: AsyncSession, skip: int = 0, limit: int = 50) -> list[User]:
    result = await db.execute(select(User).offset(skip).limit(limit))
    return list(result.scalars().all())


async def create_user(db: AsyncSession, user: User) -> User:
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def get_or_create_user(
    db: AsyncSession,
    *,
    user_id: uuid.UUID | str,
    email: str,
    name: str,
) -> User:
    """Return the app profile, repairing it if the auth trigger missed it."""
    existing = await get_user(db, user_id)
    if existing is not None:
        return existing

    user = User(id=user_id, email=email, name=name, role="farmer")
    db.add(user)
    try:
        await db.commit()
        await db.refresh(user)
        return user
    except IntegrityError:
        # A concurrent request or the auth.users trigger may have inserted it.
        await db.rollback()
        existing = await get_user(db, user_id)
        if existing is not None:
            return existing
        raise


async def update_user(db: AsyncSession, user: User) -> User:
    await db.commit()
    await db.refresh(user)
    return user


async def delete_user(db: AsyncSession, user: User) -> None:
    await db.delete(user)
    await db.commit()
