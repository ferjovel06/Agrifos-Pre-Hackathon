from fastapi import FastAPI, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.routers import users, farms, parcels, crops, varieties, phenology

app = FastAPI(title="Agrifos API")

app.include_router(users.router)
app.include_router(farms.router)
app.include_router(parcels.router)
app.include_router(crops.router)
app.include_router(varieties.router)
app.include_router(phenology.router)


@app.get("/health/db")
async def health_db(db: AsyncSession = Depends(get_db)):
    result = await db.execute(text("SELECT 1"))
    return {"database": "ok", "result": result.scalar()}