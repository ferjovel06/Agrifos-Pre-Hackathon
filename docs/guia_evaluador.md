# Guía de evaluación de Agrifos

Esta guía permite revisar la API desplegada y probar la aplicación Android sin preparar un entorno local.

## 1. Activar y verificar el backend

Agrifos está desplegado en Render. En el plan gratuito, el servicio puede suspenderse tras un periodo sin tráfico, por lo que la primera solicitud puede tardar algunos segundos.

1. Abra [Agrifos API — Swagger UI](https://agrifos-api.onrender.com/docs).
2. Espere a que aparezca la documentación interactiva.
3. Si la página tarda en responder, abra primero [Health Check](https://agrifos-api.onrender.com/health) y vuelva a Swagger.
4. Para verificar también la conexión con PostgreSQL, abra [Database Health Check](https://agrifos-api.onrender.com/health/db).

Respuestas esperadas:

```json
{"status": "ok"}
```

```json
{"database": "ok", "result": 1}
```

La API fue verificada antes de preparar esta guía: `/health`, `/health/db`, `/openapi.json` y `/docs` respondieron con HTTP 200.

## 2. Autorización para probar endpoints

Los endpoints de negocio requieren un access token válido emitido por Supabase Auth. Los endpoints `/health` y `/health/db` son las excepciones.

En Swagger UI:

1. Presione **Authorize**.
2. Pegue únicamente el access token en el campo de autenticación Bearer. Swagger agrega automáticamente el prefijo `Bearer`.
3. Presione **Authorize** y cierre el cuadro.
4. Abra un endpoint, seleccione **Try it out**, complete sus parámetros y presione **Execute**.

El token también puede enviarse manualmente así:

```http
Authorization: Bearer <access_token>
```

### Obtener un token de prueba

Con las credenciales proporcionadas por el equipo, puede iniciar sesión y obtener un token mediante:

```bash
curl --request POST \
  'https://nquoibsuhgbomlbsljvs.supabase.co/auth/v1/token?grant_type=password' \
  --header 'apikey: <SUPABASE_PUBLISHABLE_KEY>' \
  --header 'Content-Type: application/json' \
  --data '{"email":"<CORREO_DE_PRUEBA>","password":"<CONTRASEÑA_DE_PRUEBA>"}'
```

Copie el valor `access_token` de la respuesta. Los tokens expiran; si Swagger comienza a responder `401`, inicie sesión nuevamente y reemplace el token. Las credenciales, tokens y claves no deben publicarse en este repositorio ni incluirse en capturas.

## 3. Roles disponibles

| Rol | Alcance |
|---|---|
| `farmer` | Rol predeterminado. Puede administrar sus propias fincas, parcelas, lecturas, análisis y etapas, pero no los registros de otros agricultores. |
| `auditor` | Acceso global de solo lectura. Puede consultar información de distintos agricultores, pero las operaciones de escritura responden `403`. |
| `admin` | Acceso global de lectura y escritura. También puede administrar usuarios, cultivos, variedades y plantillas fenológicas. |

Una cuenta recién registrada recibe el rol `farmer`. Los roles `auditor` y `admin` deben asignarse previamente por un administrador; el usuario no puede elevar su propio rol desde la aplicación.

Para confirmar la cuenta y su rol actual, ejecute:

```http
GET /users/me
```

## 4. Recorrido sugerido por la API

Con una cuenta `farmer` autorizada:

1. `GET /users/me` — comprobar identidad y rol.
2. `GET /crops` y `GET /varieties` — consultar catálogos.
3. `POST /farms` — registrar una finca.
4. `POST /parcels` — registrar una parcela asociada.
5. `POST /readings` — guardar una lectura del sensor y recibir su diagnóstico inmediato.
6. `GET /diagnostics/readings/{reading_id}` — consultar nuevamente el diagnóstico.
7. `POST /lab-analyses` — registrar un análisis de laboratorio.

Los identificadores creados en una respuesta se reutilizan en los siguientes pasos. Swagger muestra el esquema requerido y ejemplos de cada campo. Para evitar alterar datos de demostración importantes, use nombres que comiencen con `EVALUACION-`.

## 5. Instalar y probar el APK

1. Abra [GitHub Releases de Agrifos](https://github.com/ferjovel06/agrifos/releases).
2. Seleccione la versión más reciente y descargue el archivo `.apk` incluido en **Assets**.
3. En el dispositivo Android, permita temporalmente la instalación desde la aplicación usada para descargar el archivo.
4. Instale el APK y abra Agrifos.
5. Inicie sesión con la cuenta de evaluación proporcionada o cree una cuenta y confirme el correo recibido.

Recorrido móvil sugerido:

- Inicio y cierre de sesión.
- Confirmación de correo y recuperación de contraseña.
- Consulta y edición del perfil.
- MFA TOTP opcional desde la configuración de la cuenta.
- Registro de finca y parcela.
- Captura manual de análisis de laboratorio.
- Conexión del sensor NPK mediante USB OTG, si el hardware está disponible.

## 6. Observaciones de la versión MVP

- Se necesita conexión a internet para Supabase Auth, Render y PostgreSQL.
- La primera llamada al backend puede ser más lenta si Render estaba suspendido.
- La pestaña de planificación todavía no integra todo el backend disponible.
- La pestaña de finanzas conserva una interfaz de demostración.
- El sensor físico es opcional para revisar el resto del flujo; los análisis de laboratorio pueden ingresarse manualmente.
