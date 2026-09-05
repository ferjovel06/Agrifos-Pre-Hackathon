![Logo Agrifos](docs/Agrifos_Logo_V1.svg)

# 🌱 Sistema de Asistencia Agrícola Inteligente

Sistema de asistencia agrícola compuesto por una plataforma digital interactiva que combina dos fuentes de datos del suelo: un **sensor NPK genérico conectado vía cable OTG** y la **captura manual de análisis de laboratorio**. A través de la aplicación móvil, el agricultor registra su finca y perfila sus parcelas seleccionando el tipo de planta y su etapa de crecimiento. Al conectar el sensor mediante cable OTG, la aplicación despliega un tablero de control en tiempo real con los niveles de NPK, conductividad eléctrica, pH, temperatura y humedad; alternativamente, el agricultor puede introducir manualmente los resultados de un análisis de laboratorio para una planificación de fertilización más completa.

## Tabla de contenidos
- [Arquitectura](#arquitectura)
- [Modelo de datos](#modelo-de-datos)
- [Módulos del ecosistema](#módulos-del-ecosistema)
  - [1. Calculadora de Insumos](#1-calculadora-de-insumos-motor-de-recomendación-nutricional)
  - [2. Inteligencia Climática y Alertas Predictivas](#2-inteligencia-climática-y-alertas-predictivas)
  - [3. Calendario Fenológico Automatizado](#3-calendario-fenológico-automatizado)
  - [4. Gestor de Operaciones y Finanzas](#4-gestor-de-operaciones-y-finanzas-de-la-finca)
- [Documentación Técnica de Referencia](#documentación-técnica-de-referencia)
- [Motor de Cálculo](#motor-de-cálculo)
- [Dependencias](#dependencias)
- [Variables de entorno](#variables-de-entorno)
- [Estructura modular](#estructura-modular)
- [Scripts](#scripts)
- [Ejemplos de endpoints](#ejemplos-de-endpoints)
- [Referencias](#referencias)

## Arquitectura

![Arquitectura](docs/diagrams/architecture_diagram.png)

> El PNG muestra la arquitectura objetivo del producto.

**Flujo de datos**
1. **Sensor NPK genérico (OTG):** dispositivo comercial de sonda multiparamétrica (NPK, CE, pH, temperatura, humedad) que se conecta al teléfono/tablet mediante cable OTG (USB Serial/CDC).
2. **App (Flutter):** detecta el sensor conectado por OTG, permite capturar análisis de laboratorio y consume la API REST. Supabase Auth gestiona registro, confirmación de correo, sesiones, recuperación de contraseña y MFA TOTP. Planificación incluye calendario mensual/semanal por finca, pronóstico de 7 días y alertas climáticas. Finanzas conserva una pantalla de demostración.
3. **Backend (FastAPI):** valida los JWT de Supabase, aplica permisos por rol, persiste la información en PostgreSQL y expone los servicios de diagnóstico, fertilización, fenología y clima. Los modelos financieros existen, pero su router todavía no está publicado por la API.
4. **Servicio externo de clima:** proveedor meteorológico de terceros consultado por el backend para generar alertas predictivas (lluvias, canículas, olas de calor).
5. **Base de datos (PostgreSQL):** modelo relacional de 27 entidades, incluidas referencias agronómicas versionadas, etapas fenológicas normalizadas y recomendaciones de fertilización persistidas — ver [Modelo de datos](#modelo-de-datos) para el detalle completo.

## Modelo de datos
El diagrama ER completo del modelo (27 entidades, 41 relaciones) está versionado en [`docs/diagrams/er_diagrams/agrifos_er_diagram.mmd`](docs/diagrams/er_diagrams/agrifos_er_diagram.mmd) (formato [Mermaid](https://mermaid.live)). También se divide en vistas por módulo para facilitar su lectura:

- [Estructura de finca](docs/diagrams/er_diagrams/er_core_farm.mmd)
- [Datos de suelo](docs/diagrams/er_diagrams/er_soil_data.mmd)
- [Fenología](docs/diagrams/er_diagrams/er_phenology.mmd)
- [Referencias agronómicas](docs/diagrams/er_diagrams/er_agronomic_references.mmd)
- [Planes de fertilización](docs/diagrams/er_diagrams/er_fertilization_plans.mmd)
- [Alertas climáticas](docs/diagrams/er_diagrams/er_climate_alerts.mmd)
- [Finanzas](docs/diagrams/er_diagrams/er_finance.mmd)

**Grupos de entidades:**

| Grupo | Entidades |
|---|---|
| Usuarios y estructura de finca | `User`, `Farm`, `Parcel`, `Crop`, `Variety` |
| Datos de suelo | `Reading` (sensor OTG), `LabAnalysis` (laboratorio) |
| Fenología | `PhenologicalStageTemplate` define el ciclo estándar y las etapas reutilizables de cada cultivo; `ParcelPhenologicalStage` registra las fechas estimadas y reales de cada parcela |
| Referencias agronómicas versionadas | `AgronomicReferenceSet`, `SoilReferenceRange`, `FertilizerProduct`, `FertilizerProductNutrient`, `ApplicationScheduleRule`, `AgronomicParameter`, `OptimalRequirement`, `ExtractionIndex`, `VarietyFactor`, `StageFactor`, `SoilType`, `EfficiencyFactor` |
| Resultado del motor | `FertilizationPlan` y `FertilizationPlanItem` conservan la versión del motor, la fuente, los escenarios, los productos, las dosis y el calendario de aplicación generado |
| Alertas | `Alert` — `farm_id` obligatorio (alcance por defecto: toda la finca, ej. riesgo climático), `parcel_id` opcional (acota a una parcela, ej. alertas fenológicas) |
| Finanzas | `Expense`, `Income`, `Production` (una `Production` puede agregarse a un `Income` compartido con otras) |

## Módulos del ecosistema

### 1. Calculadora de Insumos (Motor de Recomendación Nutricional)

Traduce los datos del suelo en recomendaciones de fertilización mediante dos vías. El motor implementado está orientado a **café**`, y calcula el balance de N, P y K según el contexto fenológico.

**Vía A — Basada en Sensores Genéricos 7 en 1 (Monitoreo Rápido y Dinámico)**
- **Parámetros utilizados:** Nitrógeno (N), Fósforo (P), Potasio (K), pH, Humedad, Temperatura y Conductividad Eléctrica (CE), leídos vía OTG.

**Vía B — Basada en Análisis de Laboratorio (Planificación Estratégica)**
- **Parámetros utilizados:** pH, Materia Orgánica (MO %), Capacidad de Intercambio Catiónico (CIC), Textura (arcilla, limo y arena), Macronutrientes (N, P, K) y Mesonutrientes críticos (Calcio, Magnesio y Azufre).

### 2. Inteligencia Climática y Alertas Predictivas

**Implementado:** pronóstico por finca y evaluación de alertas de lluvia y calor. La pestaña **Planificación Climática** incluye:

- Calendario mensual/semanal, pronóstico de 7 días con filas de día, indicadores de lluvia y alertas, marcadores por fecha, detalle del día y alertas activas.
- El riesgo de fertilización suma la lluvia de los primeros dos días del pronóstico y recomienda posponer cuando el índice supera 0.6. Las alertas de calor empiezan en 37 °C y son críticas desde 42 °C.

**Pendiente:** eventos programados, riego y muestreo en calendario, matriz de infiltración y alertas de sequía/canícula.

### 3. Calendario Fenológico Automatizado

**Implementado:** catálogo de etapas por cultivo y registros por parcela con fecha estimada, fecha real y momento de selección. La app permite seleccionar la etapa actual al registrar o editar una parcela; la API permite crear, consultar, editar y eliminar registros fenológicos.

**Pendiente:** mostrar y gestionar esos hitos en Planificación, proyectar automáticamente el ciclo completo y emitir avisos fenológicos. El calendario actual presenta clima y alertas climáticas.

### 4. Gestor de Operaciones y Finanzas de la Finca

El alcance previsto es:

- **Control de egresos:** registro de gastos operativos: semillas, fertilizantes, pago de peones (por día o por labor), alquiler de maquinaria y costos de transporte.
- **Registro de ingresos y producción:** documentación del rendimiento de la cosecha (quintales o toneladas) y el precio de venta en el mercado al momento de la transacción.
- **Dashboard de rentabilidad (utilidades):** cruza ingresos con gastos y muestra visualmente el costo de producción por manzana, el margen de ganancia neto y el punto de equilibrio, para que el agricultor sepa exactamente cuánto le quedó al final de la cosecha.

## Documentación Técnica de Referencia

Los detalles completos del motor agronómico se distribuyen en los documentos de `docs/`:

| Documento | Contenido |
|---|---|
| [`agrifos_engine_documentation.md`](docs/agrifos_engine_documentation.md) | Ecuaciones matemáticas del motor de balance de masa N-P-K, calibración de sensores, cascada de fertilizantes químicos y modelo de riesgo climático |
| [`coffee_phenology_and_fertilization_engine.pdf`](docs/coffee_phenology_and_fertilization_engine.pdf) | Documento completo sobre fenología, motor de fertilización, ejemplos, validación, apéndices y referencias |
| [`coffee_soil_laboratory_parameters.pdf`](docs/coffee_soil_laboratory_parameters.pdf) | Documento completo de rangos de laboratorio, criterios de interpretación, implementación y referencias |
| [`guia_evaluador.md`](docs/guia_evaluador.md) | Instrucciones para activar el backend en Render, probar endpoints protegidos e instalar el APK |

## Motor de Cálculo

El motor agronómico combina los datos del suelo con el cultivo, la variedad, la etapa fenológica, la densidad de siembra y el rendimiento objetivo para estimar el balance nutricional de N, P y K. Sus rangos, parámetros, productos, factores y calendarios activos se cargan desde referencias agronómicas versionadas en PostgreSQL; el backend conserva temporalmente la configuración inmutable para evitar consultas repetidas y reutiliza planes idénticos mediante una huella determinista de sus entradas y resultados.

- **Entradas:** lecturas del sensor 7-en-1 o resultados de laboratorio, datos de la parcela y contexto fenológico.
- **Proceso:** normalización de unidades, evaluación del aporte del suelo, estimación del déficit y ajuste por eficiencia agronómica.
- **Salidas:** diagnóstico por parámetro y recomendaciones de fertilización expresadas en unidades aplicables en campo.
- **Alcance implementado:** café, con advertencias sobre calibración, métodos de laboratorio y límites de interpretación.

Las ecuaciones, factores, supuestos, ejemplos y referencias se documentan en [`docs/agrifos_engine_documentation.md`](docs/agrifos_engine_documentation.md). El detalle fenológico y los rangos de laboratorio están en [`docs/coffee_phenology_and_fertilization_engine.pdf`](docs/coffee_phenology_and_fertilization_engine.pdf) y [`docs/coffee_soil_laboratory_parameters.pdf`](docs/coffee_soil_laboratory_parameters.pdf).

## Dependencias

### Backend (Python 3.11+ / FastAPI)

| Paquete | Uso |
|---|---|
| `fastapi[standard]` | API REST y servidor ASGI |
| `sqlalchemy` | ORM para PostgreSQL |
| `asyncpg` | Driver asíncrono de PostgreSQL |
| `alembic` | Migraciones de base de datos |
| `pydantic` / `pydantic-settings` | Validación de datos y configuración |
| `pyjwt[crypto]` | Validación de JWT emitidos por Supabase Auth (JWKS/ES256) |
| `httpx` | Cliente HTTP para consumir el proveedor externo de clima |
| `psycopg2-binary` | Driver PostgreSQL usado por Alembic |

### App (Flutter)

| Paquete | Uso |
|---|---|
| `supabase_flutter` | Cliente de Supabase Auth (login, registro, recuperación de contraseña, persistencia de sesión) |
| `flutter_dotenv` | Carga de `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` desde `.env` |
| `http` | Cliente HTTP para consumir la API de FastAPI |
| `provider` | Gestión de estado |
| `flutter_svg` | Renderizado del isotipo/logotipo de la marca |
| `flutter_native_splash` (dev) | Generación del splash nativo de Android/iOS a partir de `assets/images/` |
| `flutter_serial_communication` | Comunicación con el sensor NPK vía OTG/Serial |
| `geolocator` / `geocoding` | Ubicación y geocodificación de fincas |
| `google_fonts` | Tipografías de la interfaz |
| `flutter_map` | Renderizado de mapas OpenStreetMap para ubicar fincas y parcelas |
| `latlong2` | Tipos de coordenadas geográficas para `flutter_map` |

## Variables de entorno

Backend (`backend/.env`):

```env
# Environment
ENV=development                 # development | staging | production
APP_DEBUG=true

# Database
DATABASE_URL=postgresql+asyncpg://postgres:example_password@127.0.0.1:54321/postgres

DB_POOL_SIZE=10
DB_POOL_RECYCLE_SECONDS=300

# Supabase
SUPABASE_URL=https://[project-ref].supabase.co

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Weather providers
WEATHER_API_BASE_URL=https://api.open-meteo.com/v1
WEATHER_FALLBACK_API_BASE_URL=https://api.met.no/weatherapi/locationforecast/2.0
WEATHER_FALLBACK_USER_AGENT=Agrifos/0.1 https://github.com/ferjovel06/agrifos
```

App Flutter (`app_flutter/.env`):

```env
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxxxxxxxxxxx
API_BASE_URL=https://agrifos-api.onrender.com
```

## Estructura modular

```
agrifos/
├── backend/
│   ├── app/
│   │   ├── main.py                 # Punto de entrada FastAPI
│   │   ├── core/
│   │   │   ├── config.py           # Carga de variables de entorno (Pydantic Settings)
│   │   │   └── auth.py             # Validación de JWT de Supabase (get_current_user, require_role)
│   │   ├── models/                 # User, Farm, Parcel, Crop, Variety, PhenologicalStageTemplate,
│   │   │                           # ParcelPhenologicalStage,
│   │   │                           # Reading, LabAnalysis, OptimalRequirement, ExtractionIndex,
│   │   │                           # VarietyFactor, StageFactor, SoilType, EfficiencyFactor,
│   │   │                           # FertilizationPlan, FertilizationPlanItem, Alert,
│   │   │                           # Expense, Income, Production
│   │   ├── schemas/                # Esquemas Pydantic (request/response)
│   │   ├── routers/
│   │   │   ├── users.py            # CRUD de perfil 
│   │   │   ├── farms.py
│   │   │   ├── parcels.py
│   │   │   ├── crops.py
│   │   │   ├── readings.py
│   │   │   ├── lab_analysis.py     # Vía B: ingreso de análisis de suelo
│   │   │   ├── diagnostic.py
│   │   │   ├── fertilization.py
│   │   │   ├── weather.py                    # Pronóstico por finca
│   │   │   ├── alerts.py                     # Evaluación y consulta de alertas
│   │   │   ├── phenology.py                # Calendario fenológico automatizado
│   │   │   └── finances.py                 # Borrador; router aún no publicado
│   │   ├── services/
│   │   │   ├── diagnostic_service.py      # Cruce lectura/análisis vs. requerimientos del cultivo
│   │   │   ├── fertilization_service.py    # Balance de masa N-P-K, calibración de sensores,
│   │   │   │                              # cascada química (DAP→Urea→KCl) y dosis orgánica
│   │   │   ├── weather_service.py            # Obtención y validación del pronóstico
│   │   │   ├── climate_alert_service.py      # Reglas de riesgo por lluvia y calor
│   │   │   ├── phenology_service.py        # Proyección de fases fenológicas por cultivo
│   │   ├── integrations/
│   │   │   └── weather_provider.py         # Cliente HTTP del proveedor meteorológico externo
│   │   ├── repositories/           # Acceso a datos (consultas SQLAlchemy)
│   │   └── db/
│   │       ├── session.py
│   │       └── base.py
│   ├── alembic/                    # Migraciones de base de datos
│   ├── tests/
│   ├── pyproject.toml              # Dependencias administradas con uv
│   ├── uv.lock
│   └── .env
│
├── app_flutter/
│   ├── assets/
│   │   ├── images/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                   # Config, temas, constantes
│   │   ├── data/
│   │   │   ├── sensor/             # Conexión OTG/Serial con el sensor NPK genérico
│   │   │   └── api/                # Repositorios y cliente REST (http)
│   │   ├── domain/                 # Entidades y casos de uso
│   │   ├── presentation/
│   │   │   ├── splash/
│   │   │   ├── auth/
│   │   │   ├── farm/               # Registro de fincas y parcelas
│   │   │   ├── sensor/             # Tablero NPK y diagnóstico
│   │   │   ├── lab_analysis/       # Captura de análisis de suelo (Vía B)
│   │   │   ├── planification/      # Calendario climático, pronóstico y alertas
│   │   │   ├── finance/            # Interfaz financiera
│   │   │   └── profile/            # Perfil, contraseña y MFA
│   │   └── shared/                 # Widgets reutilizables
│   ├── .env
│   └── pubspec.yaml
│
├── docs/
│   ├── diagrams/                  # Diagramas del sistema
│   │   ├── architecture_diagram.png
│   │   ├── activity_diagram.png
│   │   ├── class_diagram.svg
│   │   ├── use_case_diagram.svg
│   │   └── er_diagrams/           # Diagrama ER completo y vistas por módulo
│   └── guia_evaluador.md          # Prueba de API y APK
│
└── README.md
```

## Scripts

### Backend

```bash
# Instalar dependencias
uv sync --locked

# Ejecutar migraciones
uv run alembic upgrade head

# Levantar servidor en modo desarrollo
uv run fastapi dev app/main.py

# Ejecutar pruebas
uv run --with pytest pytest -v

# Crear una nueva migración
uv run alembic revision --autogenerate -m "descripcion_del_cambio"
```

### App Flutter

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo (dispositivo/emulador conectado)
flutter run

# Compilar APK de release
flutter build apk --release

# Compilar para web
flutter build web

# Ejecutar pruebas
flutter test
```

## Ejemplos de endpoints

Base URL desplegada: `https://agrifos-api.onrender.com`. La especificación completa y ejecutable está en [Swagger UI](https://agrifos-api.onrender.com/docs).

Los objetos de respuesta mostrados son abreviados para facilitar la lectura; Swagger contiene el contrato completo.

### Autenticación

El registro e inicio de sesión ocurren directamente contra **Supabase Auth** (ver [supabase.com/docs/guides/auth](https://supabase.com/docs/guides/auth)).

### Registrar una finca

```http
POST /farms
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Finca El Roble",
  "area_hectares": 4.5,
  "latitude": 12.1364,
  "longitude": -86.2514
}
```

Respuesta:

```json
{
  "id": "00000000-0000-0000-0000-000000000001",
  "user_id": "00000000-0000-0000-0000-000000000010",
  "name": "Finca El Roble",
  "area_hectares": 4.5,
  "latitude": 12.1364,
  "longitude": -86.2514,
  "created_at": "2026-08-29T10:15:30Z",
  "updated_at": "2026-08-29T10:15:30Z"
}
```

### Registrar una parcela con su cultivo

```http
POST /parcels
Authorization: Bearer {token}
Content-Type: application/json

{
  "farm_id": "00000000-0000-0000-0000-000000000001",
  "crop_id": "00000000-0000-0000-0000-000000000002",
  "variety_id": null,
  "name": "Parcela Norte",
  "area_hectares": 1.2,
  "plants_per_hectare": 5000,
  "planting_date": "2026-02-15"
}
```

Respuesta:

```json
{
  "id": "00000000-0000-0000-0000-000000000003",
  "farm_id": "00000000-0000-0000-0000-000000000001",
  "crop_id": "00000000-0000-0000-0000-000000000002",
  "variety_id": null,
  "name": "Parcela Norte",
  "area_hectares": 1.2,
  "plants_per_hectare": 5000,
  "planting_date": "2026-02-15",
  "created_at": "2026-08-29T10:20:45Z",
  "updated_at": "2026-08-29T10:20:45Z"
}
```

### Enviar lectura del sensor (Vía A)

```http
POST /readings
Authorization: Bearer {token}
Content-Type: application/json

{
  "parcel_id": "00000000-0000-0000-0000-000000000003",
  "nitrogen": 45.2,
  "phosphorus": 18.7,
  "potassium": 60.1,
  "ec": 1.3,
  "ph": 5.8,
  "temperature": 24.6,
  "humidity": 38.0
}
```

Respuesta:

```json
{
  "id": "00000000-0000-0000-0000-000000000004",
  "parcel_id": "00000000-0000-0000-0000-000000000003",
  "nitrogen": 45.2,
  "phosphorus": 18.7,
  "potassium": 60.1,
  "ec": 1.3,
  "ph": 5.8,
  "temperature": 24.6,
  "humidity": 38.0,
  "recorded_at": "2026-08-29T14:32:10Z",
  "diagnosis": { "source": "sensor", "parameters": [], "warnings": [] }
}
```

### Registrar un análisis de laboratorio (Vía B)

```http
POST /lab-analyses
Authorization: Bearer {token}
Content-Type: application/json

{
  "parcel_id": "00000000-0000-0000-0000-000000000003",
  "sample_code": "MUESTRA-001",
  "sampled_at": "2026-08-20T10:00:00Z",
  "depth_start_cm": 0,
  "depth_end_cm": 20,
  "ph": 5.6,
  "ph_method": "agua 1:2.5",
  "ec": 1.1,
  "ec_method": "extracto 1:5",
  "organic_matter_pct": 3.1,
  "cic": 14.2,
  "clay_pct": 22,
  "silt_pct": 38,
  "sand_pct": 40,
  "nitrogen": 0.18,
  "phosphorus": 12.4,
  "phosphorus_method": "Bray II",
  "potassium": 0.32,
  "potassium_method": "acetato de amonio",
  "calcium": 6.1,
  "magnesium": 1.8,
  "sulfur": 9.5,
  "lab": "Laboratorio de Suelos UNA"
}
```

Respuesta:

```json
{
  "id": "00000000-0000-0000-0000-000000000005",
  "parcel_id": "00000000-0000-0000-0000-000000000003",
  "sample_code": "MUESTRA-001",
  "recorded_at": "2026-08-29T15:10:05Z"
}
```

### Obtener diagnóstico de una lectura o análisis

```http
GET /diagnostics/readings/{reading_id}
Authorization: Bearer {token}
```

Respuesta:

```json
{
  "reading_id": "00000000-0000-0000-0000-000000000004",
  "parcel_id": "00000000-0000-0000-0000-000000000003",
  "crop": "cafe",
  "source": "sensor",
  "measurement_method": "seven_in_one_sensor",
  "overall_confidence": "low",
  "parameters": [],
  "warnings": []
}
```

## Referencias

Los fundamentos matemáticos del motor de cálculo (balance de masa N-P-K, calibración de sensores 7 en 1, cascada de fertilizantes químicos y modelo de riesgo climático) están documentados en `docs/agrifos_engine_documentation.md`. Esa documentación se apoya, entre otras, en las siguientes fuentes:

1. FAO, *Fertilizers and their use: A pocket guide for extension officers*, 4.ª ed., Roma, 2000.
2. J. S. Benton, *Plant Nutrition and Soil Fertility Manual*, 2.ª ed., CRC Press, 2012.
3. CENICAFÉ, *Manual del Cafetero Colombiano*, vol. 2, Chinchiná, Colombia, 2013.
4. CIMMYT, *Maize Production in the Tropics and Subtropics*, México D.F., 2015.

---
