from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.config import settings
from app.routers import (
    alerts,
    crops,
    diagnostic,
    farms,
    fertilization,
    lab_analysis,
    parcels,
    phenology,
    readings,
    users,
    varieties,
    weather,
)

app = FastAPI(
    title="Agrifos API",
    version="0.1.0",
    debug=settings.APP_DEBUG,
)

if settings.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(alerts.router)
app.include_router(users.router)
app.include_router(readings.router)
app.include_router(farms.router)
app.include_router(parcels.router)
app.include_router(crops.router)
app.include_router(varieties.router)
app.include_router(phenology.router)
app.include_router(diagnostic.router)
app.include_router(fertilization.router)
app.include_router(lab_analysis.router)
app.include_router(weather.router)


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}


@app.get("/health/db")
async def health_db(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("SELECT 1"))
    return {"database": "ok", "result": result.scalar()}
