"""Dependencias comunes de las rutas."""

import ipaddress
from typing import Annotated
from zoneinfo import available_timezones

from fastapi import Header, Request

from kaizen.aplicacion.servicios.autenticacion import ServicioAutenticacion
from kaizen.dominio.excepciones import ValidacionError

_ZONAS = available_timezones()


def zona_horaria(request: Request, x_zona_horaria: Annotated[str | None, Header()] = None) -> str:
    """Cabecera X-Zona-Horaria (contrato §1.1): si falta, la de defecto; si es inválida, 422."""
    if x_zona_horaria is None:
        defecto: str = request.app.state.zona_defecto
        return defecto
    if x_zona_horaria not in _ZONAS:
        raise ValidacionError("No es una zona IANA válida", campo="X-Zona-Horaria")
    return x_zona_horaria


def servicio_auth(request: Request) -> ServicioAutenticacion:
    servicio: ServicioAutenticacion = request.app.state.servicio_auth
    return servicio


def ip_cliente(request: Request) -> str | None:
    """IP del cliente para la bitácora; None si no es una IP válida (la columna es inet)."""
    if request.client is None:
        return None
    try:
        return str(ipaddress.ip_address(request.client.host))
    except ValueError:
        return None
