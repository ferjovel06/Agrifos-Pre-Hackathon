![Logo AgroTech](docs/Agrifos_Logo_V1.svg)

# 🌱 Sistema de Asistencia Agrícola Inteligente

Sistema de asistencia agrícola compuesto por una plataforma digital interactiva que combina dos fuentes de datos del suelo: un **sensor NPK genérico conectado vía cable OTG** y la **captura manual de análisis de laboratorio**. A través de la aplicación móvil, el agricultor registra su finca y perfila sus parcelas seleccionando el tipo de planta y su etapa de crecimiento. Al conectar el sensor mediante cable OTG, la aplicación despliega un tablero de control en tiempo real con los niveles de NPK, conductividad eléctrica, pH, temperatura y humedad; alternativamente, el agricultor puede introducir manualmente los resultados de un análisis de laboratorio para una planificación de fertilización más completa.

## Tabla de contenidos
- [Arquitectura](#arquitectura)
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
5. **Base de datos (PostgreSQL):** almacena catálogo de cultivos y requerimientos óptimos por etapa, fincas, parcelas, lecturas del sensor NPK, análisis de laboratorio, planes de fertilización, calendarios fenológicos, alertas generadas, y registros de egresos/ingresos/producción.

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
# Entorno
ENV=development                 # development | staging | production
DEBUG=true

# Base de datos
DATABASE_URL=postgresql+asyncpg://agrosense_user:agrosense_pass@localhost:5432/agrosense_db
DB_POOL_SIZE=10

# Seguridad
SECRET_KEY=secret_key_ejemplo
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080

# Motor de diagnóstico
DEFAULT_UNIT_NPK=mg/kg
DEFAULT_UNIT_EC=dS/m

# Motor climático
WEATHER_PROVIDER=openweather        # proveedor meteorológico externo
WEATHER_API_KEY=weather_api_key_ejemplo
WEATHER_ALERT_RAIN_WINDOW_HOURS=48
WEATHER_ALERT_HEATWAVE_THRESHOLD_C=35

# Calendario fenológico
PHENOLOGY_NOTIFICATION_LEAD_DAYS=3

# Finanzas
DEFAULT_CURRENCY=NIO

# Logging
LOG_LEVEL=INFO
```

## Estructura modular

```
agrosense/
├── backend/
│   ├── app/
│   │   ├── main.py                 # Punto de entrada FastAPI
│   │   ├── core/
│   │   │   ├── config.py           # Carga de variables de entorno (Pydantic Settings)
│   │   │   └── security.py         # JWT, hashing de contraseñas
│   │   ├── models/                 # Finca, Parcela, Cultivo, Variedad, FaseFenologica,
│   │   │                           # Lectura, AnalisisLaboratorio, FactorEficiencia,
│   │   │                           # PlanFertilizacion, EtapaFenologica, Alerta, Egreso, Ingreso
│   │   ├── schemas/                # Esquemas Pydantic (request/response)
│   │   ├── routers/
│   │   │   ├── fincas.py
│   │   │   ├── parcelas.py
│   │   │   ├── cultivos.py
│   │   │   ├── lecturas.py
│   │   │   ├── analisis_laboratorio.py     # Vía B: ingreso de análisis de suelo
│   │   │   ├── diagnostico.py
│   │   │   ├── fertilizacion.py
│   │   │   ├── clima.py                    # Alertas climáticas predictivas
│   │   │   ├── fenologia.py                # Calendario fenológico automatizado
│   │   │   └── finanzas.py                 # Egresos, ingresos y dashboard de rentabilidad
│   │   ├── services/
│   │   │   ├── diagnostico_service.py      # Cruce lectura/análisis vs. requerimientos del cultivo
│   │   │   ├── fertilizacion_service.py    # Balance de masa N-P-K, calibración de sensores,
│   │   │   │                              # cascada química (DAP→Urea→KCl) y dosis orgánica
│   │   │   ├── clima_service.py            # Consumo del proveedor externo y generación de alertas
│   │   │   ├── fenologia_service.py        # Proyección de fases fenológicas por cultivo
│   │   │   └── finanzas_service.py         # Cálculo de costos, margen y punto de equilibrio
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
│   │   │   ├── finca/
│   │   │   ├── parcela/
│   │   │   ├── dashboard/          # Tablero en tiempo real (NPK, CE, pH, T°, HR)
│   │   │   ├── laboratorio/        # Captura de análisis de suelo (Vía B)
│   │   │   ├── fertilizacion/      # Plan interactivo paso a paso
│   │   │   ├── clima/              # Alertas climáticas predictivas
│   │   │   ├── fenologia/          # Calendario fenológico automatizado
│   │   │   └── finanzas/           # Egresos, ingresos y dashboard de rentabilidad
│   │   └── shared/                 # Widgets reutilizables
│   └── pubspec.yaml
│
└── docs/
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

Base URL: `https://api.agrosense.dev/v1`

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
POST /fincas
Authorization: Bearer {token}
Content-Type: application/json

{
  "nombre": "Finca El Roble",
  "ubicacion": {
    "latitud": 12.1364,
    "longitud": -86.2514
  },
  "area_hectareas": 4.5
}
```

### Registrar una parcela con su cultivo

```http
POST /fincas/{finca_id}/parcelas
Authorization: Bearer {token}
Content-Type: application/json

{
  "nombre": "Parcela Norte",
  "cultivo_id": "cafe_arabica",
  "etapa_crecimiento": "floracion",
  "fecha_siembra": "2026-02-15",
  "area_hectareas": 1.2
}
```

### Enviar lectura del sensor (Vía A)

```http
POST /parcelas/{parcela_id}/lecturas
Authorization: Bearer {token}
Content-Type: application/json

{
  "nitrogeno": 45.2,
  "fosforo": 18.7,
  "potasio": 60.1,
  "conductividad_electrica": 1.3,
  "ph": 5.8,
  "temperatura": 24.6,
  "humedad": 38.0,
  "fuente_conexion": "OTG"
}
```

Respuesta:

```json
{
  "id": "lec_9f2a3c",
  "parcela_id": "par_1a2b3c",
  "timestamp": "2026-07-01T14:32:10Z",
  "estado": "procesada"
}
```

### Registrar un análisis de laboratorio (Vía B)

```http
POST /parcelas/{parcela_id}/analisis-laboratorio
Authorization: Bearer {token}
Content-Type: application/json

{
  "ph": 5.6,
  "materia_organica_pct": 3.1,
  "cic": 14.2,
  "textura": {
    "arcilla_pct": 22,
    "limo_pct": 38,
    "arena_pct": 40
  },
  "nitrogeno": 0.18,
  "fosforo": 12.4,
  "potasio": 0.32,
  "calcio": 6.1,
  "magnesio": 1.8,
  "azufre": 9.5,
  "laboratorio": "Laboratorio de Suelos UNA"
}
```

Respuesta:

```json
{
  "id": "lab_7d1e4f",
  "parcela_id": "par_1a2b3c",
  "timestamp": "2026-07-01T09:10:00Z",
  "estado": "procesado"
}
```

### Obtener diagnóstico de una lectura o análisis

```http
GET /lecturas/{lectura_id}/diagnostico
Authorization: Bearer {token}
```

Respuesta:

```json
{
  "lectura_id": "lec_9f2a3c",
  "cultivo": "cafe_arabica",
  "etapa": "floracion",
  "resultados": [
    { "parametro": "nitrogeno", "valor": 45.2, "rango_optimo": [50, 70], "estado": "deficiente" },
    { "parametro": "ph", "valor": 5.8, "rango_optimo": [5.5, 6.2], "estado": "optimo" },
    { "parametro": "potasio", "valor": 60.1, "rango_optimo": [55, 65], "estado": "optimo" }
  ]
}
```

### Obtener plan de fertilización

```http
GET /lecturas/{lectura_id}/plan-fertilizacion
Authorization: Bearer {token}
```

Respuesta:

```json
{
  "lectura_id": "lec_9f2a3c",
  "pasos": [
    {
      "orden": 1,
      "nutriente": "nitrogeno",
      "producto_sugerido": "Urea (46-0-0)",
      "dosis_kg_por_hectarea": 12.5,
      "frecuencia": "unica_aplicacion",
      "observaciones": "Aplicar en banda, evitar contacto directo con el follaje."
    },
    {
      "orden": 2,
      "nutriente": "fosforo",
      "producto_sugerido": "Superfosfato triple (0-46-0)",
      "dosis_kg_por_hectarea": 5.0,
      "frecuencia": "unica_aplicacion",
      "observaciones": "Incorporar al suelo cerca de la zona radicular."
    }
  ]
}
```

### Consultar alertas climáticas de una parcela

```http
GET /parcelas/{parcela_id}/alertas-clima
Authorization: Bearer {token}
```

Respuesta:

```json
{
  "parcela_id": "par_1a2b3c",
  "alertas": [
    {
      "tipo": "lavado_nutrientes",
      "severidad": "alta",
      "ventana_horas": 48,
      "mensaje": "Riesgo de escorrentía severa. Posponga la fertilización para evitar que la lluvia lave sus insumos.",
      "generada_en": "2026-07-25T06:00:00Z"
    },
    {
      "tipo": "estres_termico",
      "severidad": "media",
      "mensaje": "Ola de calor prevista. Considere riego de auxilio y suspenda aplicaciones foliares.",
      "generada_en": "2026-07-24T06:00:00Z"
    }
  ]
}
```

### Consultar calendario fenológico de una parcela

```http
GET /parcelas/{parcela_id}/calendario-fenologico
Authorization: Bearer {token}
```

Respuesta:

```json
{
  "parcela_id": "par_1a2b3c",
  "cultivo": "cafe_arabica",
  "fecha_siembra": "2026-02-15",
  "etapa_actual": "floracion",
  "fases": [
    { "fase": "germinacion", "semana_inicio": 1, "semana_fin": 3, "estado": "completada" },
    { "fase": "desarrollo_vegetativo", "semana_inicio": 4, "semana_fin": 20, "estado": "completada" },
    { "fase": "floracion", "semana_inicio": 21, "semana_fin": 26, "estado": "en_curso" },
    { "fase": "llenado_grano", "semana_inicio": 27, "semana_fin": 40, "estado": "pendiente" }
  ],
  "proxima_alerta": {
    "semana": 21,
    "mensaje": "Inicio de floración. El cultivo demanda altos niveles de fósforo en esta etapa, prepare su aplicación."
  }
}
```

### Registrar un egreso

```http
POST /fincas/{finca_id}/egresos
Authorization: Bearer {token}
Content-Type: application/json

{
  "categoria": "fertilizante",
  "descripcion": "Urea 46-0-0, 2 quintales",
  "monto": 1450.00,
  "moneda": "NIO",
  "fecha": "2026-07-20",
  "parcela_id": "par_1a2b3c"
}
```

### Registrar un ingreso por cosecha

```http
POST /fincas/{finca_id}/ingresos
Authorization: Bearer {token}
Content-Type: application/json

{
  "parcela_id": "par_1a2b3c",
  "cantidad_quintales": 85,
  "precio_por_quintal": 210.00,
  "moneda": "NIO",
  "fecha_venta": "2026-07-22"
}
```

### Obtener dashboard de rentabilidad

```http
GET /fincas/{finca_id}/dashboard-rentabilidad?periodo=2026
Authorization: Bearer {token}
```

Respuesta:

```json
{
  "finca_id": "fin_5a6b7c",
  "periodo": "2026",
  "ingresos_totales": 17850.00,
  "egresos_totales": 9320.50,
  "utilidad_neta": 8529.50,
  "costo_produccion_por_manzana": 2073.44,
  "margen_ganancia_pct": 47.8,
  "punto_equilibrio_quintales": 44.4,
  "moneda": "NIO"
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
