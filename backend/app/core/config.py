from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    ENV: str = "development"
    DEBUG: bool = True

    DATABASE_URL: str
    DB_POOL_SIZE: int = 10

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
