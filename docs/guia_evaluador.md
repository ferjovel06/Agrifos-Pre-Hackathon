# Guía de evaluación de Agrifos

Esta guía permite activar la API desplegada, probar sus endpoints protegidos e instalar la aplicación Android sin preparar un entorno local.

## 1. Activar y verificar el backend

Agrifos está desplegado en Render. En el plan gratuito, el servicio puede suspenderse después de un periodo sin tráfico, por lo que la primera solicitud puede tardar algunos segundos.

1. Abra la [portada de Agrifos API](https://agrifos-api.onrender.com/).
2. Espere hasta que la portada indique **Servicio disponible** y **PostgreSQL disponible**.
3. Presione **Abrir Swagger UI** para consultar y probar los endpoints.

También puede abrir directamente los recursos técnicos:

- [Swagger UI](https://agrifos-api.onrender.com/docs): documentación interactiva.
- [ReDoc](https://agrifos-api.onrender.com/redoc): referencia legible de la API.
- [API Health](https://agrifos-api.onrender.com/health): disponibilidad y versión del backend.
- [Database Health](https://agrifos-api.onrender.com/health/db): conexión y latencia de PostgreSQL.

Una respuesta correcta de `/health` tiene esta estructura:

```json
{
  "status": "healthy",
  "service": "agrifos-api",
  "version": "1.0.0-beta.2",
  "timestamp": "2026-09-04T18:30:00+00:00"
}
```

Una respuesta correcta de `/health/db` tiene esta estructura:

```json
{
  "status": "healthy",
  "database": "postgresql",
  "latency_ms": 42.15,
  "timestamp": "2026-09-04T18:30:00+00:00"
}
```

Si `/health/db` responde HTTP `503`, espere unos segundos y vuelva a intentarlo. La respuesta no expone credenciales ni detalles internos de la base de datos.

## 2. Autorización para probar endpoints

Los endpoints de negocio requieren un access token válido emitido por Supabase Auth. La portada, `/health`, `/health/db`, `/docs`, `/redoc` y `/openapi.json` son públicos.

En Swagger UI:

1. Presione **Authorize**.
2. Pegue únicamente el access token en el campo de autenticación Bearer. Swagger agrega automáticamente el prefijo `Bearer`.
3. Presione **Authorize** y cierre el cuadro.
4. Abra un endpoint, seleccione **Try it out**, complete sus parámetros y presione **Execute**.

El token también puede enviarse manualmente mediante este encabezado:

```http
Authorization: Bearer <ACCESS_TOKEN>
```

### Obtener un token de prueba

Con las credenciales proporcionadas por el equipo, puede iniciar sesión y obtener un token. Sustituya también `<SUPABASE_PUBLISHABLE_KEY>` por la clave publicable entregada junto con las credenciales.

En Bash, Git Bash, Linux o macOS:

```bash
curl --request POST \
  'https://nquoibsuhgbomlbsljvs.supabase.co/auth/v1/token?grant_type=password' \
  --header 'apikey: <SUPABASE_PUBLISHABLE_KEY>' \
  --header 'Content-Type: application/json' \
  --data '{"email":"<CORREO_DE_PRUEBA>","password":"<CONTRASEÑA_DE_PRUEBA>"}'
```

En Windows PowerShell, copie esta línea completa desde un prompt normal que comience con `PS>`:

```powershell
(Invoke-RestMethod -Method Post -Uri 'https://nquoibsuhgbomlbsljvs.supabase.co/auth/v1/token?grant_type=password' -Headers @{apikey='<SUPABASE_PUBLISHABLE_KEY>'} -ContentType 'application/json' -Body (@{email='<CORREO_DE_PRUEBA>';password='<CONTRASEÑA_DE_PRUEBA>'} | ConvertTo-Json)).access_token
```

No copie los símbolos `>` de un prompt de continuación ni agregue barras invertidas antes de `--header`, `_` o `@`. El comando de PowerShell imprime directamente el access token; el comando `curl` lo devuelve dentro de la propiedad `access_token`.

Los tokens expiran. Si Swagger responde `401`, inicie sesión nuevamente y sustituya el token. Las credenciales y los tokens de evaluación se comparten por un canal privado y no deben publicarse en el repositorio, las notas del release ni capturas de pantalla. La clave debe ser la **publishable key** de Supabase; nunca se debe compartir una secret key o la clave `service_role`.

## 3. Roles disponibles

| Rol | Alcance |
|---|---|
| `farmer` | Rol predeterminado. Puede administrar sus propias fincas, parcelas, lecturas, análisis y etapas, pero no los registros de otros agricultores. |
| `auditor` | Acceso global de solo lectura. Puede consultar información de distintos agricultores, pero las operaciones de escritura responden `403`. |
| `admin` | Acceso global de lectura y escritura. También puede administrar usuarios, cultivos, variedades y plantillas fenológicas. |

Una cuenta recién registrada recibe el rol `farmer`. Los roles `auditor` y `admin` deben asignarse previamente por un administrador; el usuario no puede elevar su propio rol desde la aplicación.

Para confirmar la identidad y el rol de la cuenta autorizada, ejecute:

```http
GET /users/me
```

## 4. Recorrido sugerido por la API

Con una cuenta `farmer` autorizada:

1. `GET /users/me` — comprobar identidad y rol.
2. `GET /crops` y `GET /varieties` — consultar los catálogos agronómicos.
3. `POST /farms` — registrar una finca.
4. `POST /parcels` — registrar una parcela asociada a la finca.
5. `GET /phenological-stages/templates` — consultar las etapas disponibles para el cultivo.
6. `POST /phenological-stages/instances` — registrar una etapa en la parcela.
7. `POST /readings` — guardar una lectura del sensor y recibir su diagnóstico inmediato.
8. `GET /diagnostics/readings/{reading_id}` — consultar nuevamente el diagnóstico.
9. `POST /lab-analyses` — registrar un análisis de laboratorio.
10. `POST /fertilization/recommendations` — generar o recuperar una recomendación para los datos registrados.
11. `GET /fertilization/plans/latest?parcel_id={parcel_id}` — consultar el último plan guardado sin crear uno nuevo.
12. `GET /weather/farms/{farm_id}/forecast` — consultar el pronóstico de la finca.
13. `POST /alerts/farms/{farm_id}/evaluate` — evaluar el pronóstico y sincronizar las alertas climáticas.

Los identificadores devueltos en una respuesta se reutilizan en los pasos posteriores. Swagger muestra el esquema requerido, los parámetros y los ejemplos de cada endpoint. Para evitar alterar información importante de demostración, use nombres que comiencen con `EVALUACION-`.

Para comprobar los permisos, una cuenta `auditor` puede repetir consultas `GET`; cualquier intento de crear, editar o eliminar información debe responder HTTP `403`.

## 5. Instalar y probar el APK

1. Abra [GitHub Releases de Agrifos](https://github.com/ferjovel06/agrifos/releases).
2. Seleccione la prerelease más reciente y descargue el archivo `.apk` incluido en **Assets**.
3. En el dispositivo Android, permita temporalmente la instalación desde la aplicación usada para descargar el archivo.
4. Instale el APK y abra Agrifos.
5. Inicie sesión con la cuenta de evaluación proporcionada.

Recorrido móvil sugerido:

- Inicio y cierre de sesión.
- Confirmación de correo y recuperación de contraseña.
- Consulta y edición del perfil.
- Activación y verificación de MFA mediante TOTP.
- Selección, registro y edición de fincas y parcelas.
- Selección de cultivo, variedad y etapa fenológica.
- Captura manual de análisis de laboratorio.
- Consulta del diagnóstico y del plan de fertilización completo.
- Consulta del pronóstico y las alertas climáticas.
- Conexión del sensor NPK mediante USB OTG, si el hardware está disponible.

## 6. Consideraciones para la evaluación

- Se necesita conexión a internet para Supabase Auth, Render y PostgreSQL.
- La primera llamada al backend puede ser más lenta mientras Render reactiva el servicio.
- El sensor físico es opcional para revisar el resto del flujo; los análisis de laboratorio pueden ingresarse manualmente.
- Las credenciales de evaluación son temporales y deben utilizarse únicamente para revisar esta entrega.
