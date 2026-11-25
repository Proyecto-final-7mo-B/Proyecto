# App Kaizen · cómo instalar, correr y probar

## Requisitos

| Herramienta | Versión | Para qué |
|---|---|---|
| Flutter / Dart | 3.47 / 3.13 (canal stable) | Todo |
| Android SDK | plataforma 36, build-tools 36 | APK y emulador |
| Chrome | cualquiera reciente | Versión web y pruebas web |
| Linux: `clang`, `cmake`, `ninja`, GTK 3, `libsecret-devel` | — | Versión de escritorio Linux |
| Windows: Visual Studio con "Desarrollo para el escritorio con C++" | — | Versión de Windows (en la máquina Windows del equipo) |
| Mac con Xcode | — | iOS y macOS (preparados, **no se compilan**: no hay Mac en el equipo) |

## Primeros pasos

```bash
cd app
flutter pub get                 # también genera los textos (lib/l10n/gen/)
flutter analyze                 # debe decir "No issues found!"
flutter test --coverage         # todas las pruebas en verde
flutter test integration_test/navegacion_test.dart -d linux   # flujos en la app real
dart format .                   # ancho de 120 columnas (analysis_options.yaml)
```

Las pruebas *golden* (imágenes de referencia de los componentes) se generaron en Linux. Si en otro sistema fallan solo
por el suavizado de las letras, corre `flutter test --exclude-tags golden`. Detalle en
[02_sistema_de_diseno.md](modulos/02_sistema_de_diseno.md#sobre-las-pruebas-golden).

## Correr la app

La fuente de datos se elige al compilar. **Por omisión es la API de producción**; para desarrollar sin backend se usan
los repositorios de prueba (`fake`), que responden con los mismos JSON del contrato.

```bash
flutter run -d linux  --dart-define=KAIZEN_FUENTE=fake
flutter run -d chrome --dart-define=KAIZEN_FUENTE=fake
flutter run -d <emulador> --dart-define=KAIZEN_FUENTE=fake
# hasta el Paso 5, en depuración se entra con "Entrar como usuario demo" o "Entrar como admin demo"

# contra la API local de Jesús (entorno local del backend)
flutter run -d linux --dart-define=KAIZEN_FUENTE=api --dart-define=API_BASE_URL=http://localhost:8000/api/v1
# desde el emulador de Android la laptop es 10.0.2.2
```

| `--dart-define` | Valores | Por omisión |
|---|---|---|
| `KAIZEN_FUENTE` | `fake` · `api` (cualquier otro valor = `api`) | `api` |
| `API_BASE_URL` | URL base de la API, sin `/` final | `https://proyecto-kaizen.northcentralus.cloudapp.azure.com/api/v1` |
| `KAIZEN_ZONA_DEFECTO` | Zona IANA si el dispositivo no reporta la suya | `America/Mexico_City` |

Ningún secreto se pasa por `--dart-define`: la app no guarda llaves; solo recibe tokens al iniciar sesión.

## Compilar

```bash
flutter build apk --debug                         # Android (el APK firmado se hace en el Paso 16)
flutter build linux                               # build/linux/x64/release/bundle/
flutter build web --no-web-resources-cdn          # build/web (sin depender de CDNs externos)
flutter build windows                             # en la máquina Windows
```

## Estructura y forma de trabajo

- Arquitectura MVVM; árbol completo en `../README.md`.
- Solo tema claro. Colores, textos, formas e íconos salen de `lib/ui/core/tema/`; los componentes reutilizables están en
  `lib/ui/core/widgets/` (catálogo en [02_sistema_de_diseno.md](modulos/02_sistema_de_diseno.md)). En depuración, el
  botón **Ver componentes** abre la galería.
- La app se construye **por pasos**. Cada paso entrega código, pruebas y su documento en [`modulos/`](modulos/).
- Versiones de paquetes **fijas** en `pubspec.yaml` (revisadas en pub.dev, regla R14). Para cambiar una, se repite la
  revisión y se anota en el documento del paso.

| Paso | Documento |
|---|---|
| 1 · Proyecto base | [01_proyecto_base.md](modulos/01_proyecto_base.md) |
| 2 · Sistema de diseño | [02_sistema_de_diseno.md](modulos/02_sistema_de_diseno.md) |
| 3 · Navegación adaptativa | [03_navegacion.md](modulos/03_navegacion.md) |
