"""Ensambla la aplicación: aquí se conectan los adaptadores reales con los servicios.

Arranque local (desde backend/, con .env):  uvicorn kaizen.api.main:crear_app --factory --reload
"""

from collections.abc import AsyncIterator, Callable
from contextlib import asynccontextmanager

from fastapi import FastAPI

from kaizen.api.errores import registrar_manejadores
from kaizen.api.rutas import auth, salud
from kaizen.aplicacion.servicios.autenticacion import ServicioAutenticacion
from kaizen.config import Configuracion

PREFIJO = "/api/v1"


def construir_app(
    servicio_auth: ServicioAutenticacion,
    revisar_base: Callable[[], bool],
    zona_defecto: str = "America/Mexico_City",
) -> FastAPI:
    """Crea la app con las piezas que se le pasen (las pruebas pasan piezas falsas)."""
    app = FastAPI(title="Kaizen API", version="1.4.0")
    app.state.servicio_auth = servicio_auth
    app.state.revisar_base = revisar_base
    app.state.zona_defecto = zona_defecto
    registrar_manejadores(app)
    app.include_router(salud.router, prefix=PREFIJO)
    app.include_router(auth.router, prefix=PREFIJO)
    return app


def crear_app() -> FastAPI:  # pragma: no cover - se prueba en integración con la base real
    """Fábrica para uvicorn: lee la configuración y conecta PostgreSQL y la criptografía."""
    from kaizen.infraestructura.postgres.conexion import UnidadDeTrabajo, crear_pool
    from kaizen.infraestructura.postgres.repositorio_auth import RepositorioAuthPg
    from kaizen.infraestructura.seguridad.contrasenas import HasherContrasenas
    from kaizen.infraestructura.seguridad.seudonimos import GeneradorHmac
    from kaizen.infraestructura.seguridad.tokens import EmisorTokens

    cfg = Configuracion()  # type: ignore[call-arg]  # los valores vienen del entorno
    pool = crear_pool(cfg)
    uow = UnidadDeTrabajo(pool, cfg.zona_horaria_defecto)
    servicio = ServicioAutenticacion(
        RepositorioAuthPg(uow),
        HasherContrasenas(),
        GeneradorHmac(cfg.email_hmac_key.get_secret_value()),
        EmisorTokens(cfg.jwt_llave_privada.get_secret_value(), cfg.jwt_kid),
    )
    app = construir_app(servicio, uow.base_disponible, cfg.zona_horaria_defecto)

    @asynccontextmanager
    async def ciclo(_: FastAPI) -> AsyncIterator[None]:
        yield
        pool.close()

    app.router.lifespan_context = ciclo
    return app
