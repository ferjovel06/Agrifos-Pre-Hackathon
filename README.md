# 🌱 Sistema de Asistencia Agrícola Inteligente

Sistema de asistencia agrícola compuesto por un hardware multiparamétrico (ESP32) y una plataforma digital interactiva. A través de la aplicación (móvil/web), el agricultor registra su finca y perfila sus parcelas seleccionando el tipo de planta y su etapa de crecimiento. Al conectar el sensor mediante Bluetooth o cable OTG, la aplicación despliega un tablero de control en tiempo real con los niveles de NPK, conductividad eléctrica, pH, temperatura y humedad. El motor de la app procesa estos datos instantáneamente, cruzando la lectura del suelo con los requerimientos óptimos del cultivo seleccionado. Como resultado, la interfaz genera un diagnóstico automatizado y un plan interactivo de fertilización paso a paso, indicando las dosis exactas de nutrientes necesarias para corregir las deficiencias del suelo directamente desde la pantalla.

## Tabla de contenidos
- [Arquitectura](#arquitectura)
- [Dependencias](#dependencias)
- [Variables de entorno](#variables-de-entorno)
- [Estructura modular](#estructura-modular)
- [Scripts](#scripts)
- [Ejemplos de endpoints](#ejemplos-de-endpoints)

## Arquitectura 

![Arquitectura](docs/arquitectura.png)

**Flujo de datos**
1. **Hardware (ESP32):** toma lecturas del suelo mediante sonda multiparamétrica (NPK, CE, pH, temperatura, humedad) y las transmite por BLE (GATT) o por cable OTG (USB Serial/CDC).
2. **App (Flutter):** descubre y empareja el sensor, recibe el stream de datos, permite registrar finca/parcela/cultivo, muestra el tablero en tiempo real y envía las lecturas al backend para su procesamiento.
3. **Backend (FastAPI):** expone la API REST, persiste la información en PostgreSQL, ejecuta el motor de diagnóstico (comparación lectura vs. requerimientos del cultivo por etapa fenológica) y calcula el plan de fertilización.
4. **Base de datos (PostgreSQL):** almacena catálogo de cultivos y requerimientos óptimos por etapa, fincas, parcelas, lecturas históricas y planes de fertilización generados.

### Capas del backend

```
Cliente (Flutter)
      │
      ▼
routers/          → capa de presentación (endpoints FastAPI, validación con Pydantic)
      │
      ▼
services/         → lógica de negocio (motor de diagnóstico y fertilización)
      │
      ▼
repositories/     → acceso a datos (SQLAlchemy)
      │
      ▼
PostgreSQL
```

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
| `pytest` / `httpx` | Testing de la API |

### App (Flutter 3.x)

| Paquete | Uso |
|---|---|
| `flutter_blue_plus` | Comunicación BLE con el sensor ESP32 |
| `usb_serial` | Comunicación vía cable OTG (USB Serial) |
| `dio` | Cliente HTTP para consumir la API |
| `provider` / `riverpod` | Gestión de estado |
| `fl_chart` | Gráficos del tablero en tiempo real |
| `hive` / `sqflite` | Persistencia local / caché offline |
| `intl` | Formateo de fechas y unidades |

### Firmware (ESP32 / Arduino / PlatformIO)

| Librería | Uso |
|---|---|
| `BLEDevice` (ESP32 BLE Arduino) | Servidor GATT para transmisión BLE |
| `ArduinoJson` | Serialización de las lecturas en formato JSON |
| `Wire` | Comunicación I2C con los sensores |
| Driver del sensor NPK/CE/pH | Lectura de parámetros del suelo |

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
│   │   ├── models/                 # Modelos SQLAlchemy (Finca, Parcela, Cultivo, Lectura, PlanFertilizacion)
│   │   ├── schemas/                # Esquemas Pydantic (request/response)
│   │   ├── routers/
│   │   │   ├── fincas.py
│   │   │   ├── parcelas.py
│   │   │   ├── cultivos.py
│   │   │   ├── lecturas.py
│   │   │   └── diagnostico.py
│   │   ├── services/
│   │   │   ├── diagnostico_service.py     # Cruce lectura vs. requerimientos del cultivo
│   │   │   └── fertilizacion_service.py   # Cálculo de dosis y plan paso a paso
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
│   │   │   ├── ble/                # Conexión y parsing BLE
│   │   │   ├── usb/                # Conexión OTG/Serial
│   │   │   └── api/                # Clientes REST (dio)
│   │   ├── domain/                 # Entidades y casos de uso
│   │   ├── presentation/
│   │   │   ├── finca/
│   │   │   ├── parcela/
│   │   │   ├── dashboard/          # Tablero en tiempo real (NPK, CE, pH, T°, HR)
│   │   │   └── fertilizacion/      # Plan interactivo paso a paso
│   │   └── shared/                 # Widgets reutilizables
│   └── pubspec.yaml
│
├── firmware_esp32/
│   ├── src/
│   │   ├── main.cpp
│   │   ├── ble_server.cpp          # Servicio GATT
│   │   ├── sensor_reader.cpp       # Lectura NPK/CE/pH/T°/HR
│   │   └── json_builder.cpp
│   └── platformio.ini
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

### Firmware (PlatformIO)

```bash
# Compilar firmware
pio run

# Cargar firmware al ESP32
pio run --target upload

# Monitor serial
pio device monitor
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
  "area_hectareas": 1.2
}
```

### Enviar lectura del sensor

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
  "fuente_conexion": "BLE"
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

### Obtener diagnóstico de una lectura

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

---
