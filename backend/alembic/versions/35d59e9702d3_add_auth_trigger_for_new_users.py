"""add auth trigger for new users

Revision ID: 35d59e9702d3
Revises: 6be214854654
Create Date: 2026-08-07 14:26:35.193085

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '35d59e9702d3'
down_revision: Union[str, None] = '6be214854654'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("""
        create function public.handle_new_user()
        returns trigger as $$
        begin
          insert into public.users (id, name, email, role)
          values (new.id, coalesce(new.raw_user_meta_data->>'name', ''), new.email, 'farmer');
          return new;
        end;
        $$ language plpgsql security definer;
    """)
    op.execute("""
        create trigger on_auth_user_created
          after insert on auth.users
          for each row execute procedure public.handle_new_user();
    """)


def downgrade() -> None:
    op.execute("drop trigger if exists on_auth_user_created on auth.users;")
    op.execute("drop function if exists public.handle_new_user();")