from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    ENV: str = "development"
    APP_DEBUG: bool = True

    DATABASE_URL: str
    DB_POOL_SIZE: int = 10
    DB_POOL_RECYCLE_SECONDS: int = 300

    SUPABASE_URL: str
    WEATHER_API_BASE_URL: str = "https://api.open-meteo.com/v1"
    WEATHER_FALLBACK_API_BASE_URL: str = (
        "https://api.met.no/weatherapi/locationforecast/2.0"
    )
    WEATHER_FALLBACK_USER_AGENT: str = (
        "Agrifos/0.1 https://github.com/ferjovel06/agrifos"
    )
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
