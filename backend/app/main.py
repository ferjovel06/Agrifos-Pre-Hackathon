import logging
from datetime import UTC, datetime
from time import perf_counter

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
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

logger = logging.getLogger(__name__)

app = FastAPI(
    title="Agrifos API",
    version="1.0.0-beta.2",
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


@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def root():
    return f"""
    <!doctype html>
    <html lang="es">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Agrifos API</title>
        <style>
          :root {{
            color-scheme: light;
            --green: #285738;
            --green-dark: #173a25;
            --green-soft: #edf4ee;
            --brown: #4b241b;
            --paper: #fffdf9;
            --line: #dce6dd;
            --muted: #657068;
          }}
          * {{ box-sizing: border-box; }}
          body {{
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            padding: 32px 18px;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system,
              BlinkMacSystemFont, "Segoe UI", sans-serif;
            color: var(--brown);
            background:
              radial-gradient(circle at top right, #dcebdc 0, transparent 34%),
              linear-gradient(145deg, #f8f4ec, #eef5ef);
          }}
          main {{
            width: min(760px, 100%);
            padding: clamp(28px, 6vw, 56px);
            border: 1px solid rgba(40, 87, 56, 0.12);
            border-radius: 28px;
            background: rgba(255, 253, 249, 0.94);
            box-shadow: 0 24px 70px rgba(36, 62, 43, 0.14);
          }}
          .eyebrow {{
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 24px;
            color: var(--green);
            font-size: 0.82rem;
            font-weight: 750;
            letter-spacing: 0.12em;
            text-transform: uppercase;
          }}
          .dot {{
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: #42a35f;
            box-shadow: 0 0 0 5px rgba(66, 163, 95, 0.14);
          }}
          h1 {{
            margin: 0;
            color: var(--green-dark);
            font-size: clamp(2.6rem, 9vw, 5rem);
            letter-spacing: -0.055em;
            line-height: 0.94;
          }}
          .lead {{
            max-width: 590px;
            margin: 22px 0 30px;
            color: var(--muted);
            font-size: clamp(1rem, 2.5vw, 1.18rem);
            line-height: 1.65;
          }}
          .actions {{
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 34px;
          }}
          a {{ color: inherit; }}
          .button {{
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-height: 48px;
            padding: 0 21px;
            border: 1px solid var(--green);
            border-radius: 999px;
            color: var(--green);
            font-weight: 700;
            text-decoration: none;
          }}
          .button.primary {{
            color: white;
            background: var(--green);
          }}
          .button:hover {{ transform: translateY(-1px); }}
          .grid {{
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
          }}
          .card {{
            padding: 18px;
            border: 1px solid var(--line);
            border-radius: 17px;
            color: var(--green-dark);
            background: var(--green-soft);
            text-decoration: none;
          }}
          .card strong {{ display: block; margin-bottom: 5px; }}
          .card span {{ color: var(--muted); font-size: 0.88rem; }}
          .status {{
            display: inline-flex;
            align-items: center;
            gap: 7px;
          }}
          .status::before {{
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background: #8b948d;
            content: "";
          }}
          .status.healthy {{ color: var(--green); }}
          .status.healthy::before {{ background: #42a35f; }}
          .status.unhealthy {{ color: #a43c2f; }}
          .status.unhealthy::before {{ background: #c94c3d; }}
          .notice {{
            margin: 28px 0 0;
            padding-top: 22px;
            border-top: 1px solid var(--line);
            color: var(--muted);
            font-size: 0.9rem;
            line-height: 1.55;
          }}
          code {{ color: var(--green-dark); font-weight: 650; }}
          @media (max-width: 620px) {{
            .grid {{ grid-template-columns: 1fr; }}
            .button {{ width: 100%; }}
          }}
        </style>
      </head>
      <body>
        <main>
          <div class="eyebrow"><span class="dot"></span>Servicio operativo</div>
          <h1>Agrifos API</h1>
          <p class="lead">
            Backend de la plataforma de asistencia agr&iacute;cola inteligente
            Agrifos. Consulta y prueba los endpoints disponibles desde la
            documentaci&oacute;n interactiva.
          </p>
          <nav class="actions" aria-label="Documentaci&oacute;n de la API">
            <a class="button primary" href="/docs">Abrir Swagger UI</a>
            <a class="button" href="/redoc">Ver documentaci&oacute;n ReDoc</a>
          </nav>
          <section class="grid" aria-label="Recursos del servicio">
            <a class="card" href="/docs">
              <strong>Endpoints</strong>
              <span>Documentaci&oacute;n interactiva</span>
            </a>
            <a class="card" href="/health">
              <strong>API Health</strong>
              <span class="status" data-health="/health">Verificando servicio</span>
            </a>
            <a class="card" href="/health/db">
              <strong>Database Health</strong>
              <span class="status" data-health="/health/db">Verificando PostgreSQL</span>
            </a>
          </section>
          <p class="notice">
            Versi&oacute;n <code>{app.version}</code>. Los endpoints de negocio
            requieren un token de Supabase en el encabezado
            <code>Authorization: Bearer &lt;token&gt;</code>.
          </p>
        </main>
        <script>
          document.querySelectorAll("[data-health]").forEach(async (element) => {{
            try {{
              const response = await fetch(element.dataset.health);
              const result = await response.json();
              const healthy = response.ok && result.status === "healthy";
              element.classList.add(healthy ? "healthy" : "unhealthy");
              element.textContent = healthy
                ? (result.latency_ms === undefined
                    ? "Servicio disponible"
                    : `PostgreSQL disponible · ${{result.latency_ms}} ms`)
                : "Servicio no disponible";
            }} catch (_) {{
              element.classList.add("unhealthy");
              element.textContent = "No se pudo verificar";
            }}
          }});
        </script>
      </body>
    </html>
    """


@app.get("/health", tags=["health"])
async def health():
    return {
        "status": "healthy",
        "service": "agrifos-api",
        "version": app.version,
        "timestamp": datetime.now(UTC).isoformat(),
    }


@app.get(
    "/health/db",
    tags=["health"],
    responses={503: {"description": "PostgreSQL is unavailable"}},
)
async def health_db(db: AsyncSession = Depends(get_db)):
    started_at = perf_counter()
    timestamp = datetime.now(UTC).isoformat()

    try:
        result = await db.execute(text("SELECT 1"))
        if result.scalar() != 1:
            raise RuntimeError("Unexpected database health-check result.")
    except Exception as exc:
        logger.warning("Database health check failed: %s", type(exc).__name__)
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "database": "postgresql",
                "timestamp": timestamp,
            },
        )

    return {
        "status": "healthy",
        "database": "postgresql",
        "latency_ms": round((perf_counter() - started_at) * 1000, 2),
        "timestamp": timestamp,
    }
