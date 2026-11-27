"""Traduce los errores de Kaizen a respuestas application/problem+json (RFC 9457, contrato §3)."""

import logging
import uuid
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from kaizen.dominio.excepciones import (
    CredencialesInvalidas,
    CuentaBloqueada,
    CuentaSuspendida,
    KaizenError,
    TokenInvalido,
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
}


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
