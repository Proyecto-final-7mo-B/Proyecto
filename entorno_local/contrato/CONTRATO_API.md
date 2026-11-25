# Kaizen · Contrato de la API v1 (frontend ↔ backend)

- **Versión:** 1.4 · 24-nov-2026. Reemplaza a la tabla de endpoints de la 2.ª entrega (§16.1).
- **Cambios de la 1.4 respecto a la 1.3** (MongoDB; detalle completo en `MongoDB_analitica_y_ETL.pdf`):
  1. `GET /laboratorio/perspectivas`: cada perspectiva trae `categoria` y la lista `habitos` (la arma la API desde PostgreSQL), en lugar de `habito_id`/`habito_nombre`, porque MongoDB no guarda ids ni nombres de hábitos (§6.8).
  2. `GET /admin/indicadores/{codigo}`: la forma de cada elemento de `series` depende del indicador, y los 6 los calcula el ETL en la colección `indicadores` (§6.10).
  3. Nueva variable `KAIZEN_ANALITICA_HMAC_KEY`: la usa la API para calcular el seudónimo `usuario_sdn` y buscar las perspectivas del usuario.
- **Cambios de la 1.3 respecto a la 1.2:**
  1. **Zona horaria (corrige un error real):** la app manda la cabecera `X-Zona-Horaria` (IANA) en **todas** las peticiones y la API la fija en cada transacción. Sin esto, entre las 18:00 y las 24:00 de México la racha vigente se ve en 0, porque la base cree que ya es "mañana" (UTC). Ver §1.1.
  2. **Llaves de firma:** los JWT llevan en la cabecera `kid`; la llave privada viene de `KAIZEN_JWT_LLAVE_PRIVADA` (§2.1).
  3. **Tareas programadas:** no son endpoints; corren en nodo1 con el rol `kaizen_tareas` (§6.12).
- **Cambios de la 1.2 respecto a la 1.1** (no cambian la base de datos):
  1. El token de acceso lleva el claim `sid`: el `jti` de la sesión (`sesion.jti`) con la que se emitió. Con él, `PUT /cuenta/contrasena` sabe cuál es la sesión actual y cierra solo las demás (§2.1, §6.2).
  2. Se aclaró qué fechas se aceptan. El rango hoy-1 a hoy+1 aplica **solo** al parámetro `?fecha=` ("hoy"). Un check-in (`POST /registros` y `/registros/lote`) se acepta con **cualquier fecha** desde el día en que se creó el hábito hasta hoy+1, para que la cola sin conexión pueda enviar días atrasados (§1, §4, §6.5).
- **Para quién:** Jesús Ángel (API en FastAPI) y Samuel (app Flutter). Los dos programan contra **este** documento: la app con sus repositorios *fake* y la API con sus pruebas.
- **Base de datos:** describe la estructura que ya está en el clúster y en el entorno local (`postgres/`), con los cambios del 23-nov: Escalera por hábito, suspensión, categorías administrables, recuperación de contraseña y catálogo de 8 categorías.
- **Cómo se cambia:** un cambio de forma (campo, ruta o código de error) se acuerda entre los dos y se sube en un PR que actualice este archivo. Cuando exista, `docs/api/openapi.json` (generado por FastAPI) debe coincidir con este contrato, y una prueba lo vigila.

---

## 1. Convenciones generales

| Tema | Regla |
|---|---|
| URL base | Producción: `https://proyecto-kaizen.northcentralus.cloudapp.azure.com/api/v1` · Local: `http://localhost:8000/api/v1` |
| Formato | JSON en UTF-8. Petición con `Content-Type: application/json`. Nombres de campos en `snake_case` y en español |
| Campos de más | **Se rechazan con 422** (Pydantic `extra="forbid"`). La app manda solo los campos de este contrato. Nunca manda `usuario_id` ni `region`: salen del token |
| Identificadores | UUID v4 en texto. El `id` de un check-in lo **genera la app** (idempotencia) |
| Fechas | `fecha`: `YYYY-MM-DD` (fecha **local del usuario**). Instantes: ISO 8601 en UTC con `Z` (`2026-11-23T18:04:05Z`) |
| Números | `meta` y `valor`: número JSON con hasta 2 decimales (`10`, `12.5`). Porcentajes: 0–100 con 2 decimales |
| Paginación | `?pagina=1&por_pagina=20` (máximo 100). Respuesta: `{"elementos": [...], "pagina": 1, "por_pagina": 20, "total": 134}` |
| Vacíos | Las listas vacías son `[]`, nunca `null`. Un campo opcional sin valor va como `null` |
| Caché | `Cache-Control: no-store` en `/auth/*` y `/cuenta*`. `GET /categorias`: `max-age=3600` |
| Idempotencia | `POST /registros` y `POST /registros/lote` se pueden reenviar sin duplicar (mismo `id` = mismo check-in). Las demás operaciones **no** se reintentan solas |
| Zona horaria | **Cabecera `X-Zona-Horaria` obligatoria** en todas las peticiones (detalle en §1.1). Además, el servidor trabaja en UTC: cuando importa "hoy", la app manda su fecha local en el parámetro `?fecha=` (`GET /habitos`, `GET /habitos/{id}`, `GET /progreso`). **Solo ese parámetro** debe estar entre hoy-1 y hoy+1 (UTC), porque representa "hoy" en cualquier zona horaria de México y LATAM; fuera de ese rango → 422 `fecha-fuera-de-rango`. Las fechas de los check-ins y de los rangos `desde`/`hasta` **no** tienen ese límite (ver §4) |

### 1.1 Zona horaria del usuario

**El problema.** La base trabaja en UTC y varias reglas usan "hoy" (`current_date`):
- la racha vigente (`v_racha_vigente`);
- la validación de fecha futura de un check-in;
- el cumplimiento de la Escalera;
- la fecha de creación de un hábito (`fecha_creacion::date`).

A las 19:00 de la Ciudad de México ya es el día siguiente en UTC. Un usuario que todavía no marca su hábito de hoy ve su **racha en 0** desde las 18:00 hasta la medianoche, aunque el día no ha terminado. Se comprobó en la base el 23-nov a las 23:02 h de México: la misma racha se veía en **0** sin arreglo y en **10** con el arreglo. El script está en `postgres/cambios/demo_zona_horaria.sql` del entorno local.

**El arreglo** (no cambia la base):

| Quién | Qué hace |
|---|---|
| App | Manda `X-Zona-Horaria: America/Mexico_City` (la zona IANA del dispositivo; en Flutter, con el paquete `flutter_timezone`) en **todas** las peticiones, desde el interceptor de `dio` |
| API | Valida la zona contra `zoneinfo.available_timezones()`. Si falta, usa `America/Mexico_City`; si es inválida, responde 422 `validacion` (`campo: "X-Zona-Horaria"`) |
| API | En **cada** transacción, junto al `set_config` de la RLS, ejecuta `SELECT set_config('TimeZone', %s, true)` con la zona como parámetro. El `true` la limita a esa transacción (seguro con el pool) y la base calcula "hoy" en la hora del usuario |
| API | El rango de `?fecha=` (hoy-1 a hoy+1) se valida contra la fecha **en la zona del usuario** |
| Tareas | La Escalera diaria corre a las **08:00 UTC** (02:00 en México, 05:00 en Argentina): a esa hora el día anterior ya terminó en toda la región. No se corre a las 00:00 UTC, cuando en México todavía son las 18:00 |

Los instantes (`registrado_en`, `creada_en`, …) siguen viajando en UTC con `Z`. La zona horaria **no se guarda** en la base: solo vive en la petición.

## 2. Autenticación y sesión

### 2.1 Tokens

| Token | Vida | Contenido (claims) | Dónde lo guarda la app |
|---|---|---|---|
| Acceso | **15 min** | `sub` (id de usuario), `region`, `rol` (`usuario` \| `admin`), `jti` (propio del token de acceso), **`sid`** (= `sesion.jti` del token de renovación emitido junto con él), `iat`, `exp`, `typ: "acceso"` | Solo en memoria |
| Renovación | **7 días** | `sub`, `region`, `jti` (= `sesion.jti`), `fam` (familia), `iat`, `exp`, `typ: "renovacion"` | Android: Keystore · iOS/macOS: Keychain · Linux: libsecret · Windows: Credential Manager · **Web: solo en memoria** |

- Los dos son JWT firmados con **EdDSA (Ed25519)**. La API verifica fijando `algorithms=["EdDSA"]` y el `typ`.
- **Llave:** `KAIZEN_JWT_LLAVE_PRIVADA` es la semilla Ed25519 de 32 bytes en base64 (`Ed25519PrivateKey.from_private_bytes(base64.b64decode(...))`). La pública se deriva de ella. La cabecera del JWT lleva `kid` = `KAIZEN_JWT_KID`, para poder rotar la llave más adelante. En producción la llave vive en nodo1 (`/etc/kaizen/api.env`); en local se usa la **de desarrollo** del `.env` (un token local no sirve en producción, ni al revés).
- Cada petición protegida manda `Authorization: Bearer <token_acceso>`.
- **`sid`:** login, registro y renovar emiten el par de tokens juntos. El `sid` del token de acceso es el `jti` del token de renovación del mismo par, es decir, la fila de `sesion` que se acaba de insertar. La app no lo usa: solo lo lee la API.
- **Rotación:** cada `POST /auth/renovar` revoca el token de renovación usado y entrega un par nuevo de la misma familia. Si alguien presenta un token **ya rotado**, la API revoca la familia completa y responde `401 token-reutilizado`. La app manda a `/login`.
- **Una cuenta suspendida** no puede iniciar ni renovar sesión: la base lo impide (KZ012). Al suspenderla se revocan sus sesiones. El token de acceso que ya tenga vence en ≤ 15 min.
- **Interceptor de la app:** ante un 401 en cualquier ruta (menos `/auth/*`), llama **una sola vez** a `/auth/renovar`, con un candado para que no haya dos renovaciones a la vez, y repite la petición. Si falla, cierra la sesión.

### 2.2 Límites de tasa

| Dónde | Límite | Qué pasa al pasarse |
|---|---|---|
| Nginx · `/auth/login`, `/auth/registro`, `/auth/recuperar`, `/auth/restablecer` | 5 por minuto por IP (ráfaga 5) | 429 |
| Nginx · `/auth/renovar`, `/auth/salir` | 30 por minuto por IP (ráfaga 10) | 429 |
| Nginx · resto de `/api/` | 10 por segundo por IP (ráfaga 20) | 429 |
| API · registro | 3 por hora por IP | 429 |
| API · login | Tras **10 fallos** la cuenta se bloquea 15 min (`usuario.bloqueado_hasta`) | 429 `cuenta-bloqueada` con `Retry-After` |
| Base · recuperación | 3 solicitudes por hora por cuenta (en silencio: la respuesta no cambia) | — |

Los 429 de Nginx también llegan como `application/problem+json` (`type: demasiadas-peticiones`). La app respeta `Retry-After` cuando viene.

### 2.3 Política de contraseña

- De **12 a 128 caracteres**, sin reglas de composición (ASVS 2.1).
- No puede ser igual al correo y se rechaza si está en la lista de contraseñas comunes que lleve la API.
- La app valida la longitud; la API valida todo. Error: `422 validacion` con `errores[].campo = "contrasena"`.

## 3. Errores

Todas las respuestas de error usan `application/problem+json` (RFC 9457):

```json
{
  "type": "https://kaizen.app/errores/capsula-sellada",
  "title": "La cápsula aún está sellada",
  "status": 409,
  "detail": "Racha 9 de 21",
  "id_peticion": "7f3c2a9e-…",
  "errores": [{"campo": "mensaje", "detalle": "Máximo 4096 bytes"}]
}
```

- `errores` solo aparece en los 422 de validación.
- Algunos tipos agregan campos (`racha`, `objetivo` en `capsula-sellada`).
- Un 500 **nunca** trae la traza: solo `id_peticion`, para buscarla en las bitácoras.

| `type` (sufijo) | HTTP | Origen | Qué hace la app |
|---|---|---|---|
| `validacion` | 422 | Pydantic, **KZ011** o `X-Zona-Horaria` inválida | Muestra el error junto al campo |
| `region-invalida` | 422 | **KZ002** | "País o estado fuera del servicio" |
| `fecha-fuera-de-rango` | 422 | **KZ003** | "Fecha no válida" |
| `categoria-inactiva` | 422 | **KZ014** | Recarga `/categorias` |
| `enlace-invalido` | 400 | **KZ015** | "El enlace no es válido o ya venció"; ofrece pedir otro |
| `credenciales-invalidas` | 401 | API | "Correo o contraseña incorrectos" (mismo texto exista o no la cuenta) |
| `token-invalido` | 401 | API | Renovar una vez; si falla, `/login` |
| `token-reutilizado` | 401 | API | Cerrar sesión con aviso de seguridad |
| `consentimiento-requerido` | 403 | **KZ008** | Abrir el diálogo de consentimiento de señales |
| `rol-insuficiente` | 403 | API o **KZ010** | Ocultar la opción de admin |
| `cuenta-suspendida` | 403 | API o **KZ012** | "Tu cuenta está suspendida. Contacta al administrador" |
| `no-encontrado` | 404 | **KZ004** o API | "No encontrado". También para recursos de **otro** usuario (anti-IDOR) |
| `registro-rechazado` | 409 | **KZ001** | "No fue posible completar el registro" (texto genérico a propósito) |
| `capsula-sellada` | 409 | **KZ005** | "Racha 9 de 21" (usa `racha` y `objetivo`) |
| `sugerencia-resuelta` | 409 | **KZ005** | Refresca la Escalera |
| `operacion-no-permitida` | 409 | **KZ006** | Mensaje de regla (p. ej., la meta solo cambia con la Escalera) |
| `habito-archivado` | 409 | **KZ007** | "El hábito está archivado" |
| `nombre-duplicado` | 409 | **KZ013** | "Ya existe una categoría con ese nombre" |
| `cuenta-bloqueada` | 429 | API | Muestra el tiempo de `Retry-After` |
| `demasiadas-peticiones` | 429 | Nginx o API | Espera `Retry-After` y reintenta |
| `primario-no-disponible` | 503 | API (failover) | Reintenta 3 veces (0.2/0.4/0.8 s ± azar); si sigue, encola el check-in o muestra la caché |
| `analitica-no-disponible` | 503 | API (HomeLab caído) | Laboratorio y panel muestran lo último guardado |
| `servicio-no-disponible` | 502/503 | Nginx (API apagada) | Banner "Servicio no disponible"; modo sin conexión |
| `error-interno` | 500 | API | "Algo salió mal" + `id_peticion` |

## 4. Valores permitidos y validaciones

Son los mismos límites que hace cumplir la base. Si la app los valida antes, el usuario ve el error sin esperar al servidor.

| Campo | Regla |
|---|---|
| `nombre` (usuario) | 1–80 caracteres |
| `email` | Formato `x@y.z`. Se normaliza: sin espacios y en minúsculas |
| `pais`, `estado` | Solo los de `paises_estados.json` (México con estado ISO 3166-2, o uno de 19 países de LATAM sin estado) |
| `region` | `MX-NORTE` · `MX-CENTRO-SUR` · `LATAM` (la calcula la base; la app solo la muestra) |
| `habito.nombre` | 1–60 caracteres |
| `habito.unidad` | 1–20 caracteres |
| `habito.meta` | > 0, hasta 2 decimales. **Solo se fija al crear**; después solo cambia aceptando una sugerencia de la Escalera |
| `frecuencia.tipo` | `diaria` · `dias_semana` · `n_por_semana` |
| `frecuencia.dias_semana` | Máscara 1–127: lunes = 1, martes = 2, miércoles = 4, jueves = 8, viernes = 16, sábado = 32, domingo = 64 (L–V = 31). Solo con `dias_semana` |
| `frecuencia.veces_semana` | 1–7. Solo con `n_por_semana` |
| `escalera_activa` | Booleano, por omisión `true`. Al apagarla o al archivar el hábito, su sugerencia pendiente se marca `expirada` |
| `registro.valor` | ≥ 0, hasta 2 decimales, opcional |
| `registro.origen` | `manual` · `rapido` · `offline` (la cola sin conexión manda `offline`) |
| `registro.fecha` | Cualquier fecha **desde el día de creación del hábito hasta hoy+1** (UTC); el hábito no puede estar archivado. **No** se limita a hoy-1: la cola sin conexión envía la fecha original del check-in aunque tenga días de atraso. La base lo hace cumplir (KZ003, KZ007) |
| `desde`, `hasta` | `desde` ≤ `hasta`, máximo 366 días entre ambos; pueden ser fechas pasadas |
| `animo`, `energia` | Enteros 1–5 |
| `capsula.mensaje` | 1 a 4,096 **bytes** en UTF-8 (un emoji ocupa 4) |
| `capsula.racha_objetivo` | `7` · `21` · `66` |
| `categoria.nombre` | 2–40 caracteres; única sin importar mayúsculas |
| `suspension.motivo` | 3–200 caracteres |
| Sugerencia `estado` | `pendiente` · `aceptada` · `rechazada` · `expirada` |
| Cápsula `estado` | `sellada` · `abierta` |

## 5. Objetos que se repiten

```jsonc
// Habito
{
  "id": "1c9e…", "nombre": "Leer", "unidad": "páginas", "meta": 15, "nivel": 3,
  "categoria": {"id": "5b1e…", "nombre": "Lectura"},
  "frecuencia": {"tipo": "dias_semana", "dias_semana": 31, "veces_semana": null},
  "escalera_activa": true, "activo": true, "fecha_creacion": "2026-09-01T14:00:00Z",
  "racha": {"actual": 5, "maxima": 12, "ultima_fecha": "2026-11-22"},   // de v_racha_vigente
  "hoy": {"fecha": "2026-11-23", "programado": true,
          "registro": {"id": "…", "cumplido": true, "valor": 18}}        // null si aún no hay check-in
}

// Registro (check-in)
{"id": "…", "habito_id": "…", "fecha": "2026-11-23", "cumplido": true, "valor": 18,
 "origen": "manual", "registrado_en": "2026-11-23T14:05:00Z"}

// Sugerencia de la Escalera
{"id": "…", "habito_id": "…", "habito_nombre": "Leer", "tipo": "subir",
 "meta_actual": 15, "meta_propuesta": 16.5, "cumplimiento_14d": 92.86,
 "estado": "pendiente", "creada_en": "2026-11-23T03:00:00Z", "resuelta_en": null}

// Capsula (sin el mensaje)
{"id": "…", "habito_id": "…", "habito_nombre": "Tomar agua", "racha_objetivo": 21,
 "progreso": 9,                 // racha máxima desde que se selló (fn_rachas desde creada_en)
 "se_puede_abrir": false, "estado": "sellada", "tiene_foto": true,
 "creada_en": "…", "abierta_en": null}

// Tokens (respuesta de login, registro y renovar)
{"token_acceso": "eyJ…", "token_renovacion": "eyJ…", "tipo": "Bearer", "expira_en": 900,
 "usuario": {"id": "…", "nombre": "Daniela", "rol": "usuario", "region": "MX-NORTE"}}
```

---

## 6. Endpoints

Rol: **público** (sin token) · **usuario** (cualquier sesión) · **admin** (`rol = admin` en el token; la API lo vuelve a verificar y, en las operaciones de escritura, también la base).

### 6.1 Autenticación (`/auth`)

#### `POST /auth/registro` · público
```json
{"nombre": "Daniela", "email": "dani@correo.com", "contrasena": "…", "pais": "MX", "estado": "JAL",
 "acepta_aviso": true, "consiente_senales": false}
```
- `estado` es obligatorio si `pais = MX` y debe ser `null` en otro caso. `acepta_aviso` debe ser `true` (si no, 422).
- **201** → Tokens (ya queda con la sesión iniciada).
- Errores: 422 `validacion` o `region-invalida` · 409 `registro-rechazado` · 429.
- BD: Argon2id + HMAC del correo → `CALL sp_registrar_usuario(...)` → `INSERT sesion`.

#### `POST /auth/login` · público
```json
{"email": "dani@correo.com", "contrasena": "…"}
```
- **200** → Tokens.
- Errores: 401 `credenciales-invalidas` · 403 `cuenta-suspendida` (solo si la contraseña fue correcta) · 429 `cuenta-bloqueada`.
- BD: `directorio_usuarios` (por HMAC) → `set_config` → `usuario` → `UPDATE intentos_fallidos / bloqueado_hasta` → `INSERT sesion` → bitácora `auth.login`.

#### `POST /auth/renovar` · token de renovación
```json
{"token_renovacion": "eyJ…"}
```
- **200** → Tokens nuevos.
- Errores: 401 `token-invalido` o `token-reutilizado` · 403 `cuenta-suspendida`.

#### `POST /auth/salir` · usuario
```json
{"token_renovacion": "eyJ…"}
```
- **204**. Revoca esa sesión. La app borra sus tokens aunque la petición falle.

#### `POST /auth/recuperar` · público (B4b)
```json
{"email": "dani@correo.com"}
```
- **202** siempre, con el mismo cuerpo exista o no la cuenta: `{"detalle": "Si el correo está registrado, te enviamos un enlace."}`.
- La API genera 32 bytes aleatorios (`secrets.token_urlsafe(32)`) y llama a `CALL sp_solicitar_recuperacion(hmac, sha256_hex(token), ip, NULL, NULL)`. Si `p_enviar` es `true`, manda el correo **en segundo plano**, para que el tiempo de respuesta no delate si la cuenta existe.
- Correo: asunto "Restablece tu contraseña de Kaizen", saludo con `p_nombre` y enlace `KAIZEN_URL_RESTABLECER?token=<token>`, vigente **15 min** y de **un solo uso**.

#### `POST /auth/restablecer` · público (B4b)
```json
{"token": "…", "nueva": "…"}
```
- **204**. Cambia la contraseña, desbloquea la cuenta y **cierra todas las sesiones**.
- Errores: 400 `enlace-invalido` · 422 `validacion` (política de contraseña).
- BD: `CALL sp_restablecer_contrasena(sha256_hex(token), argon2(nueva), ip)`.
- App: ruta `/restablecer?token=` (web). En móvil el enlace abre el navegador con la versión web.

### 6.2 Cuenta (`/cuenta`) · usuario · ARCO

| Método y ruta | Cuerpo | Respuesta | BD |
|---|---|---|---|
| `GET /cuenta` | — | 200 `{"id","nombre","email","pais","region","rol","fecha_registro","consentimiento_senales": true, "consentimiento_senales_en": "…"}` | `usuario` |
| `PATCH /cuenta` | `{"nombre": "…"}` | 200 = `GET /cuenta` | `UPDATE usuario (nombre)` |
| `PUT /cuenta/contrasena` (B4a) | `{"actual": "…", "nueva": "…"}` | 204; revoca **las demás** sesiones y la actual sigue abierta · 401 `credenciales-invalidas` (cuenta para el bloqueo) · 422 | `UPDATE usuario (password_hash)`, y luego `UPDATE sesion SET revocada_en = now() WHERE region = :region AND usuario_id = :sub AND revocada_en IS NULL AND familia <> (SELECT familia FROM sesion WHERE region = :region AND jti = :sid)`, con `:sid` tomado del token de acceso |
| `PUT /cuenta/consentimientos` | `{"senales": false}` | 200 `{"senales": false, "senales_borradas": 42}` | `true` → `UPDATE consentimiento_senales_en = now()` · `false` → `CALL sp_retirar_consentimiento_senales` |
| `GET /cuenta/datos` | — | 200 JSON descargable (`Content-Disposition: attachment; filename="kaizen-mis-datos.json"`) con cuenta, hábitos, registros, niveles, sugerencias, señales y cápsulas (solo con el mensaje de las **abiertas**) | Lecturas con RLS |
| `DELETE /cuenta` | `{"contrasena": "…"}` | 204 · 401 | `CALL sp_eliminar_cuenta` (borra todo en cascada; la bitácora conserva el evento) |

> No se puede cambiar el correo ni el país desde la app: cambiar la región es mover al usuario de fragmento (la base lo impide, KZ006). Si un usuario lo pide, lo atiende el administrador.

### 6.3 Categorías

#### `GET /categorias` · usuario (B1)
- **200** `[{"id": "…", "nombre": "Aprendizaje"}, …]`. Solo las activas, ordenadas por nombre.
- Catálogo inicial: Aprendizaje, Ejercicio, Finanzas, Hidratación, Lectura, Meditación, Salud, Sueño.
- La app lo guarda en su tabla local `categorias` y deriva el ícono del nombre de la categoría.

### 6.4 Hábitos (`/habitos`) · usuario

| Método y ruta | Cuerpo / parámetros | Respuesta |
|---|---|---|
| `GET /habitos?fecha=2026-11-23&archivados=false` | `fecha`: la fecha local, para calcular `hoy` | 200 `[Habito]` (activos; con `archivados=true`, también los archivados) |
| `POST /habitos` | `{"nombre","categoria_id","frecuencia": {"tipo","dias_semana","veces_semana"},"meta","unidad","escalera_activa": true}` | **201** Habito (la base crea el nivel 1 y la racha) · 422 `categoria-inactiva` / `validacion` |
| `GET /habitos/{id}?fecha=` | — | 200 Habito · 404 |
| `PATCH /habitos/{id}` | Cualquiera de: `{"nombre","categoria_id","unidad","escalera_activa","activo"}` | 200 Habito · 404 · 422. **`meta` y `frecuencia` no se aceptan** (422): la meta cambia con la Escalera y la frecuencia no se edita |
| `GET /habitos/{id}/registros?desde=&hasta=` | Máximo **366 días** | 200 `[Registro]` ordenados por fecha |
| `GET /habitos/{id}/escalera` (B2) | — | 200 ver abajo |

- **Archivar** = `PATCH {"activo": false}`. No hay `DELETE` de hábitos: el historial se conserva. Al archivar, su sugerencia pendiente expira.
- **Escalera de un hábito** (pantalla 06):
```json
{"habito_id": "…", "escalera_activa": true, "nivel_actual": 3, "meta_actual": 10, "unidad": "min",
 "niveles": [{"nivel": 1, "meta": 7, "desde": "2026-10-03", "hasta": "2026-10-18"},
             {"nivel": 2, "meta": 8.5, "desde": "2026-10-18", "hasta": "2026-11-02"},
             {"nivel": 3, "meta": 10, "desde": "2026-11-02", "hasta": null}],
 "sugerencia_pendiente": {"id": "…", "tipo": "subir", "meta_propuesta": 11, "cumplimiento_14d": 92.0},
 "historial": [{"fecha": "2026-11-02", "tipo": "subir", "de": 8.5, "a": 10, "estado": "aceptada"}]}
```
  Los niveles futuros **no existen** en la base. Si la app quiere mostrar "nivel 3 de 5", dibuja 2 niveles *proyectados* (+10 % cada uno) y los marca como proyección.
- BD: `habito`, `v_racha_vigente`, `nivel_habito`, `sugerencia_ajuste`, `fn_dia_programado` (para `hoy.programado`).

### 6.5 Check-ins (`/registros`) · usuario

#### `POST /registros`
```json
{"id": "uuid-generado-por-la-app", "habito_id": "…", "fecha": "2026-11-23", "cumplido": true, "valor": 18, "origen": "manual"}
```
- **200** `{"id": "…", "racha_actual": 6}`, igual si es nuevo o si se reenvía. Reenviar con otro valor el mismo día **reemplaza** el check-in: gana el último.
- `fecha` es el día **local** del check-in y puede ser de días anteriores (desde la creación del hábito hasta hoy+1). La API no aplica el rango de `?fecha=`.
- Errores: 404 (hábito ajeno o inexistente) · 409 `habito-archivado` · 422 `fecha-fuera-de-rango`.
- BD: `CALL sp_registrar_checkin(region, usuario, id, habito, fecha, cumplido, valor, origen, NULL)`.

#### `POST /registros/lote` (cola sin conexión)
```json
{"registros": [ /* hasta 100 objetos como el de arriba, con "origen": "offline" */ ]}
```
- **200** siempre que el lote tenga forma válida. Cada elemento se procesa aparte (un `SAVEPOINT` por elemento):
```json
{"resultados": [{"id": "…", "estado": "aceptado", "racha_actual": 6},
                {"id": "…", "estado": "rechazado",
                 "error": {"type": "https://kaizen.app/errores/habito-archivado", "status": 409, "title": "El hábito está archivado"}}]}
```
- La app saca de la cola los `aceptado` y marca los `rechazado` con su motivo (no los reintenta).

### 6.6 Escalera (`/escalera`) · usuario

| Método y ruta | Cuerpo | Respuesta |
|---|---|---|
| `GET /escalera/sugerencias` | — | 200 `[Sugerencia]` pendientes del usuario |
| `POST /escalera/sugerencias/{id}/respuesta` | `{"aceptar": true}` | 200 `{"estado": "aceptada", "nivel": 4, "meta_nueva": 11}` (si rechaza: `nivel` y `meta_nueva` son `null`) · 404 · 409 `sugerencia-resuelta` |

- Las sugerencias las genera la tarea diaria (`sp_generar_sugerencias`), **solo** para hábitos activos con `escalera_activa = true`.
- "Mantener" en la app = `{"aceptar": false}`.

### 6.7 Progreso · usuario (B3)

#### `GET /progreso?periodo=semana|mes|anio&fecha=2026-11-23`
```json
{"periodo": "semana", "desde": "2026-11-17", "hasta": "2026-11-23",
 "cumplimiento": 82.0, "variacion": 6.0, "habitos_activos": 5,
 "por_dia": [{"fecha": "2026-11-17", "programados": 5, "cumplidos": 3, "cumplimiento": 60.0}],
 "por_habito": [{"habito_id": "…", "nombre": "Leer", "cumplimiento": 85.71}],
 "mejores_rachas": [{"categoria": "Lectura", "racha_maxima": 34}],
 "crecimiento_metas": 18.0}
```
- La semana va de lunes a domingo. `variacion` compara con el periodo anterior. `crecimiento_metas` compara la meta vigente con la del nivel 1.
- La barra L–D de "Hoy" y "Mi semana" usan `periodo=semana`.
- BD: `registro`, `habito`, `fn_dia_programado`, `fn_cumplimiento`, `v_racha_vigente`, `nivel_habito`.

### 6.8 Señales y Laboratorio · usuario (F2)

| Método y ruta | Cuerpo / parámetros | Respuesta |
|---|---|---|
| `POST /senales` | `{"fecha": "2026-11-23", "animo": 4, "energia": 3}` | 200 la señal guardada. Si ya hay una ese día, se reemplaza · 403 `consentimiento-requerido` |
| `GET /senales?desde=&hasta=` | Máximo 366 días | 200 `[{"fecha","animo","energia"}]` |
| `GET /laboratorio/perspectivas?semana=2026-W47` | Semana ISO; por omisión, la última completa | 200 ver abajo · 503 `analitica-no-disponible` |

```json
{"semana": "2026-W47", "datos_suficientes": true, "generado_en": "2026-11-24T09:03:00Z",
 "perspectivas": [{"tipo": "asociacion", "categoria": "Ejercicio", "variable": "energia", "delta": 0.8,
                   "dias_con": 9, "dias_sin": 8,
                   "habitos": [{"id": "1c9e…", "nombre": "Caminar"}],
                   "texto": "Los días que cumples tus hábitos de Ejercicio, tu energía promedio es 0.8 puntos mayor"}]}
```
- `tipo`: `asociacion` · `franja_horaria` (con `franja`: `manana`/`tarde`/`noche`) · `riesgo_abandono` (con `cumplimiento_7d`, `pendiente_14d`) · `capsula_cercana` (con `racha_objetivo`, `dias_restantes`). Los campos que no aplican a un tipo se omiten.
- La API busca el documento por `usuario_sdn = HMAC-SHA256(KAIZEN_ANALITICA_HMAC_KEY, str(usuario_id).lower())` y completa `habitos` y `texto` con datos de PostgreSQL.
- Con menos de 14 días de datos: `datos_suficientes: false` y `perspectivas: []`.
- La app muestra siempre la leyenda "asociaciones, no causas".
- BD: `senal_diaria` (PostgreSQL) · `perspectivas_semanales` (MongoDB, usuario `kaizen_api` de solo lectura).

### 6.9 Cápsulas (`/capsulas`) · usuario (F3)

| Método y ruta | Cuerpo | Respuesta |
|---|---|---|
| `POST /capsulas` | `{"habito_id": "…", "mensaje": "…", "racha_objetivo": 21, "tiene_foto": true}` | **201** Capsula · 404 · 422 |
| `GET /capsulas?estado=sellada\|abierta` | — | 200 `[Capsula]` (nunca incluye el mensaje) |
| `POST /capsulas/{id}/abrir` | — | 200 `{"id","mensaje","abierta_en"}` · 409 `capsula-sellada` con `{"racha": 9, "objetivo": 21}` · 404 |

- La API cifra el mensaje con **AES-256-GCM**: `nonce(12) ‖ cifrado ‖ tag(16)`, con AAD = los 16 bytes del UUID de la cápsula y `llave_version = 1`.
- La **foto nunca se sube**: vive en la carpeta privada de la app y el servidor solo sabe `tiene_foto`. En escritorio y web se sella solo con el mensaje.
- Abrir una cápsula ya abierta devuelve otra vez el mensaje (200).
- Flujo de crear hábito con cápsula: primero `POST /habitos` y después la pantalla de cápsula con el objetivo preseleccionado (2 pasos).

### 6.10 Administración (`/admin`) · admin · escritorio y web

| Método y ruta | Cuerpo / parámetros | Respuesta |
|---|---|---|
| `GET /admin/usuarios` | `?region=&rol=&suspendido=true&email=&pagina=&por_pagina=` | 200 paginado de `{"id","region","pais","rol","fecha_registro","nombre_mascara","email_mascara","bloqueado","consiente_senales","suspendido","suspendido_en","suspension_motivo"}` |
| `PATCH /admin/usuarios/{id}` (B5) | `{"suspendido": true, "motivo": "Publica spam"}` o `{"suspendido": false}` | 200 el usuario (como en la lista) · 403 `rol-insuficiente` (también al intentar suspenderse a sí mismo o a otro admin) · 404 · 422 (motivo de 3–200) |
| `GET /admin/metricas` (B9) | — | 200 `{"resumen": {"usuarios_activos", "variacion", "cumplimiento_global", "categorias_activas"}, "por_region": [{"region","categoria","usuarios","habitos","racha_promedio"}]}` |
| `GET /admin/categorias` | — | 200 `[{"id","nombre","activa"}]` (incluye las inactivas) |
| `POST /admin/categorias` (B6) | `{"nombre": "Música"}` | **201** `{"id","nombre","activa": true}` · 409 `nombre-duplicado` · 422 |
| `PATCH /admin/categorias/{id}` (B6) | `{"nombre"?: "…", "activa"?: false}` | 200 · 404 · 409 · 422 |
| `GET /admin/indicadores/{codigo}` (B8) | `codigo` de `I1` a `I6` | 200 `{"codigo","titulo","grafica","origen","datos_sinteticos","periodo","series":[…],"generado_en"}` (la forma de cada elemento de `series` depende del indicador: ver `MongoDB_analitica_y_ETL.pdf`, sección 6) · 404 si el código no existe · 503 `analitica-no-disponible` |
| `GET /admin/cluster` (B7) | — | **Pendiente**: necesita un certificado de cliente para Patroni. Mientras tanto responde 503 `servicio-no-disponible` y el panel oculta la tarjeta |

- **Búsqueda por correo:** solo **exacta**, por HMAC en `directorio_usuarios`. No hay búsqueda parcial.
- **No hay cambio de rol** desde la app: a los administradores los crea el DBA.
- Todo agregado respeta **k ≥ 5** usuarios por grupo.
- BD: `v_usuario_admin` · `CALL sp_admin_suspender_usuario(admin, usuario, suspender, motivo, ip)` · `CALL sp_admin_crear_categoria(admin, nombre, ip, NULL)` · `CALL sp_admin_actualizar_categoria(admin, id, nombre, activa, ip)` · `v_metricas_region` · MongoDB `metricas_globales` y `resumen_diario`. Los procedimientos vuelven a comprobar en la base que quien llama es admin activo (KZ010), y todo queda en la bitácora.

### 6.11 Salud (interno)

| Ruta | Respuesta |
|---|---|
| `GET /salud` | 200 `{"estado": "ok"}` si el proceso está vivo |
| `GET /salud/listo` | 200 si hay conexión al primario; 503 si no |

Nginx no las publica hacia internet. Las consultan Prometheus y la prueba de despliegue.

---

### 6.12 Tareas programadas (no son endpoints)

Corren en **nodo1** con el mismo paquete Python (`python -m kaizen.tareas <tarea>`), con temporizadores de systemd. Se conectan con el rol **`kaizen_tareas`**, que solo puede ejecutar estos 4 procedimientos y no lee ninguna tabla. Su contraseña está en nodo1, en `/etc/kaizen/tareas.env` (`KAIZEN_TAREAS_DB_PASSWORD`). La cadena de conexión es la misma de la API, con `user=kaizen_tareas`.

| Tarea | Cuándo (UTC) | Qué llama |
|---|---|---|
| `escalera` | Diario 08:00 | `CALL sp_generar_sugerencias(NULL, current_date, NULL)` → número de sugerencias creadas |
| `limpieza` | Diario 08:30 | `CALL sp_limpiar_expirados(NULL, NULL)` → sesiones y tokens de recuperación borrados |
| `particiones` | Día 25 de cada mes | `CALL sp_crear_particion_bitacora(<primer día del mes siguiente>)` (ya existen hasta jun-2027) |
| `verificar-rachas` | Domingos 09:00 | `CALL sp_reconstruir_rachas(NULL, NULL)` → debe dar 0 (si no, avisar: un trigger falló) |

## 7. Resumen: endpoint → objeto de la base

| Endpoint | PostgreSQL (`kaizen`) | Permiso de `kaizen_api` |
|---|---|---|
| `/auth/registro` | `sp_registrar_usuario`, `sesion` | EXECUTE, INSERT |
| `/auth/login`, `/auth/renovar`, `/auth/salir` | `directorio_usuarios`, `usuario`, `sesion` (+ trigger de cuenta suspendida) | SELECT, UPDATE de columnas, INSERT |
| `/auth/recuperar`, `/auth/restablecer` | `sp_solicitar_recuperacion`, `sp_restablecer_contrasena` (tabla `recuperacion_contrasena` sin acceso directo) | EXECUTE |
| `/cuenta*` | `usuario`, `sp_retirar_consentimiento_senales`, `sp_eliminar_cuenta` | SELECT, UPDATE de columnas, EXECUTE |
| `/categorias` | `categoria` | SELECT |
| `/habitos*` | `habito`, `v_racha_vigente`, `nivel_habito`, `sugerencia_ajuste` | SELECT, INSERT y UPDATE de columnas |
| `/registros*` | `sp_registrar_checkin` | EXECUTE |
| `/escalera*` | `sugerencia_ajuste`, `sp_responder_sugerencia` | SELECT, EXECUTE |
| `/progreso` | `registro`, `fn_cumplimiento`, `fn_dia_programado` | SELECT, EXECUTE |
| `/senales` | `senal_diaria` | SELECT, INSERT, UPDATE (animo, energia) |
| `/capsulas*` | `capsula` (sin `mensaje_cifrado`), `sp_abrir_capsula`, `fn_rachas` | SELECT de columnas, INSERT, EXECUTE |
| `/admin/*` | `v_usuario_admin`, `v_metricas_region`, `sp_admin_*` | SELECT, EXECUTE |

En **cada** transacción con usuario autenticado, la API hace primero `SELECT set_config('kaizen.usuario_id', '<sub>', true)`. Sin eso, la RLS devuelve 0 filas.

## 8. Reglas para la app (resumen)

1. Nunca manda `usuario_id`, `region` ni `rol`: salen del token.
2. Genera el `id` (UUID v4) de cada check-in **antes** de guardarlo en su base local. Así el reenvío es idempotente. En la cola guarda la **fecha local original**; nunca la cambia por la del día en que se sincroniza.
3. Reintenta solo lecturas y check-ins, ante 503 o errores de red. Nunca reintenta registro, login, restablecer ni operaciones de admin.
4. La meta de un hábito se muestra de **solo lectura** al editar ("cambia con la Escalera").
5. No guarda el mensaje de la cápsula en claro ni los tokens en su base local.
6. En web: el token de renovación vive solo en memoria y la caché local se borra al cerrar sesión.
7. Para "¿Olvidaste tu contraseña?" usa `/auth/recuperar` y muestra siempre el mismo mensaje.
8. Manda `X-Zona-Horaria` (zona IANA del dispositivo) en **todas** las peticiones (§1.1). Antes de agregar `flutter_timezone`, verificarlo en pub.dev como cualquier otro paquete.

## 9. Pendiente

| Tema | Qué falta | Quién |
|---|---|---|
| `GET /admin/cluster` (B7) | Emitir el certificado de cliente `kaizen-api-patroni` con la CA (requiere la frase de la CA) | Jael |
| Servicio de la API y temporizadores de las tareas | Usuario de sistema `kaizen`, unidades systemd `kaizen-api` y `kaizen-tareas-*.timer` en nodo1 | Jael + Jesús |
| Correo real (B4b) | Cuenta SMTP y sus variables en `/etc/kaizen/api.env` (ver LEEME, sección "Correo") | Jael + Jesús |
| App web en Nginx (A6) | `location /` con su CSP propia, cuando exista el build de Flutter web | Jael + Samuel |
| `openapi.json` | Generarlo desde FastAPI y comprobar que coincida con este contrato | Jesús |
