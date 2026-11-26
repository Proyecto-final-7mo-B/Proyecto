# Paso 4 · Núcleo de datos y *fakes* (F2)

**Estado:** terminado · **Fecha:** 25-nov-2026 · **IA:** asistido (Claude), revisado por Samuel Rizo

La capa de datos completa: los modelos con las formas exactas del contrato v1.4, el cliente HTTP con sus
interceptores, el manejo de tokens y los **11 repositorios**. Cada uno tiene una interfaz y dos implementaciones:
contra la API real (`_api`) y contra datos en memoria (`_fake`). Las pantallas de los pasos siguientes solo hablan con
las interfaces y no saben cuál se usa.

## Capas

```
Pantalla ──▶ ViewModel ──▶ Repositorio (interfaz) ──┬──▶ _api  ──▶ ClienteApi (dio + interceptores) ──▶ API
                                                    └──▶ _fake ──▶ DatosDemo (servidor en memoria)
```

- Los repositorios **nunca lanzan excepciones**: devuelven `Result<T>`, que es `Exito(valor)` o `Fallo(ErrorApp)`
  (`utils/result.dart`).
- Los ViewModels usan `Command0` y `Command1` (`utils/command.dart`) para cada acción: guardan si está
  `ejecutando`, si quedó `completado` o `conError`, e ignoran un segundo toque mientras se ejecuta.

## Archivos

| Carpeta | Contenido |
|---|---|
| `domain/models/` | `usuario`, `sesion` (tokens y registro), `categoria`, `frecuencia`, `habito` (con racha y "hoy"), `registro` (check-in y lote), `escalera` (sugerencias y niveles), `capsula`, `progreso`, `laboratorio` (señales y perspectivas), `admin` (página, usuarios, métricas, indicadores), `problema` (problem+json), `conversores` (fechas) |
| `utils/` | `result`, `command`, `validadores`, `paises_estados`, `fechas` (formato largo, ISO y semana ISO) |
| `data/services/api/` | `cliente_api`, `interceptor_zona_horaria`, `interceptor_auth`, `interceptor_reintentos`, `errores_api` |
| `data/services/` | `gestor_tokens` y `almacen_seguro` |
| `data/repositories/<área>/` | Interfaz, `_api` y `_fake` para auth, categorías, hábitos, registros, escalera, progreso, señales, laboratorio, cápsulas, cuenta y admin |
| `data/fake/datos_demo.dart` | El "servidor" en memoria de los *fakes* |
| `config/dependencias.dart` | Arma todo según `KAIZEN_FUENTE` y lo registra con `provider` |
| `assets/paises_estados.json` | Copia del archivo del contrato (igual que `fn_region`) |

## Modelos ↔ contrato

Los modelos usan `json_serializable` con `field_rename: snake` (`build.yaml`). Así, `fechaCreacion` en Dart es
`fecha_creacion` en el JSON.

| Contrato | Dart |
|---|---|
| `fecha` (`YYYY-MM-DD`, día local) | `DateTime` UTC a medianoche (`FechaConverter`), para que comparar días no dependa de la zona del teléfono |
| Instantes (`…T18:04:05Z`) | `DateTime` en UTC (`InstanteConverter`); al enviarlos salen con `Z` y sin milisegundos |
| `meta`, `valor` | `double` (acepta `10` o `12.5`) |
| `frecuencia` | Clase sellada `Frecuencia`: `Diaria`, `DiasSemana(máscara)` y `NPorSemana(veces)`. `programadoEn(día)` hace lo mismo que `fn_dia_programado`: lunes = 1 … domingo = 64, L–V = 31, y "N por semana" no tiene días fijos |
| `PATCH /habitos/{id}` | `CambiosHabito`: solo manda lo que cambia y **no tiene** `meta` ni `frecuencia` (la API los rechaza) |
| Enums (`rol`, `origen`, `estado`…) | `enum` de Dart. Un `tipo` de perspectiva desconocido se lee como `desconocido` y no truena |
| problem+json | `Problema`: `tipo` (sufijo del `type`), `errores` por campo y `extras` (p. ej., `racha` y `objetivo`) |

Los `toString()` de `Tokens`, `SolicitudRegistro` y `NuevaCapsula` **no muestran** tokens, contraseñas ni mensajes,
para que no terminen en una bitácora de depuración.

## Cliente de la API

`ClienteApi` (dio) con tiempos de espera de 10 s para conectar y 15 s para recibir, y tres interceptores en este
orden:

| Interceptor | Qué hace |
|---|---|
| Zona horaria | `X-Zona-Horaria` con la zona IANA del dispositivo (`flutter_timezone`), en **todas** las peticiones. Se lee una vez. Si el sistema no la da o no tiene forma IANA, usa `KAIZEN_ZONA_DEFECTO` |
| Autenticación | `Authorization: Bearer …` en todo menos `/auth/*` (salvo `/auth/salir`). Ante un 401, **renueva una sola vez** y repite la petición. Nunca renueva en `/auth/*` ni repite dos veces la misma petición |
| Reintentos | Solo **lecturas (`GET`) y check-ins** (`POST /registros` y `/registros/lote`, idempotentes por su `id`), ante 502/503/504 o falta de red. Espera 0.2, 0.4 y 0.8 s con ± 20 % de azar. Nunca reintenta login, registro, crear hábito ni admin, ni `analitica-no-disponible` |

`/auth/renovar` va por un cliente aparte, sin el interceptor de autenticación, para que un 401 ahí no vuelva a
renovar.

## Tokens

`GestorTokens`:
- El token de **acceso** vive **solo en memoria**.
- El de **renovación** y el usuario se guardan en el almacén seguro: Keystore en Android, Keychain en iOS y macOS,
  libsecret en Linux y Credential Manager en Windows. En **web** van **solo en memoria**, como pide el contrato, así
  que al recargar hay que volver a entrar.
- `renovar()` es de **un solo vuelo**: si varias peticiones reciben 401 a la vez, se hace una sola llamada a
  `/auth/renovar` y todas esperan su resultado. Hay una prueba con dos 401 simultáneos.
- Si el servidor rechaza la renovación (`token-invalido`, `token-reutilizado` o `cuenta-suspendida`), borra todo y
  avisa en `sesionExpirada`. Si solo falló la red, conserva los tokens para intentarlo después.

## Errores

`ErrorApp` lleva un `TipoError` por cada `type` del contrato (§3), más `sinConexion`, `tiempoAgotado` y
`desconocido`. También trae los errores por campo (`errorDe('contrasena')`) y el `Retry-After`. Si la respuesta no
trae problem+json, el tipo se decide por el código HTTP. Si llega una respuesta que no tiene la forma del contrato, el
resultado es un `Fallo(desconocido)` y la app no truena.

- `esDeRed`: errores en los que conviene usar lo guardado o encolar.
- `cierraSesion`: errores que mandan a volver a entrar.

## Datos de prueba (`KAIZEN_FUENTE=fake`)

`DatosDemo` funciona como un servidor en memoria con **las mismas personas que el poblador** del entorno local. La
contraseña de todas es `KaizenDemo2026!`.

| Cuenta | Para probar |
|---|---|
| `demo@kaizen.test` (Daniela, MX-NORTE) | Los **5 hábitos del bosquejo de Hoy**: Tomar agua (racha 21, cumplido hoy, cápsula de 21 lista para abrir), Ejercicio (racha 8, cumplido hoy, cápsula de 66), Leer (racha 34, nivel 3 con metas 7 → 8.5 → 10, sugerencia 10 → 11), Estudiar inglés (L–V, Escalera apagada) y Dormir 7 h (racha 2). Tiene 30 días de señales |
| `admin@kaizen.test` (MX-CENTRO-SUR) | Rol admin |
| `latam@kaizen.test` (LATAM) | Tercera región; un hábito "N por semana", sugerencia pendiente y cápsula sellada |
| `nuevo@kaizen.test` | Sin hábitos ni consentimiento de señales |
| `suspendido@kaizen.test` | Responde `cuenta-suspendida` |
| `usuario001…045@kaizen.test` | Para la paginación del panel de admin |

Aplica las mismas reglas que la base:
- rachas por días programados (hoy no rompe la racha hasta que termina);
- check-in idempotente, donde gana el último del día;
- fechas válidas desde la creación del hábito hasta hoy + 1;
- archivar expira la sugerencia pendiente;
- la cápsula no se abre hasta alcanzar la racha (con `racha` y `objetivo` en el error);
- las señales exigen consentimiento;
- bloqueo de 15 min tras 10 fallos;
- rotación del token de renovación, donde reutilizar uno revoca la familia;
- recuperación de contraseña de un solo uso (en modo *fake*, el enlace se imprime en la consola);
- el admin no puede suspender a otro admin y la búsqueda por correo es exacta.

`fallarSiguiente(error)` hace que la próxima operación falle, para probar estados de error.
`analiticaDisponible = false` simula el HomeLab apagado. En la app los *fakes* tardan ~300 ms, para que se vean los
estados de carga; en las pruebas no tardan nada.

## Cambiar entre *fake* y API

```bash
flutter run -d linux --dart-define=KAIZEN_FUENTE=fake
flutter run -d linux --dart-define=KAIZEN_FUENTE=api --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

`main.dart` carga el catálogo de países, arma `Dependencias.desdeEntorno(...)` y `KaizenApp` registra todo con
`MultiProvider`. En una pantalla: `context.read<HabitosRepository>()`.

## Cómo agregar un repositorio

1. Interfaz en `data/repositories/<área>/<área>_repository.dart`, con métodos que devuelven `Future<Result<T>>`.
2. `_api` con `ClienteApi` (`get`, `post`, `patch`, `put` o `delete` y una función que convierte el JSON).
3. `_fake` sobre `DatosDemo`: la regla se escribe dentro de `datos.ejecutar(() { ... })` y los errores se lanzan con
   `DatosDemo.error(...)`.
4. Registrarlo en `Dependencias` (`fake`, `api` y `proveedores()`).
5. Pruebas: ruta y cuerpo en `repositorios_api_test.dart` y reglas en `repositorios_fake_test.dart`.

## Generación de código

Después de cambiar un modelo:

```bash
dart run build_runner build
```

Los `*.g.dart` **se suben al repo**, para que `flutter test` funcione sin generar nada. El análisis los ignora.

## Pruebas

| Archivo | Pruebas | Qué comprueba |
|---|---|---|
| `test/unit/modelos/modelos_test.dart` | 20 | Cada JSON de ejemplo del contrato, de ida y vuelta (hábito, registro, sugerencia, cápsula, tokens, registro de usuario, `PATCH`, lote, Escalera, progreso, perspectivas v1.4, cuenta, admin, indicador y problem+json); `toString` sin secretos; conversores de fechas |
| `test/unit/modelos/frecuencia_test.dart` | 4 | Máscara (L–V = 31) y día programado igual que `fn_dia_programado` |
| `test/unit/utils/validadores_test.dart` | 9 | Todos los límites del contrato con sus bordes, incluidos 4096 **bytes** con emojis |
| `test/unit/utils/result_command_paises_test.dart` | 8 | `Result`, `Command` (doble toque), catálogo real de 20 países y 32 estados con la región de `fn_region`, semana ISO |
| `test/unit/datos/cliente_api_test.dart` | 22 | Cabeceras, renovación (y **una sola** con dos 401 a la vez), reintentos (qué sí y qué no, tiempos), cada `type` del contrato, respuestas que no son del contrato |
| `test/unit/datos/repositorios_api_test.dart` | 10 | Cada repositorio `_api`: ruta, parámetros y cuerpo del contrato |
| `test/unit/datos/repositorios_fake_test.dart` | 31 | Las reglas de la base en los *fakes* (lista arriba) |
| `test/unit/datos/dependencias_almacen_test.dart` | 5 | *fake* o API según el entorno, `provider` y el almacén seguro |

**Resultado:** 293 de 293 en verde (109 nuevas, todas unitarias) · `flutter analyze`: sin avisos · cobertura de la
app: **98.9 %** (sin contar el código generado).

## Cómo probarlo

```bash
cd app
flutter pub get
flutter test test/unit/modelos test/unit/datos
flutter run -d linux --dart-define=KAIZEN_FUENTE=fake
```

En este paso todavía no hay pantallas nuevas: la app se ve igual que en el Paso 3, pero ya arranca con los
repositorios armados. El login real llega en el Paso 5.
