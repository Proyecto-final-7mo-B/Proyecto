# Paso 8 · Base local y modo sin conexión (F5)

**Estado:** terminado · **Fecha:** 27-nov-2026 (ajustado al catálogo con respaldo científico, contrato v1.6) ·
**IA:** asistido (Claude), revisado por Samuel Rizo

La app ya funciona **sin red**: Hoy, Hábitos y el detalle se ven con la última copia, y el check-in se guarda en el
dispositivo y se envía solo cuando vuelve la conexión. **Criterio del paso (plan F5): en modo avión el check-in se
guarda y, al reconectar, llega una sola vez.** Lo comprueba `integration_test/sin_conexion_test.dart`.

No hay pantallas nuevas. Arriba de todo aparece el aviso **"Sin conexión · 1 registro por enviar"**
(`BannerSinConexion` del Paso 2) mientras no haya red o quede algo en la cola.

## Cómo funciona

```
Pantalla → ViewModel → Repositorio local ──┬── Repositorio remoto (API o fake) ── servidor
                                            └── AlmacenLocal ── BaseLocal (SQLite con drift)
                                                       ▲
                                     Sincronizador ────┘  (envía la cola con POST /registros/lote)
```

- **Lecturas** (categorías, hábitos, un hábito, sus check-ins): primero el servidor y se guarda la copia. Si falla
  **por red** (sin conexión, tiempo agotado, 502/503), se usa la copia. Si nunca se guardó nada, sale el error de
  siempre.
- **Check-in** (`RegistrosRepositoryLocal`):
  1. **guarda el check-in y lo encola en una sola transacción**: o quedan los dos o ninguno;
  2. intenta enviarlo al momento (`POST /registros`):
     - si llega, sale de la cola y la copia del hábito toma la racha real;
     - si falla **por red**, se queda en la cola y se devuelve la racha **estimada**: en la pantalla el check-in se
       queda marcado;
     - si el servidor lo **rechaza** (p. ej., hábito archivado), se quita de la cola, vuelve el check-in que había y
       la pantalla se regresa con el aviso, como antes.
- **Lo pendiente siempre se ve:** al leer del servidor se aplican los check-ins que siguen en la cola (el servidor
  aún no los conoce). Así lo marcado sin conexión no "desaparece" si vuelve la red antes de sincronizar.
- **Racha estimada:** la última racha del servidor más o menos 1, según el check-in local de ese día. Al sincronizar,
  el servidor manda la real.
- **Sincronizador** (`data/sync/sincronizador.dart`). Envía la cola:
  - al abrir la app y al iniciar sesión;
  - cuando vuelve la red (`connectivity_plus`);
  - cuando la app regresa al frente;
  - cada minuto mientras queden pendientes (por si había red pero el servidor estaba caído).

  Manda lotes de **hasta 100** con `origen: offline` y la **fecha local original**. Por cada elemento:
  - `aceptado`: sale de la cola;
  - `rechazado`: se marca con su motivo, **no se reintenta** (contrato §6.5), se quita su check-in local y se avisa
    una vez ("Un check-in hecho sin conexión no se guardó: El hábito está archivado.").

  Si el envío falla por red, todo se queda y se anota el intento. Dos llamadas al mismo tiempo hacen un solo envío.
- **Crear, editar y archivar un hábito y la Escalera necesitan al servidor:** sin red dan el error "Sin conexión a
  internet." (no se encolan).
- **Al cerrar sesión** primero se intenta enviar la cola y después **se borra toda la base local**. Pasa también si
  la sesión se cierra sola (contraseña cambiada, cuenta suspendida). Los datos de una cuenta no deben quedar para la
  siguiente, y en web así lo pide el diseño (§7.5).
- **Modo *fake*:** usa la misma capa local. En la app, el "servidor" en memoria obedece al monitor de red, así que
  **en el teléfono el modo avión funciona de verdad**. En las pruebas, la red se apaga con `MonitorConexionManual`.

### Cambio de comportamiento respecto al Paso 6

Antes, cualquier falla del check-in regresaba la fila y avisaba "No se guardó el check-in…". Ahora:
- **sin red**, el check-in se queda marcado y en la cola;
- solo un **rechazo** del servidor la regresa.

Se actualizaron las pruebas y `06_hoy.md`.

## Tablas locales (`data/services/base_local/tablas.dart`)

| Tabla | Contenido | Se usa desde |
|---|---|---|
| `habitos` | JSON del contrato (racha, nivel y `hoy`) | Paso 8 |
| `categorias` | Copia del catálogo **con su árbol** (`datos`: subcategorías, unidades permitidas y referencia científica) y su `orden` | Paso 8 |
| `registros` | Check-ins, hasta 366 días por hábito; **`UNIQUE (habito_id, fecha)`** | Paso 8 |
| `cola_pendientes` | `id` UUID, **fecha local original**, intentos, último error, `rechazado`; uno por hábito y día | Paso 8 |
| `recordatorios` | Hora por hábito (copia de las notificaciones programadas) | Paso 8 |
| `marcas` | Si la lista de hábitos ya se guardó alguna vez ("nunca se cargó" ≠ "no hay hábitos"). Desde el Paso 9 guarda también, como JSON, los hábitos recomendados y las fuentes (`json:recomendados`, `json:fuentes`) | Paso 8 |
| `senales` | Ánimo y energía recientes | Paso 10 |
| `sugerencias` | Sugerencias de la Escalera | Paso 9 |
| `capsulas` | Solo metadatos y la **ruta local de la foto**; **nunca el mensaje** | Paso 11 |

- **No se guardan tokens** (siguen en el almacén seguro del Paso 4) **ni el mensaje de las cápsulas**.
- **Sin red se sigue evaluando contra la evidencia:** la copia del catálogo trae los rangos, y el formulario usa
  `EvaluadorEvidencia` (Paso 7) igual que con red. Los hábitos guardados conservan su `evaluacion`, `prioridad` e
  `intencion` (van en el JSON) y la lista local sale **por prioridad y después por nombre**, como `GET /habitos`.
- Esquema **versión 1**. Cada cambio de tablas sube la versión y agrega su paso en `migration` (`onUpgrade`).
- Las fechas de los check-ins van como texto `AAAA-MM-DD` (la fecha local del usuario, sin zona horaria).

## Archivos

| Archivo | Qué hace |
|---|---|
| `data/services/base_local/tablas.dart` | Las 9 tablas |
| `data/services/base_local/base_local.dart` | `BaseLocal` (drift): `abrir()` (`kaizen.sqlite` o WebAssembly en web), `enMemoria()`, migraciones, `borrarTodo()` |
| `data/services/base_local/memoria*.dart` | Base en memoria: SQLite nativo en pruebas; en web, una base aparte (sin `dart:ffi`) |
| `data/services/base_local/almacen_local.dart` | Todo el SQL: copia de hábitos y categorías, check-ins, **guardar + encolar**, deshacer, pendientes, rechazos, intentos, racha estimada, recordatorios |
| `data/repositories/cache.dart` | `leerConCache` y `escribirEnServidor`: qué hacer ante un error de red |
| `data/repositories/*/…_repository_local.dart` | Categorías, hábitos y check-ins con copia local (envuelven al remoto) |
| `data/services/recordatorios/servicio_recordatorios_con_copia.dart` | Copia la hora de cada recordatorio en la tabla `recordatorios` |
| `data/sync/monitor_conexion.dart` | ¿Hay red? `MonitorConexionPlus` (`connectivity_plus`) y `MonitorConexionManual` (pruebas) |
| `data/sync/sincronizador.dart` | Envía la cola y expone `enLinea`, `pendientes`, `rechazados` y `mostrarAviso`. Desde el Paso 9, el aviso solo sale sin red o si un envío **ya falló** (`fallidos`: pendientes con intentos); un check-in que se está enviando no lo muestra |
| `web/sqlite3.wasm`, `web/drift_worker.js` | SQLite en el navegador (ver abajo) |
| `tool/drift_worker.dart` | Fuente de `web/drift_worker.js` |

Cambios en archivos de pasos anteriores:
- `config/dependencias.dart` envuelve los repositorios remotos con la capa local y registra `Sincronizador` (16
  proveedores). `crearServicioSesion()` arma la sesión que envía la cola y borra la base al salir.
- `data/services/servicio_sesion.dart`: `enviarPendientes` y `borrarDatosLocales`.
- `app.dart` conecta el sincronizador con la sesión y con el ciclo de vida de la app, y avisa los rechazos.
  `main.dart` usa `crearServicioSesion()`.
- `ui/core/adaptativo/shell_adaptativo.dart`: el aviso "Sin conexión" arriba de todos los *shells*.
- `data/fake/datos_demo.dart`: `hayRed` (con `false`, el "servidor" responde sin conexión).
- `l10n/app_es.arb`: `checkinsRechazados`.
- `test/flutter_test_config.dart` y `test/golden/flutter_test_config.dart`: cada prueba usa su propia base en
  memoria, así que se apaga el aviso de drift por varias bases.

### Web: `sqlite3.wasm` y `drift_worker.js`

- **`sqlite3.wasm`** es SQLite compilado a WebAssembly, del *release* oficial `sqlite3-3.5.2` de
  `simolus3/sqlite3.dart` (la misma versión que fija `pubspec.lock`). Publicado el 19-ago-2026, 748 686 bytes,
  **SHA-256 `13d3f11d05b39ba0618a7115fb41640a5d48b6300f5d3f325f554b42bd6688a4`**, verificado contra el resumen que
  publica GitHub para ese archivo. Al subir de versión `sqlite3` hay que bajar el de la versión nueva.
- **`drift_worker.js`** se compiló aquí desde `tool/drift_worker.dart`:
  `dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js`.
  Al subir de versión `drift` hay que regenerarlo.
- La web **compila** con los dos archivos incluidos. Falta probarla en el navegador (abrir, marcar sin red con las
  DevTools en "Offline" y reconectar); se hará con la publicación en Nginx (Paso 16).

## Pruebas

| Tipo | Archivo | Pruebas | Qué comprueba |
|---|---|---|---|
| Unitarias | `test/unit/base_local/base_local_test.dart` | 18 | Las 9 tablas y la versión; la cápsula sin columna de mensaje; reabrir el archivo conserva los datos; **`UNIQUE (habito_id, fecha)`**; el último check-in del día gana; rango y orden; **guardar + encolar atómico** (con un *trigger* que hace fallar la cola, el check-in tampoco queda); el mismo check-in dos veces queda una; deshacer; pendientes ordenados, con límite y sin rechazados; intentos; observar la cola; racha estimada y confirmada; marca de "ya se guardó"; archivados; categorías y recordatorios; **cerrar sesión no deja nada** |
| Unitarias | `test/unit/base_local/humo_test.dart` | 1 | La base en memoria abre (SQLite nativo en las pruebas) |
| Unitarias | `test/unit/sync/sin_conexion_test.dart` | 19 | Categorías (el árbol completo de 22 subcategorías) y hábitos sin red desde la copia (y error si nunca se guardó); la copia conserva prioridad, intención y evaluación; un 500 no usa la copia; "hoy" recalculado para otro día; crear/editar/Escalera exigen servidor; check-ins del detalle con y sin red (con el pendiente); check-in con red, sin red y rechazado; **al volver la red se envía solo y llega una vez**; **lotes de 100** con fechas atrasadas; rechazados (se avisan una vez y no se reintentan); falla de red durante el lote; sin sesión o sin red no envía; dos llamadas, un envío; reintento periódico; **salir envía y borra**; copia de recordatorios |
| Unitarias | `test/unit/sync/monitor_conexion_test.dart` | 3 | `connectivity_plus` simulado: estado inicial, cambios reales, sin reporte del sistema; monitor manual |
| Unitarias | `test/unit/hoy/hoy_viewmodel_test.dart` | +4 | Hoy sin red desde la copia; sin copia, error; **check-in sin red se queda y se envía una vez**; marcar y desmarcar sin red deja un pendiente |
| Widget | `test/widget/sync/aviso_sin_conexion_test.dart` | 3 | Aviso arriba sin red, check-in que se queda, "1 registro por enviar", al volver la red se envía y el aviso se va; aviso arriba del riel en escritorio; aviso de rechazo |
| Integración | `integration_test/sin_conexion_test.dart` | 1 | En la app real de Linux: entrar → modo avión → marcar, desmarcar y marcar Leer → "1 registro por enviar" → reconectar → el servidor tiene **un** check-in (`offline`) y la racha de la pantalla es la del servidor |

Se ajustaron las pruebas del Paso 6 que simulaban la falla del check-in con "sin conexión" (ahora con un rechazo), la
de Dependencias (los repositorios vienen envueltos) y las del arranque de la app (usan la base en memoria).

**Resultado:** 534 de 534 en verde (512 sin goldens), más las 5 de integración en Linux · `flutter analyze`: sin
avisos · **cobertura: 97.6 %**. Sin `tablas.dart` es 98.7 %: son las declaraciones que lee el generador de drift y en
ejecución corre el código generado. `almacen_local` y el check-in local están al 100 % y el sincronizador al 97 %.
Compilan web, Linux y el APK.

## Cómo probarlo

```bash
cd app
flutter test
flutter test integration_test/sin_conexion_test.dart -d linux
flutter build apk --debug --dart-define=KAIZEN_FUENTE=fake
```

**En el teléfono** (APK *fake*), con Daniela:
1. Activa el **modo avión**: arriba aparece "Sin conexión".
2. Marca **Leer**: se queda marcado ("1 registro por enviar"). Cierra la app y vuelve a abrirla: sigue marcado.
3. Quita el modo avión: el aviso se va solo y el check-in llega al "servidor".

> En modo *fake*, los datos del "servidor" viven en memoria y se reinician al cerrar la app. Por eso, al reabrirla
> sin red se ve la copia local; con red, el "servidor" ya no tiene lo que se marcó antes de cerrarla. Con la API
> real no pasa: el servidor guarda todo.
