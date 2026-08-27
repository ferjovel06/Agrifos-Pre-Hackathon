from fastapi import FastAPI, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
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

app = FastAPI(title="Agrifos API")

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


@app.get("/health/db")
async def health_db(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("SELECT 1"))
    return {"database": "ok", "result": result.scalar()}
