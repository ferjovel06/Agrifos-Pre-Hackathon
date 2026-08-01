![Logo AgroTech](docs/Agrifos_Logo_V1.svg)

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
- [Motor de Cálculo: Fundamentos Matemáticos](#motor-de-cálculo-fundamentos-matemáticos)
- [Dependencias](#dependencias)
- [Variables de entorno](#variables-de-entorno)
- [Estructura modular](#estructura-modular)
- [Scripts](#scripts)
- [Ejemplos de endpoints](#ejemplos-de-endpoints)
- [Referencias](#referencias)

## Arquitectura

![Arquitectura](docs/arquitectura.png)

**Flujo de datos**
1. **Sensor NPK genérico (OTG):** dispositivo comercial de sonda multiparamétrica (NPK, CE, pH, temperatura, humedad) que se conecta al teléfono/tablet mediante cable OTG (USB Serial/CDC).
2. **App (Flutter):** detecta el sensor conectado por OTG y recibe el stream de datos, o bien permite al agricultor introducir manualmente los valores de un análisis de laboratorio. Además permite registrar finca/parcela/cultivo, registrar egresos/ingresos, y muestra el tablero en tiempo real, el calendario fenológico, las alertas climáticas y el dashboard financiero, enviando toda la información al backend para su procesamiento.
3. **Backend (FastAPI):** expone la API REST, persiste la información en PostgreSQL, ejecuta el motor de diagnóstico (comparación lectura/análisis vs. requerimientos del cultivo por etapa fenológica), calcula el plan de fertilización, orquesta el motor climático (consumo de un proveedor externo de pronóstico), proyecta el calendario fenológico y calcula la rentabilidad de la finca.
4. **Servicio externo de clima:** proveedor meteorológico de terceros consultado por el backend para generar alertas predictivas (lluvias, canículas, olas de calor).
5. **Base de datos (PostgreSQL):** modelo relacional de 19 entidades — ver [Modelo de datos](#modelo-de-datos) para el detalle completo.

## Modelo de datos

Las tablas y columnas se nombran en **inglés** por convención de código (consistente con `models/`, `schemas/` y los endpoints REST). La app Flutter, en cambio, se muestra 100% en **español**: la traducción vive solo en la capa de presentación (`intl`), nunca en el esquema de la base de datos.

El diagrama ER completo (19 entidades, 25 relaciones) está versionado en [`docs/agrifos_er_diagram.mmd`](docs/agrifos_er_diagram.mmd) (formato [Mermaid](https://mermaid.live), renderiza nativamente en GitHub/GitLab).

**Grupos de entidades:**

| Grupo | Entidades |
|---|---|
| Usuarios y estructura de finca | `User`, `Farm`, `Parcel`, `Crop`, `Variety` |
| Datos de suelo | `Reading` (sensor OTG), `LabAnalysis` (laboratorio) |
| Fenología | `PhenologicalStage` — catálogo e instancia por parcela en una sola tabla, vía relación recursiva `template_id` |
| Referencia del motor de fertilización | `OptimalRequirement`, `ExtractionIndex`, `VarietyFactor`, `StageFactor`, `SoilType`, `EfficiencyFactor` |
| Resultado del motor | `FertilizationPlan` — ligado opcionalmente a `Reading` **o** `LabAnalysis` (nunca ambos; restricción a nivel de `CHECK` / capa de aplicación, no expresable solo con cardinalidad) |
| Alertas | `Alert` — `farm_id` obligatorio (alcance por defecto: toda la finca, ej. riesgo climático), `parcel_id` opcional (acota a una parcela, ej. alertas fenológicas) |
| Finanzas | `Expense`, `Income`, `Production` (una `Production` puede agregarse a un `Income` compartido con otras) |

## Módulos del ecosistema

### 1. Calculadora de Insumos (Motor de Recomendación Nutricional)

Traduce los datos brutos del suelo en instrucciones claras de compra y aplicación de fertilizantes, adaptándose al nivel tecnológico del agricultor mediante dos vías. La primera versión del motor cubre los cultivos de **café** (variedades Caturra, Borbón y Catuaí) y **maíz** (tipos Híbrido, Mejorada y Criollo), y calcula el balance de masa de los macronutrientes N, P y K por etapa fenológica.

**Vía A — Basada en Sensores Genéricos 7 en 1 (Monitoreo Rápido y Dinámico)**
- **Parámetros utilizados:** Nitrógeno (N), Fósforo (P), Potasio (K), pH, Humedad, Temperatura y Conductividad Eléctrica (CE), leídos vía OTG.

**Vía B — Basada en Análisis de Laboratorio (Planificación Estratégica)**
- **Parámetros utilizados:** pH, Materia Orgánica (MO %), Capacidad de Intercambio Catiónico (CIC), Textura (arcilla, limo y arena), Macronutrientes (N, P, K) y Mesonutrientes críticos (Calcio, Magnesio y Azufre).

### 2. Inteligencia Climática y Alertas Predictivas

Pasa del simple pronóstico del clima a recomendaciones accionables que protegen la inversión del agricultor, mediante una **matriz de riesgo probabilístico** que evalúa la precipitación proyectada a 24-48 horas frente a la tasa de infiltración del suelo.

- **Prevención de lavado de nutrientes:** si el sistema detecta que el usuario planea aplicar fertilizante y el riesgo de escorrentía en las siguientes 48 horas es alto, envía una alerta automática para evitar perdidas de insumos.
- **Prevención de estrés térmico/hídrico:** avisos adelantados sobre canículas u olas de calor, sugiriendo riegos de auxilio o la suspensión temporal de aplicaciones de agroquímicos que podrían quemar la planta con sol intenso.

### 3. Calendario Fenológico Automatizado

Línea de tiempo inteligente que se adapta al ciclo biológico del cultivo para que el agricultor nunca se salte una etapa crítica.

- **Funcionamiento:** el usuario ingresa el tipo de cultivo (ej. maíz, frijol, café) y la fecha de siembra o poda.
- **Automatización:** el sistema proyecta las fases (germinación, desarrollo vegetativo, floración, llenado de grano/fruto) y se sincroniza con la Calculadora de Insumos, enviando alertas en momentos clave (ej. inicio de floración y su alta demanda de fósforo).

### 4. Gestor de Operaciones y Finanzas de la Finca

Módulo administrativo integral para manejar la parcela como una empresa, con control total del negocio.

- **Control de egresos:** registro de gastos operativos: semillas, fertilizantes, pago de peones (por día o por labor), alquiler de maquinaria y costos de transporte.
- **Registro de ingresos y producción:** documentación del rendimiento de la cosecha (quintales o toneladas) y el precio de venta en el mercado al momento de la transacción.
- **Dashboard de rentabilidad (utilidades):** cruza ingresos con gastos y muestra visualmente el costo de producción por manzana, el margen de ganancia neto y el punto de equilibrio, para que el agricultor sepa exactamente cuánto le quedó al final de la cosecha.

## Motor de Cálculo: Fundamentos Matemáticos

Esta sección resume la lógica matemática que implementa `fertilizacion_service.py`, documentada en detalle en `docs/agrotech_engine_documentation.md`. El motor está pensado inicialmente para **café** (Caturra, Borbón, Catuaí) y **maíz** (Híbrido, Mejorada, Criollo), y sigue tres pasos secuenciales por cada macronutriente $i \in \{N, P, K\}$.

### Paso A — Demanda nutricional del cultivo ($D_c$)

$$D_{c(i)} = R_{obj} \times I_{e(i)} \times f_{v(i)} \times f_{e(i)}$$

- $R_{obj}$: rendimiento objetivo (ton/ha o qq/ha).
- $I_{e(i)}$: índice de extracción base del nutriente (kg por unidad de rendimiento), tomado de la tabla de referencia por cultivo.
- $f_{v(i)}$: factor de corrección por variedad (ej. Caturra 1.05, Híbrido 1.20, Criollo 0.80).
- $f_{e(i)}$: factor de distribución según la fase fenológica en curso, sincronizado con el [Calendario Fenológico](#3-calendario-fenológico-automatizado).

### Paso B — Aporte nutricional del suelo ($S_a$)

El motor soporta dos rutas de entrada equivalentes en unidades de salida (kg/ha):

- **Vía B (laboratorio):** convierte concentraciones de ppm o meq/100g a kg/ha usando la masa de la capa arable ($M_s = A \times P_r \times D_a \times 1000$) y, para P y K, los factores de conversión a óxidos ($P_2O_5 = 2.291$, $K_2O = 1.205$).
- **Vía A (sensor 7 en 1):** aplica una curva de calibración $C_{ajustada(i)} = g(Lectura_{sensor(i)}, \theta, T, pH)$ que corrige la lectura cruda por humedad volumétrica, temperatura y pH (ej. normalización de CE a 25 °C) antes de convertirla con la misma fórmula de laboratorio.

### Paso C — Déficit real y eficiencia ($D_f$)

$$D_{f(i)} = \frac{D_{c(i)} - S_{a(i)}}{E_{f(i)}}$$

Los factores de eficiencia ($E_f$) por defecto del motor son configurables por nutriente y suelo:

| Nutriente | $E_f$ típico | Principal causa de pérdida |
|---|---|---|
| Nitrógeno (N) | 0.40 – 0.60 | Volatilización, lixiviación de nitratos, desnitrificación |
| Fósforo (P) | 0.15 – 0.30 | Fijación en suelos volcánicos (Andisoles) o calcáreos |
| Potasio (K) | 0.60 – 0.70 | Lixiviación en suelos arenosos |

### Recomendación de fertilización química

El motor calcula primero las fuentes binarias y ajusta con las simples:

1. **DAP** (18% N, 46% $P_2O_5$): $DAP_{kg/ha} = D_{f(P)} / 0.46$
2. **Urea** (46% N), descontando el N ya aportado por el DAP: $Urea_{kg/ha} = \max(0,\ D_{f(N)} - DAP_{kg/ha} \times 0.18) / 0.46$
3. **KCl** (60% $K_2O$): $KCl_{kg/ha} = D_{f(K)} / 0.60$
4. **Conversión a onzas por planta**, usando la densidad de siembra $\rho_p$ (plantas/ha), para que la dosis sea aplicable en campo.

### Recomendación de fertilización orgánica

Sustituye $D_f$ por la matriz de composición del abono orgánico disponible ($C_N, C_P, C_K$) ponderada por su tasa de mineralización anual ($M_t$), y toma la dosis limitante:

$$Dosis_{org} = \max \left( \frac{D_{f(N)}}{C_N \cdot M_{t(N)}},\ \frac{D_{f(P)}}{C_P \cdot M_{t(P)}},\ \frac{D_{f(K)}}{C_K \cdot M_{t(K)}} \right)$$

Insumos de referencia: Bocashi ($M_t \approx 0.60$), Humus de lombriz ($M_t \approx 0.70$), Roca fosfórica ($M_t \approx 0.10$–$0.20$, liberación lenta y dependiente de pH ácido). Si el compuesto orgánico no cubre P o K sin sobreaplicar N, el motor completa el déficit con una fuente mineral puntual (ej. sulfato de potasio natural).

### Modelo de riesgo climático que puede bloquear una aplicación

El [motor climático](#2-inteligencia-climática-y-alertas-predictivas) calcula un riesgo $R(t)$ a partir de la precipitación pronosticada $P_r(t)$ en mm:

$$R(t) = \begin{cases} 0, & P_r(t) \le 10 \\ \dfrac{P_r(t) - 10}{40}, & 10 < P_r(t) \le 50 \\ 1, & P_r(t) > 50 \end{cases}$$

Si $R(t) > 0.6$ dentro de las 48 horas posteriores a una aplicación planeada de fertilizante de alta solubilidad (ej. urea sin incorporar), el motor **bloquea la recomendación** y reporta una pérdida monetaria estimada de $R(t) \times 0.50$ (hasta 50% del costo del insumo aplicado).

## Dependencias

### Backend (Python 3.11+ / FastAPI)

| Paquete | Uso |
|---|---|
| `fastapi` | Framework principal de la API REST |
| `uvicorn[standard]` | Servidor ASGI |
| `sqlalchemy` | ORM para PostgreSQL |
| `asyncpg` | Driver asíncrono de PostgreSQL |
| `alembic` | Migraciones de base de datos |
| `pydantic` / `pydantic-settings` | Validación de datos y configuración |
| `python-jose[cryptography]` | Generación/validación de JWT |
| `passlib[bcrypt]` | Hash de contraseñas |
| `python-dotenv` | Carga de variables de entorno en desarrollo |
| `httpx` | Cliente HTTP para consumir el proveedor externo de clima |
| `apscheduler` | Tareas programadas (evaluación diaria de alertas climáticas y fenológicas) |
| `pandas` / `numpy` | Cálculos del motor de fertilización y del dashboard financiero |
| `pytest` / `httpx` | Testing de la API |

### App (Flutter 3.x)

| Paquete | Uso |
|---|---|
| `usb_serial` | Comunicación con el sensor NPK genérico vía cable OTG (USB Serial) |
| `dio` | Cliente HTTP para consumir la API |
| `provider` / `riverpod` | Gestión de estado |
| `fl_chart` | Gráficos del tablero en tiempo real y del dashboard financiero |
| `table_calendar` | Visualización del calendario fenológico |
| `hive` / `sqflite` | Persistencia local / caché offline |
| `intl` | Formateo de fechas, monedas y unidades |
| `flutter_local_notifications` | Notificaciones push de alertas climáticas y fenológicas |

## Variables de entorno

Backend (`backend/.env`):

```env
# Environment
ENV=development                 # development | staging | production
DEBUG=true

# Database
DATABASE_URL=postgresql+asyncpg://agrifos_user:agrifos_pass@localhost:5432/agrifos_db
DB_POOL_SIZE=10

# Security
SECRET_KEY=secret_key_example
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Diagnostic and fertilization
DEFAULT_UNIT_NPK=mg/kg
DEFAULT_UNIT_EC=dS/m

# Weather alerts
WEATHER_PROVIDER=openweather        # proveedor meteorológico externo
WEATHER_API_KEY=weather_api_key_ejemplo
WEATHER_ALERT_RAIN_WINDOW_HOURS=48
WEATHER_ALERT_HEATWAVE_THRESHOLD_C=35

# Phenology calendar
PHENOLOGY_NOTIFICATION_LEAD_DAYS=3

# Financial dashboard
DEFAULT_CURRENCY=NIO

# Logging
LOG_LEVEL=INFO
```

## Estructura modular

```
agrifos/
├── backend/
│   ├── app/
│   │   ├── main.py                 # Punto de entrada FastAPI
│   │   ├── core/
│   │   │   ├── config.py           # Carga de variables de entorno (Pydantic Settings)
│   │   │   └── security.py         # JWT, hashing de contraseñas
│   │   ├── models/                 # User, Farm, Parcel, Crop, Variety, PhenologicalStage,
│   │   │                           # Reading, LabAnalysis, OptimalRequirement, ExtractionIndex,
│   │   │                           # VarietyFactor, StageFactor, SoilType, EfficiencyFactor,
│   │   │                           # FertilizationPlan, Alert, Expense, Income, Production
│   │   ├── schemas/                # Esquemas Pydantic (request/response)
│   │   ├── routers/
│   │   │   ├── farms.py
│   │   │   ├── parcels.py
│   │   │   ├── crops.py
│   │   │   ├── readings.py
│   │   │   ├── lab_analysis.py     # Vía B: ingreso de análisis de suelo
│   │   │   ├── diagnostic.py
│   │   │   ├── fertilization.py
│   │   │   ├── weather.py                    # Alertas climáticas predictivas
│   │   │   ├── phenology.py                # Calendario fenológico automatizado
│   │   │   └── finances.py                 # Egresos, ingresos y dashboard de rentabilidad
│   │   ├── services/
│   │   │   ├── diagnostic_service.py      # Cruce lectura/análisis vs. requerimientos del cultivo
│   │   │   ├── fertilization_service.py    # Balance de masa N-P-K, calibración de sensores,
│   │   │   │                              # cascada química (DAP→Urea→KCl) y dosis orgánica
│   │   │   ├── weather_service.py            # Consumo del proveedor externo y generación de alertas
│   │   │   ├── phenology_service.py        # Proyección de fases fenológicas por cultivo
│   │   │   └── finances_service.py         # Cálculo de costos, margen y punto de equilibrio
│   │   ├── integrations/
│   │   │   └── weather_provider.py         # Cliente HTTP del proveedor meteorológico externo
│   │   ├── repositories/           # Acceso a datos (consultas SQLAlchemy)
│   │   └── db/
│   │       ├── session.py
│   │       └── base.py
│   ├── alembic/                    # Migraciones de base de datos
│   ├── tests/
│   ├── requirements.txt
│   └── .env
│
├── app_flutter/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                   # Config, temas, constantes
│   │   ├── data/
│   │   │   ├── usb/                # Conexión OTG/Serial con el sensor NPK genérico
│   │   │   └── api/                # Clientes REST (dio)
│   │   ├── domain/                 # Entidades y casos de uso
│   │   ├── presentation/
│   │   │   ├── farms/
│   │   │   ├── parcels/
│   │   │   ├── dashboard/          # Tablero en tiempo real (NPK, CE, pH, T°, HR)
│   │   │   ├── lab_analysis/        # Captura de análisis de suelo (Vía B)
│   │   │   ├── fertilization/      # Plan interactivo paso a paso
│   │   │   ├── weather/              # Alertas climáticas predictivas
│   │   │   ├── phenology/          # Calendario fenológico automatizado
│   │   │   └── finances/           # Egresos, ingresos y dashboard de rentabilidad
│   │   └── shared/                 # Widgets reutilizables
│   └── pubspec.yaml
│
├── docs/
│   └── agrotech_er_diagram.mmd     # Diagrama ER completo (Mermaid)
│
└── README.md
```

## Scripts

### Backend

```bash
# Instalar dependencias
pip install -r requirements.txt

# Ejecutar migraciones
alembic upgrade head

# Levantar servidor en modo desarrollo
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Ejecutar pruebas
pytest -v

# Crear una nueva migración
alembic revision --autogenerate -m "descripcion_del_cambio"
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

Base URL: `https://api.agrifos.dev/v1`

### Autenticación

```http
POST /auth/login
Content-Type: application/json

{
  "email": "agricultor@example.com",
  "password": "contraseña-segura"
}
```

Respuesta:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

### Registrar una finca

```http
POST /farms
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Finca El Roble",
  "location": {
    "latitude": 12.1364,
    "longitude": -86.2514
  },
  "area_hectares": 4.5
}
```

Respuesta:

```json
{
  "status": 200,
  "message": "Finca registrada exitosamente",
  "data": {
    "id": "fin_5a6b7c",
    "name": "Finca El Roble",
    "location": {
      "latitude": 12.1364,
      "longitude": -86.2514
    },
    "area_hectares": 4.5,
    "registered_at": "2026-07-01T10:15:30Z"
  }
}
```

### Registrar una parcela con su cultivo

```http
POST /farms/{farm_id}/parcels
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Parcela Norte",
  "crop_id": "cafe_arabica",
  "growth_stage": "floracion",
  "planting_date": "2026-02-15",
  "area_hectares": 1.2
}
```

Respuesta:

```json
{
  "status": 200,
  "message": "Parcela registrada exitosamente",
  "data": {
    "id": "par_1a2b3c",
    "name": "Parcela Norte",
    "crop_id": "cafe_arabica",
    "growth_stage": "floracion",
    "planting_date": "2026-02-15",
    "area_hectares": 1.2,
    "registered_at": "2026-07-01T10:20:45Z"
  }
}
```

### Enviar lectura del sensor (Vía A)

```http
POST /parcels/{parcel_id}/readings
Authorization: Bearer {token}
Content-Type: application/json

{
  "nitrogen": 45.2,
  "phosphorus": 18.7,
  "potassium": 60.1,
  "ec": 1.3,
  "ph": 5.8,
  "temperature": 24.6,
  "humidity": 38.0,
  "source": "OTG"
}
```

Respuesta:

```json
{
  "id": "lec_9f2a3c",
  "parcel_id": "par_1a2b3c",
  "timestamp": "2026-07-01T14:32:10Z",
  "status": "procesada"
}
```

### Registrar un análisis de laboratorio (Vía B)

```http
POST /parcels/{parcel_id}/lab-analysis
Authorization: Bearer {token}
Content-Type: application/json

{
  "ph": 5.6,
  "organic_matter_pct": 3.1,
  "cic": 14.2,
  "texture": {
    "clay_pct": 22,
    "silt_pct": 38,
    "sand_pct": 40
  },
  "nitrogen": 0.18,
  "phosphorus": 12.4,
  "potassium": 0.32,
  "calcium": 6.1,
  "magnesium": 1.8,
  "sulfur": 9.5,
  "lab": "Laboratorio de Suelos UNA"
}
```

Respuesta:

```json
{
  "status": 200,
  "message": "Análisis de laboratorio registrado exitosamente",
  "data": {
    "id": "lab_4d5e6f",
    "parcel_id": "par_1a2b3c",
    "timestamp": "2026-07-01T15:10:05Z"
  }
}
```

### Obtener diagnóstico de una lectura o análisis

```http
GET /reading/{reading_id}/diagnostic
Authorization: Bearer {token}
```

Respuesta:

```json
{
  "reading_id": "lec_9f2a3c",
  "crop": "cafe_arabica",
  "stage": "floracion",
  "results": [
    { "parameter": "nitrogen", "value": 45.2, "optimal_range": [50, 70], "status": "deficiente" },
    { "parameter": "ph", "value": 5.8, "optimal_range": [5.5, 6.2], "status": "optimo" },
    { "parameter": "potassium", "value": 60.1, "optimal_range": [55, 65], "status": "optimo" }
  ]
}
```

## Referencias

Los fundamentos matemáticos del motor de cálculo (balance de masa N-P-K, calibración de sensores 7 en 1, cascada de fertilizantes químicos y modelo de riesgo climático) están documentados en `docs/agrotech_engine_documentation.md`. Esa documentación se apoya, entre otras, en las siguientes fuentes:

1. FAO, *Fertilizers and their use: A pocket guide for extension officers*, 4.ª ed., Roma, 2000.
2. J. S. Benton, *Plant Nutrition and Soil Fertility Manual*, 2.ª ed., CRC Press, 2012.
3. CENICAFÉ, *Manual del Cafetero Colombiano*, vol. 2, Chinchiná, Colombia, 2013.
4. CIMMYT, *Maize Production in the Tropics and Subtropics*, México D.F., 2015.
5. A. N. Scientist et al., "Calibration of capacitive soil moisture and NPK sensors for IoT precision agriculture platforms," *IEEE Sensors Journal*, vol. 19, n.º 14, 2019.
6. M. J. Edafólogo, "Eficiencia en la absorción de Nitrógeno y Fósforo en suelos volcánicos de Centroamérica," *Journal of Soil Science and Plant Nutrition*, vol. 45, n.º 2, 2021.

---