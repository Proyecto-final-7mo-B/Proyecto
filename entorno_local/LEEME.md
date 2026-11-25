# Kaizen · entorno local para desarrollar el backend

Este paquete levanta en tu computadora **la misma base de datos que corre en la nube**, con datos de prueba, para que
programes la API sin tocar los servidores.

| Qué trae | Detalle |
|---|---|
| PostgreSQL 16 | Estructura **exacta** del clúster, tomada del primario el 23-nov-2026 **con los ajustes de frontend y backend**: Escalera por hábito, suspensión de usuarios, categorías administrables, recuperación de contraseña y catálogo de 8 categorías. Esquema `kaizen`: 13 tablas, funciones, triggers, procedimientos, vistas, permisos y Row-Level Security |
| MongoDB 4.4 | Base `kaizen_analitica` con sus 3 colecciones, índices y usuarios, igual que en el HomeLab. Vacía: la llena el ETL |
| Mailpit | Servidor de correo de desarrollo: atrapa los correos de "recuperar contraseña" y los muestra en http://localhost:8025 |
| Poblador | Script de Python que llena PostgreSQL con ~45 usuarios, ~130 hábitos, ~4,000 check-ins, señales, cápsulas cifradas, sugerencias de la Escalera y una cuenta suspendida |
| Cuentas de prueba | 5 cuentas fijas para iniciar sesión (abajo) |
| **`contrato/CONTRATO_API.md`** | **El contrato que siguen la API y la app**: rutas, JSON de entrada y salida, errores, límites y qué objeto de la base usa cada endpoint. Léelo primero |
| **`contrato/MongoDB_analitica_y_ETL.pdf`** | **Para qué usamos MongoDB, la forma de cada colección, el ETL que la llena, el Laboratorio, los indicadores I1–I6 y lo que lee la API** |
| `contrato/paises_estados.json` | Lista de países y estados que acepta la base (la misma que `fn_region`), para el formulario de registro y la validación de la API |

> Todo escucha solo en `127.0.0.1`. Las contraseñas y llaves de `.env.ejemplo` son **de desarrollo**: no son las de
> producción ni sirven en los servidores.

---

## 1. Requisitos

- **Docker** con **Compose v2** (`docker compose version` debe responder). En Windows o Mac, Docker Desktop.
- Unos 600 MB libres para las imágenes.
- **Windows:** descomprime el zip tal cual. Si abres y guardas los `.sh` con un editor que los convierta a fin de línea
  CRLF, la inicialización falla (ver *Problemas comunes*).

## 2. Arranque (la primera vez)

```bash
cd entorno_local                     # dentro del repositorio
cp .env.ejemplo .env                 # en Windows (PowerShell): copy .env.ejemplo .env
docker compose up -d                 # descarga las imágenes y crea las bases (~1 min la primera vez)
docker compose ps                    # espera a que postgres y mongo digan "healthy"
docker compose run --rm poblar       # llena PostgreSQL con datos de prueba (~5 s)
```

Al terminar, el poblador imprime cuántas filas quedaron en cada fragmento y comprueba que el login, el directorio por
HMAC y la RLS funcionen como lo hará la API.

Opciones del poblador:

```bash
docker compose run --rm poblar --usuarios 500 --dias 120     # más volumen
docker compose run --rm poblar --semilla 7                   # otros datos (misma semilla = mismos datos)
```

Solo corre sobre una base vacía. Para volver a poblar, reinicia desde cero (sección 6).

## 3. Cuentas de prueba

Todas usan la contraseña `KAIZEN_DEMO_PASSWORD` de tu `.env` (por defecto `KaizenDemo2026!`).

| Correo | Región | Para probar |
|---|---|---|
| `demo@kaizen.test` | MX-NORTE | 4 hábitos (uno con la **Escalera apagada**); uno con **racha de 25 días**; **cápsula de 21 días lista para abrir** y otra de 66 que todavía no se puede; sugerencias pendientes de la Escalera; señales de ánimo |
| `admin@kaizen.test` | MX-CENTRO-SUR | Rol `admin` (vistas enmascaradas, métricas) |
| `latam@kaizen.test` | LATAM | Tercer fragmento; cápsula sellada; sugerencias pendientes |
| `nuevo@kaizen.test` | MX-CENTRO-SUR | Recién registrado: sin hábitos ni consentimiento de señales |
| `suspendido@kaizen.test` | MX-NORTE | Suspendido por el admin: el login debe responder 403 `cuenta-suspendida`, y la base no le deja abrir sesión (KZ012) |
| `usuario001@kaizen.test` … | Las 3 | Usuarios sintéticos con distintos niveles de constancia |

## 4. Cómo se conecta tu API en local

Variables (ya están en `.env`; tu API puede leer el mismo archivo con pydantic-settings):

| Variable | Uso |
|---|---|
| `KAIZEN_DB_PASSWORD` | Contraseña del rol `kaizen_api`. **Mismo nombre que en producción** (`/etc/kaizen/api.env` en nodo1) |
| `KAIZEN_EMAIL_HMAC_KEY` | Llave del HMAC del correo (directorio de usuarios) |
| `KAIZEN_CAPSULA_KEY_V1` | Llave AES-256-GCM de las cápsulas, versión 1 |
| `KAIZEN_MONGO_API_PASSWORD` | Usuario `kaizen_api` de MongoDB (solo lectura) |
| `KAIZEN_SMTP_*`, `KAIZEN_URL_RESTABLECER` | Envío del correo de recuperación (en local van a Mailpit) |
| `KAIZEN_JWT_LLAVE_PRIVADA`, `KAIZEN_JWT_KID` | Firma de los JWT (Ed25519). La del `.env` es **de desarrollo** |
| `KAIZEN_ZONA_HORARIA_DEFECTO` | Zona que usa la API si la app no manda `X-Zona-Horaria` |
| `KAIZEN_TAREAS_DB_PASSWORD` | Rol `kaizen_tareas`, para las tareas programadas (sección 5.3) |

**PostgreSQL**: en local y en producción la cadena es la misma, salvo los hosts y TLS:

```text
# LOCAL
host=localhost port=5432 dbname=kaizen user=kaizen_api
application_name=kaizen-api options='-c search_path=kaizen'

# PRODUCCIÓN (nodo1): la pone infraestructura en la configuración del servidor
host=10.10.0.1,10.10.0.2,10.10.0.3 port=5432,5432,5432 dbname=kaizen user=kaizen_api
target_session_attrs=read-write sslmode=verify-full sslrootcert=/etc/kaizen/ca.crt
connect_timeout=5 application_name=kaizen-api options='-c search_path=kaizen'
```

La contraseña **no** va en la cadena: pásala aparte (`password=os.environ["KAIZEN_DB_PASSWORD"]`). Haz que la cadena
completa sea configurable (por ejemplo `KAIZEN_DB_CONNINFO`) para no tocar código al desplegar.

**MongoDB:**

```text
mongodb://kaizen_api:<KAIZEN_MONGO_API_PASSWORD>@localhost:27017/kaizen_analitica?authSource=kaizen_analitica
```

En producción es `10.10.0.10:27017` con `tls=true` y la CA de Kaizen. MongoDB es 4.4: usa una versión de pymongo que
todavía lo soporte (revisa la tabla de compatibilidad de pymongo antes de fijarla).

## 5. Reglas de la base que la API debe respetar

La base ya hace cumplir estas reglas. Si las olvidas, verás errores, no datos mal guardados.

1. **Conéctate siempre como `kaizen_api`**, nunca como `postgres`. Con `postgres` todo "funciona" porque se salta los
   permisos y la RLS, pero en el servidor va a fallar.
2. **Row-Level Security.** En cada transacción, antes de leer o escribir datos del usuario:
   ```python
   conn.execute("SELECT set_config('kaizen.usuario_id', %s, true)", (str(usuario_id),))
   ```
   Si no lo haces, las consultas devuelven **0 filas**: la base falla cerrada. El `true` hace que valga solo para esa
   transacción, lo que es seguro con un pool de conexiones.
3. **La región sale del JWT**, nunca del cuerpo de la petición. Inclúyela siempre en el `WHERE`
   (`region = %s AND usuario_id = %s`) para que PostgreSQL lea un solo fragmento.
4. **Escrituras con reglas: solo con procedimientos.** `kaizen_api` no tiene `UPDATE`/`DELETE` directos sobre esas
   tablas:

   | Operación | Procedimiento |
   |---|---|
   | Registro de usuario | `CALL sp_registrar_usuario(id, email_hmac, nombre, email, password_hash, pais, estado, consiente_senales, ip, NULL)` → devuelve la región |
   | Check-in (idempotente: el `id` lo genera la app) | `CALL sp_registrar_checkin(region, usuario, id, habito, fecha, cumplido, valor, origen, NULL)` → devuelve la racha actual |
   | Aceptar o rechazar una sugerencia | `CALL sp_responder_sugerencia(region, usuario, sugerencia, aceptar)` |
   | Abrir una cápsula | `CALL sp_abrir_capsula(region, usuario, capsula, NULL, NULL)` → devuelve `mensaje_cifrado` y `llave_version` |
   | Borrar la cuenta (ARCO) | `CALL sp_eliminar_cuenta(region, usuario, ip)` |
   | Retirar el consentimiento de señales | `CALL sp_retirar_consentimiento_senales(region, usuario, NULL)` |
   | Pedir enlace de recuperación | `CALL sp_solicitar_recuperacion(email_hmac, sha256_hex(token), ip, NULL, NULL)` → `p_enviar`, `p_nombre` |
   | Restablecer la contraseña | `CALL sp_restablecer_contrasena(sha256_hex(token), password_hash, ip)` |
   | Admin: suspender o reactivar | `CALL sp_admin_suspender_usuario(admin, usuario, suspender, motivo, ip)` |
   | Admin: crear o editar categoría | `CALL sp_admin_crear_categoria(admin, nombre, ip, NULL)` → id · `CALL sp_admin_actualizar_categoria(admin, id, nombre, activa, ip)` |

   Crear hábitos, registrar señales y crear sesiones sí son `INSERT` directos, en las columnas permitidas.
   Encender o apagar la Escalera de un hábito es `UPDATE habito SET escalera_activa = …` (permitido).
5. **Siempre parámetros `%s`** de psycopg. Nunca armes SQL con f-strings.
6. **Errores propios.** Los triggers y procedimientos lanzan `SQLSTATE` que empiezan con `KZ`. Tradúcelos a HTTP:

   | Código | Significado | HTTP sugerido |
   |---|---|---|
   | KZ001 | No se pudo completar el registro (correo ya existe; el mensaje es genérico a propósito) | 409 |
   | KZ002 | País o estado fuera del servicio | 422 |
   | KZ003 | Fecha inválida (futura o anterior a la creación del hábito) | 422 |
   | KZ004 | No encontrado (o no es tuyo) | 404 |
   | KZ005 | Condición no cumplida (cápsula sin la racha requerida, sugerencia ya resuelta) | 409 |
   | KZ006 | Campo inmutable | 409 |
   | KZ007 | Hábito archivado | 409 |
   | KZ008 | Sin consentimiento para señales | 403 |
   | KZ009 | La bitácora es de solo inserción | 500 (es un error de programación) |
   | KZ010 | Se requiere rol de administrador (o un admin intentó suspenderse a sí mismo o a otro admin) | 403 |
   | KZ011 | Dato inválido (motivo de suspensión, nombre de categoría) | 422 |
   | KZ012 | Cuenta suspendida (no puede abrir ni renovar sesión) | 403 |
   | KZ013 | Ya existe una categoría con ese nombre | 409 |
   | KZ014 | La categoría está desactivada | 422 |
   | KZ015 | El enlace de recuperación no es válido o ya venció | 400 |

   La tabla completa con el `type` de cada error está en `contrato/CONTRATO_API.md`, sección 3.

7. **Tiempos máximos de `kaizen_api`** (iguales a producción): 5 s por consulta y 15 s de transacción inactiva. Si
   te detienes mucho tiempo en un breakpoint dentro de una transacción, la base cierra la conexión. Es esperado.

### Convenciones criptográficas que usaron los datos de prueba

Tu código debe hacer **exactamente** esto o el login y las cápsulas no van a coincidir. Si el equipo decide otra
cosa, cambien también `poblar/poblar.py` y vuelvan a poblar.

| Qué | Cómo |
|---|---|
| Directorio de usuarios | `hmac.new(bytes.fromhex(KAIZEN_EMAIL_HMAC_KEY), correo.strip().lower().encode(), sha256).hexdigest()` |
| Contraseña | Argon2id con `argon2.PasswordHasher()` (parámetros por defecto de argon2-cffi) |
| Cápsula | AES-256-GCM (`cryptography`, `AESGCM`). Se guarda `nonce(12) ‖ cifrado ‖ tag(16)`. **AAD = `capsula_id.bytes`** (los 16 bytes del UUID), para que un mensaje no se pueda mover a otra cápsula. `llave_version = 1` |

Ejemplo de descifrado al abrir una cápsula:

```python
mensaje, version = conn.execute("CALL sp_abrir_capsula(%s, %s, %s, NULL, NULL)",
                                (region, usuario_id, capsula_id)).fetchone()
texto = AESGCM(llave).decrypt(mensaje[:12], mensaje[12:], capsula_id.bytes).decode()
```

## 5.1 Secretos: desarrollo y producción

Tu `.env` trae **llaves de desarrollo**. Con ellas funcionan el login, los JWT y las cápsulas de los datos de prueba.
Las de **producción son otras**: se generaron dentro de nodo1 el 23-nov-2026 y **no vienen en este paquete**. Con la
llave privada de los JWT cualquiera podría fabricar un token de administrador en producción, así que nunca se reparte.
Tu código no las necesita: lee las mismas variables y en el servidor toman otro valor.

| Variable | Local (`.env`) | Producción (la pone Jael) |
|---|---|---|
| `KAIZEN_DB_PASSWORD` | `kaizen_api_local_dev` | nodo1 `/etc/kaizen/api.env` |
| `KAIZEN_JWT_LLAVE_PRIVADA`, `KAIZEN_JWT_KID` | Llave de desarrollo, `kid = kaizen-dev` | nodo1 `/etc/kaizen/api.env`, `kid = kaizen-2026-11` |
| `KAIZEN_EMAIL_HMAC_KEY` | De desarrollo | nodo1 `/etc/kaizen/api.env` |
| `KAIZEN_CAPSULA_KEY_V1` | De desarrollo | nodo1 `/etc/kaizen/api.env` |
| `KAIZEN_TAREAS_DB_PASSWORD` | `kaizen_tareas_local_dev` | nodo1 `/etc/kaizen/tareas.env` |
| `KAIZEN_MONGO_API_PASSWORD` | `mongo_api_local_dev` | nodo1 `/etc/kaizen/api.env` (el original vive en el HomeLab) |
| `KAIZEN_SMTP_*` | Mailpit | Pendiente: cuenta SMTP |

Jael guarda una copia de los de producción en su laptop. Si en algún momento necesitas probar algo **en el servidor**,
lo hacen juntos en nodo1; los valores no se copian a tu máquina.

**Cómo cargar la llave de firma** (PyJWT + cryptography):

```python
import base64, jwt
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

privada = Ed25519PrivateKey.from_private_bytes(base64.b64decode(cfg.jwt_llave_privada))
publica = privada.public_key()
token = jwt.encode({...claims...}, privada, algorithm="EdDSA", headers={"kid": cfg.jwt_kid})
claims = jwt.decode(token, publica, algorithms=["EdDSA"])   # SIEMPRE fijar algorithms
```

## 5.2 Zona horaria: error conocido y lo que debe hacer la API

**El error.** La base trabaja en UTC y calcula "hoy" con `current_date`. A las 7 pm en México ya es el día siguiente
en UTC, así que entre las **18:00 y las 24:00** la vista `v_racha_vigente` dice que la racha de quien no ha marcado
"hoy" está rota (**0**), aunque su día no ha terminado. También afecta a la validación de fecha futura de un check-in
y al cumplimiento de la Escalera.

**Compruébalo** (entre las 18:00 y las 23:59 de México):

```bash
docker exec -i kaizen-pg psql -U postgres -d kaizen < postgres/cambios/demo_zona_horaria.sql
# sin arreglo: racha_que_ve_la_app = 0   ·   con arreglo: racha_que_ve_la_app = 10
```

**Lo que tienes que hacer** (no requiere cambiar la base):

1. Lee la cabecera `X-Zona-Horaria` de cada petición. La app manda la zona IANA del dispositivo, por ejemplo
   `America/Mexico_City` o `America/Bogota`.
2. Valídala contra `zoneinfo.available_timezones()`. Si falta, usa `KAIZEN_ZONA_HORARIA_DEFECTO`; si no es válida,
   responde 422 `validacion`.
3. En la **unidad de trabajo**, al abrir cada transacción y junto a la RLS, fija la zona **con parámetro**:
   ```python
   conn.execute("SELECT set_config('kaizen.usuario_id', %s, true), set_config('TimeZone', %s, true)",
                (str(usuario_id), zona))
   ```
   El `true` hace que solo valga para esa transacción, así que no "contamina" la conexión del pool. Desde ese
   momento `current_date`, la racha vigente y las validaciones usan la fecha del usuario. **Nunca** armes
   `SET TIME ZONE` concatenando texto: es inyección SQL.
4. Valida el parámetro `?fecha=` (hoy-1 a hoy+1) contra `datetime.now(ZoneInfo(zona)).date()`, no contra UTC.
5. La tarea diaria de la Escalera corre a las **08:00 UTC**, no a medianoche UTC (sección 5.3).

Prueba sugerida: un test de integración que fije `TimeZone` a `America/Mexico_City` y a `UTC` en la misma transacción
y compare `v_racha_vigente`, como hace `demo_zona_horaria.sql`.

## 5.3 Tareas programadas (rol `kaizen_tareas`)

Hay trabajos que no son de ningún usuario: generar las sugerencias de la Escalera, borrar sesiones vencidas y crear
la partición del mes de la bitácora. `kaizen_api` no puede hacerlos (la RLS le impide tocar las sesiones de otros), así
que existe el rol **`kaizen_tareas`**. Solo puede ejecutar estos 4 procedimientos y no lee ninguna tabla.

| Tarea (`python -m kaizen.tareas …`) | Cuándo (UTC) | Llamada |
|---|---|---|
| `escalera` | Diario 08:00 | `CALL sp_generar_sugerencias(NULL, current_date, NULL)` |
| `limpieza` | Diario 08:30 | `CALL sp_limpiar_expirados(NULL, NULL)` → sesiones y tokens borrados |
| `particiones` | Día 25 de cada mes | `CALL sp_crear_particion_bitacora('<primer día del mes siguiente>')` |
| `verificar-rachas` | Domingos 09:00 | `CALL sp_reconstruir_rachas(NULL, NULL)` → debe dar 0 |

En local se conecta igual que la API, con `user=kaizen_tareas` y `KAIZEN_TAREAS_DB_PASSWORD`. En producción corre en
nodo1 con temporizadores de systemd (los prepara Jael con tu paquete).

### Correo de recuperación de contraseña

En local, la API manda el correo a **Mailpit** (`KAIZEN_SMTP_HOST=localhost`, puerto `1025`, sin TLS ni usuario) y tú
lo ves en **http://localhost:8025**. No sale nada a internet.

Para producción hace falta:

1. **Una cuenta SMTP.** Lo más sencillo es una cuenta de Gmail **solo para el proyecto**, con verificación en dos pasos y
   una *contraseña de aplicación* (`smtp.gmail.com`, puerto 587, STARTTLS, hasta 500 correos al día). Otra opción
   es Brevo (plan gratis de 300 al día; pide verificar el remitente). No podemos firmar con nuestro propio dominio
   porque `cloudapp.azure.com` no es nuestro, así que los correos pueden caer en spam. Para el proyecto es aceptable.
2. **Puerto 587 de salida.** Azure bloquea el 25, pero el 587 está permitido y ufw deja salir todo.
3. **Variables en nodo1**, en `/etc/kaizen/api.env` (las pone Jael, nunca en el repositorio): `KAIZEN_SMTP_HOST`,
   `KAIZEN_SMTP_PUERTO=587`, `KAIZEN_SMTP_TLS=starttls`, `KAIZEN_SMTP_USUARIO`, `KAIZEN_SMTP_CONTRASENA`,
   `KAIZEN_SMTP_REMITENTE` y `KAIZEN_URL_RESTABLECER=https://proyecto-kaizen.northcentralus.cloudapp.azure.com/restablecer`.
4. **En el código:** `smtplib` (biblioteca estándar) o `aiosmtplib`, con el envío en segundo plano para que la respuesta
   de `/auth/recuperar` tarde lo mismo exista o no la cuenta.

## 6. Comandos útiles

```bash
docker compose ps                                   # estado
docker compose logs -f postgres                     # bitácoras (también: mongo)
docker compose stop                                 # apagar sin perder datos
docker compose start                                # volver a encender

# Consola SQL
docker exec -it kaizen-pg psql -U postgres -d kaizen               # como administrador
docker exec -it kaizen-pg psql -U kaizen_api -d kaizen              # como la API (dentro del contenedor no pide contraseña;
                                                                    # desde tu máquina, por el puerto, sí)

# Consola de MongoDB
docker exec -it kaizen-mongo mongo -u kaizen_api -p --authenticationDatabase kaizen_analitica kaizen_analitica

# EMPEZAR DE CERO (borra las bases y vuelve a crear la estructura)
docker compose down -v && docker compose up -d
docker compose run --rm poblar
```

Consultas útiles en `psql`:

```sql
SET search_path = kaizen;
\dt                                   -- tablas
\df                                   -- funciones y procedimientos
\dp habito                            -- permisos (qué puede hacer kaizen_api)
SELECT tableoid::regclass, count(*) FROM registro GROUP BY 1;   -- filas por fragmento
SELECT u.email, h.nombre, r.racha_actual, r.racha_maxima
  FROM usuario u JOIN habito h ON h.usuario_id = u.id JOIN racha r ON r.habito_id = h.id
 WHERE u.email = 'demo@kaizen.test';
```

## 7. Diferencias con producción

| Aspecto | Local | Producción |
|---|---|---|
| Nodos | 1 PostgreSQL | 3 nodos con Patroni (failover automático); usa `target_session_attrs=read-write` |
| TLS | Sin TLS | TLS 1.3 obligatorio con `verify-full` (PostgreSQL y MongoDB) |
| Contraseñas y llaves | Las de `.env` | Otras, en `/etc/kaizen/api.env` de nodo1 (solo root) |
| Datos | Sintéticos | Hoy vacía; datos reales cuando abra la app |
| Escrituras | Inmediatas | Síncronas: cada `COMMIT` espera a la réplica (unos ms más) |
| Esquema | Este dump | El mismo; se cambia solo en el primario |
| Correo | Mailpit (no sale a internet) | SMTP real (pendiente de configurar) |

## 8. Problemas comunes

| Síntoma | Causa y solución |
|---|---|
| `port is already allocated` o `address already in use` | Ya tienes PostgreSQL o MongoDB usando ese puerto. Cambia `KAIZEN_PG_PUERTO` o `KAIZEN_MONGO_PUERTO` en `.env` (p. ej. 55432) y ajusta tu cadena de conexión |
| `Falta .env: copia .env.ejemplo a .env` | No creaste el `.env` (paso 2) |
| `/bin/bash^M: bad interpreter` o `$'\r': command not found` en los logs | Los `.sh` quedaron con CRLF (Windows). Conviértelos a LF (en VS Code, abajo a la derecha: CRLF → LF), luego `docker compose down -v && docker compose up -d` |
| Cambiaste `.env` y las contraseñas no cambiaron | Los scripts de inicio solo corren con el volumen vacío: `docker compose down -v && docker compose up -d` |
| `La base ya tiene usuarios` | El poblador solo corre una vez por base. Empieza de cero (sección 6) |
| La API ve 0 filas | Te faltó el `set_config('kaizen.usuario_id', …, true)` en esa transacción (sección 5) |
| `permission denied for table …` | Esa operación va por procedimiento, o no está en la matriz de permisos. Revisa con `\dp tabla` |
| `canceling statement due to statement timeout` | Una consulta tardó más de 5 s: falta un índice o un filtro por región |

## 9. Lo que no se debe hacer

- No apuntes la API ni el poblador al clúster. El poblador se niega a correr si `KAIZEN_ENTORNO` no es `local`.
- No subas `.env` a Git (ya está en `.gitignore`). Sí puedes subir `.env.ejemplo`.
- No cambies el esquema "a mano" en tu base y luego en el código: cualquier cambio de estructura se acuerda con
  Jael, que lo aplica en el clúster. Después se regenera este dump.

---

### Para infraestructura: regenerar el dump cuando cambie el esquema

```bash
ssh nodo1-proyecto 'cd /tmp && sudo -u postgres pg_dump -d kaizen --schema-only' > postgres/kaizen_esquema.sql
# ejecutarlo contra el LÍDER vigente (sudo kpatronictl list); revisar que no traiga datos ni contraseñas:
grep -cE '^COPY |PASSWORD ' postgres/kaizen_esquema.sql      # debe dar 0
```

Si cambia el catálogo de categorías en el clúster, actualizar también `postgres/init/20_catalogo.sh` (el dump no lleva datos).
Cada cambio de estructura se guarda además en `postgres/cambios/` con sus pruebas.

*Generado el 23-nov-2026. IA: asistido (Claude); revisión: Jael Contreras.*
