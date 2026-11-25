# Paso 1 · Proyecto base (F0)

**Estado:** terminado · **Fecha:** 24-nov-2026 · **IA:** asistido (Claude), revisado por Samuel Rizo

## Qué se hizo

| Parte | Detalle |
|---|---|
| Proyecto | `flutter create --org mx.uaa.kaizen --project-name kaizen --platforms android,ios,linux,windows,macos,web .` dentro de `app/`, respetando las carpetas ya creadas |
| Dependencias | 21 paquetes con versión **fija** (sin `^`), revisados en pub.dev: *publisher* verificado y al menos 14 días de publicados. Descartados: `sqlite3_flutter_libs` (descontinuado) y `lucide_icons_flutter` (no hace falta). Dos paquetes se bajaron de versión porque sus versiones nuevas exigen el **Android SDK 37** (el proyecto compila con el 36): `flutter_local_notifications` **22.3.3** (la 23.x exige compileSdk 37 y AGP 9.1) y `permission_handler` **12.0.3** (la 13.x usa `permission_handler_android` 14, que exige compileSdk 37). Las versiones están en `pubspec.yaml` |
| Análisis estático | `flutter_lints` + `strict-casts`, `strict-inference`, `strict-raw-types` y reglas extra (comillas simples, `const`, `final` locales, comas finales, `unawaited_futures`, sin `print`) |
| Textos | `flutter_localizations` + archivo `lib/l10n/app_es.arb` (es-MX). Se generan en `lib/l10n/gen/` con `flutter pub get` |
| Configuración | `lib/config/entorno.dart`: `KAIZEN_FUENTE` (`fake`/`api`, **por omisión `api`**: un valor desconocido nunca deja la app con datos de prueba), `API_BASE_URL` y `KAIZEN_ZONA_DEFECTO` |
| Límites del contrato | `lib/config/constantes.dart`: los mismos de la base (contraseña 12–128, mensaje 4096 bytes, rachas 7/21/66…) |
| App mínima | `lib/main.dart` y `lib/app.dart`: arranca en español de México y muestra una pantalla temporal con la fuente de datos (se reemplaza en los pasos 2 y 3) |

### Configuración por plataforma

| Plataforma | Cambio |
|---|---|
| Android | Nombre "Kaizen", `applicationId mx.uaa.kaizen`, `minSdk 24` (lo piden el almacén seguro y las notificaciones), permisos `INTERNET`, `CAMERA` (se pedirá en contexto) y `POST_NOTIFICATIONS`; cámara no obligatoria; *desugaring* para `flutter_local_notifications`. La firma de release se hace en el Paso 16 |
| iOS | Textos en español de los permisos de cámara y fotos (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`). Preparado, sin compilar |
| macOS | Permiso de red saliente (`com.apple.security.network.client`) en *DebugProfile* y *Release*. Preparado, sin compilar |
| Linux, Windows, web | Título "Kaizen" en la ventana, la pestaña y el manifiesto web |

## Pruebas

| Tipo | Archivo | Qué comprueba |
|---|---|---|
| Unitaria | `test/unit/config/entorno_test.dart` (7) | `fake` en cualquier forma de escribirlo; `api` y valores desconocidos → API; limpieza de la URL; valores por omisión sin `--dart-define`; los límites coinciden con el contrato v1.4 |
| Widget (humo) | `test/widget/app/app_arranca_test.dart` (1) | La app arranca, en `es-MX`, y muestra marca, lema y fuente de datos |

**Resultado:** 8 de 8 pruebas en verde · `flutter analyze`: sin avisos · **Cobertura: 100 %** (27/27 líneas, sin contar el código generado de los textos).

| Compilación | Resultado |
|---|---|
| Linux (debug) | ✓ `build/linux/x64/debug/bundle/kaizen` |
| Web (`--no-web-resources-cdn`) | ✓ `build/web` |
| Android APK (debug) | ✓ `build/app/outputs/flutter-apk/app-debug.apk` (163 MB en debug; el de release firmado se hace en el Paso 16) |

## Cómo probarlo

```bash
cd app
flutter pub get && flutter analyze && flutter test --coverage
flutter run -d linux --dart-define=KAIZEN_FUENTE=fake     # muestra "Fuente de datos: fake"
```
