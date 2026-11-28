"""Traduce los errores de Kaizen a respuestas application/problem+json (RFC 9457, contrato §3)."""

import logging
import uuid
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from kaizen.dominio.excepciones import (
    CategoriaInactiva,
    ConsentimientoRequerido,
    CredencialesInvalidas,
    CuentaBloqueada,
    CuentaSuspendida,
    FechaFueraDeRango,
    HabitoArchivado,
    KaizenError,
    NoEncontrado,
    NombreDuplicado,
    OperacionNoPermitida,
    RecomendacionNoDisponible,
    RegionInvalida,
    RolInsuficiente,
    SubcategoriaInactiva,
    TokenInvalido,
    UnidadNoPermitida,
    ValidacionError,
)

log = logging.getLogger("kaizen.api")
BASE_TIPO = "https://kaizen.app/errores/"

# excepción -> (tipo, HTTP, título que ve el usuario)
TABLA: dict[type[KaizenError], tuple[str, int, str]] = {
    ValidacionError: ("validacion", 422, "Datos inválidos"),
    CredencialesInvalidas: ("credenciales-invalidas", 401, "Correo o contraseña incorrectos"),
    TokenInvalido: ("token-invalido", 401, "Sesión inválida o vencida"),
    CuentaSuspendida: (
        "cuenta-suspendida",
        403,
        "Tu cuenta está suspendida. Contacta al administrador",
    ),
    CuentaBloqueada: ("cuenta-bloqueada", 429, "Demasiados intentos. Intenta más tarde"),
    RegionInvalida: ("region-invalida", 422, "País o estado fuera del servicio"),
    FechaFueraDeRango: ("fecha-fuera-de-rango", 422, "Fecha no válida"),
    CategoriaInactiva: ("categoria-inactiva", 422, "La categoría ya no está disponible"),
    SubcategoriaInactiva: ("subcategoria-inactiva", 422, "La subcategoría ya no está disponible"),
    UnidadNoPermitida: ("unidad-no-permitida", 422, "Unidad no permitida para la subcategoría"),
    RecomendacionNoDisponible: (
        "recomendacion-no-disponible",
        422,
        "Esa recomendación ya no está disponible",
    ),
    ConsentimientoRequerido: ("consentimiento-requerido", 403, "Falta tu consentimiento"),
    RolInsuficiente: ("rol-insuficiente", 403, "No tienes permiso para esta operación"),
    NoEncontrado: ("no-encontrado", 404, "No encontrado"),
    OperacionNoPermitida: ("operacion-no-permitida", 409, "Operación no permitida"),
    HabitoArchivado: ("habito-archivado", 409, "El hábito está archivado"),
    NombreDuplicado: ("nombre-duplicado", 409, "Ya existe una categoría con ese nombre"),
}

# Para estos tipos el texto del error (de la regla o de la base) sí ayuda al usuario
CON_DETALLE = (
    FechaFueraDeRango,
    UnidadNoPermitida,
    SubcategoriaInactiva,
    CategoriaInactiva,
    OperacionNoPermitida,
    RegionInvalida,
)


def resumen_de(error: KaizenError) -> dict[str, Any]:
    """type, status y title de un error: lo que lleva cada rechazo del lote de check-ins."""
    for clase, (tipo, status, titulo) in TABLA.items():
        if isinstance(error, clase):
            return {"type": BASE_TIPO + tipo, "status": status, "title": titulo}
    return {"type": BASE_TIPO + "error-interno", "status": 500, "title": "Error interno"}


def problema(
    tipo: str, status: int, titulo: str, headers: dict[str, str] | None = None, **extra: Any
) -> JSONResponse:
    cuerpo = {
        "type": BASE_TIPO + tipo,
        "title": titulo,
        "status": status,
        "id_peticion": str(uuid.uuid4()),
    }
    return JSONResponse(
        cuerpo | extra, status_code=status, media_type="application/problem+json", headers=headers
    )


def error_interno(error: Exception) -> JSONResponse:
    id_peticion = str(uuid.uuid4())
    # La traza va a la bitácora del servidor, nunca al cliente (contrato §3)
    log.error("error interno id_peticion=%s", id_peticion, exc_info=error)
    return problema("error-interno", 500, "Error interno", id_peticion=id_peticion)


def respuesta_de(error: KaizenError) -> JSONResponse:
    for clase, (tipo, status, titulo) in TABLA.items():
        if isinstance(error, clase):
            headers = None
            extra: dict[str, Any] = {}
            if isinstance(error, CuentaBloqueada):
                headers = {"Retry-After": str(error.segundos)}
            if isinstance(error, ValidacionError):
                extra["errores"] = [{"campo": error.campo, "detalle": str(error)}]
            if isinstance(error, CON_DETALLE):
                extra["detail"] = str(error)
            return problema(tipo, status, titulo, headers, **extra)
    return error_interno(error)


def registrar_manejadores(app: FastAPI) -> None:
    @app.exception_handler(KaizenError)
    async def _kaizen(_: Request, error: KaizenError) -> JSONResponse:
        return respuesta_de(error)

    @app.exception_handler(RequestValidationError)
    async def _validacion(_: Request, error: RequestValidationError) -> JSONResponse:
        errores = [
            {"campo": ".".join(str(p) for p in e["loc"][1:]) or None, "detalle": e["msg"]}
            for e in error.errors()
        ]
        return problema("validacion", 422, "Datos inválidos", errores=errores)

    @app.exception_handler(Exception)
    async def _inesperado(_: Request, error: Exception) -> JSONResponse:
        return error_interno(error)
