from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    ENV: str = "development"
    APP_DEBUG: bool = True

    DATABASE_URL: str
    DB_POOL_SIZE: int = 10
    DB_POOL_RECYCLE_SECONDS: int = 300

    SUPABASE_URL: str
    WEATHER_API_BASE_URL: str = "https://api.open-meteo.com/v1"
    ALLOWED_ORIGINS: str = ""

    @property
    def cors_origins(self) -> list[str]:
        return [
            origin.strip()
            for origin in self.ALLOWED_ORIGINS.split(",")
            if origin.strip()
        ]

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
