# App (Flutter)

Una sola base de código para Android, iOS, Linux, Windows, macOS y web. Arquitectura **MVVM** (la recomendada por la
guía oficial de Flutter): Vista → ViewModel (`ChangeNotifier`) → Repositorio (implementación API y *fake*) → Servicio.
Responsable: Samuel Rizo.

```
app/
├── lib/
│   ├── config/              entorno (API_BASE_URL, KAIZEN_FUENTE=fake|api) y constantes
│   ├── routing/             go_router, rutas y guardas
│   ├── utils/               Result, Command, validadores, fechas, países y estados
│   ├── domain/models/       modelos (usuario, hábito, frecuencia, registro, cápsula, …)
│   ├── data/
│   │   ├── services/api/         cliente dio, interceptores (auth, zona horaria, reintentos), problem+json
│   │   ├── services/base_local/  drift (SQLite nativo y WASM en web)
│   │   ├── repositories/         interfaz + implementación _api + _fake por módulo
│   │   └── sync/                 cola sin conexión → POST /registros/lote
│   ├── ui/
│   │   ├── core/            tema/, adaptativo/ (breakpoints y shells), widgets/ reutilizables
│   │   └── <módulo>/        view_models/ y widgets/ (pantallas)
│   │                        auth · hoy · habitos · progreso · escalera · laboratorio · capsulas · cuenta · admin
│   └── l10n/                textos en español (ARB)
├── test/                    unit/ (ViewModels, validadores) y widget/ (componentes y pantallas)
├── integration_test/        flujo principal en Android, Linux y Chrome
└── assets/                  fuentes/ e imagenes/
```

Las carpetas de plataforma (`android/`, `ios/`, `linux/`, `windows/`, `macos/`, `web/`) y `pubspec.yaml` se generan con
`flutter create --org mx.uaa.kaizen --platforms android,ios,linux,windows,macos,web .` dentro de esta carpeta: el
comando respeta lo que ya existe en `lib/`.
