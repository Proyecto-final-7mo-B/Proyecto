# Backend (Python 3.12)

API REST con FastAPI, ETL hacia MongoDB, reportes con Matplotlib y tareas programadas. **Arquitectura hexagonal**:
el dominio es Python puro y los adaptadores (PostgreSQL, MongoDB, criptografía, HTTP) dependen de él, nunca al revés.
Responsable: Jesús Ángel Vázquez.

```
backend/
├── requirements/            base.in → base.txt (ejecución) y dev.in → dev.txt (pruebas y análisis), con hashes
├── src/kaizen/
│   ├── dominio/             entidades, objetos de valor y excepciones (sin base de datos ni red)
│   │   └── reglas/          frecuencia, rachas, Escalera, política de apertura de cápsulas
│   ├── aplicacion/          puertos (Protocol) y DTO
│   │   └── servicios/       casos de uso: auth, hábitos, check-in, Escalera, cápsula, laboratorio, cuenta, admin
│   ├── infraestructura/
│   │   ├── postgres/        pool, unidad de trabajo (RLS + zona horaria), repositorios, SQLSTATE → errores
│   │   ├── mongo/           conexión y lectura de la base analítica
│   │   └── seguridad/       Argon2id, AES-256-GCM, HMAC, JWT EdDSA
│   ├── api/                 crear_app(), dependencias, middleware, errores problem+json
│   │   ├── esquemas/        modelos Pydantic (extra="forbid")
│   │   └── rutas/           un módulo por grupo de endpoints del contrato
│   ├── etl/                 extraer → limpiar → seudonimizar → transformar → cargar → analizar
│   ├── reportes/            indicadores I1–I6 con Matplotlib
│   ├── sinteticos/          generador de datos sintéticos reproducible
│   └── tareas/              Escalera diaria, limpieza, particiones y verificación de rachas
└── tests/
    ├── unit/                dominio, seguridad y limpieza (sin red)
    ├── integracion/         postgres/ y mongo/ con servicios reales
    ├── api/                 flujos, IDOR, inyección, CORS y límites
    └── datos/               archivos pequeños de prueba
```

Referencias: el contrato de la API está en [`docs/api/`](../docs/api/) y el entorno local de desarrollo se entrega
aparte (Docker con la misma base que producción).

## Cómo correr la API en local

Se corre en Docker (Linux): así no depende de lo que Windows permita ejecutar.

1. Levanta el entorno de Jael (`docker compose up -d` en `entorno_local_backend` y, la primera vez,
   `docker compose run --rm poblar`).
2. Copia su `.env` a esta carpeta (`backend/.env`; no se sube a Git):
   ```powershell
   copy ..\..\entorno_local_backend\.env .env
   ```
3. Construye y arranca la API (se conecta a la base por la red de Docker del entorno):
   ```powershell
   docker compose up --build
   ```
4. Prueba: http://localhost:8000/api/v1/salud y la documentación en http://localhost:8000/docs
   (login con `demo@kaizen.test` y la contraseña `KAIZEN_DEMO_PASSWORD` del `.env`).

Sin Docker (si tu sistema lo permite): `pip install --no-deps -e .` y
`uvicorn kaizen.api.main:crear_app --factory --reload`.

## Pruebas

```powershell
ruff check . ; mypy src ; pytest                          # unitarias y de API (sin base)
$env:KAIZEN_PRUEBAS_INTEGRACION=1; pytest tests/integracion # contra el PostgreSQL local
```
