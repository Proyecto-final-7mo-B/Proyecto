"""Dependencias comunes de las rutas."""

import ipaddress
from typing import Annotated
from uuid import UUID
from zoneinfo import available_timezones

from fastapi import Depends, Header, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from kaizen.aplicacion.puertos import UsuarioActual
from kaizen.aplicacion.servicios.autenticacion import ServicioAutenticacion
from kaizen.aplicacion.servicios.habitos import ServicioHabitos
from kaizen.aplicacion.servicios.registros import ServicioRegistros
from kaizen.dominio.excepciones import TokenInvalido, ValidacionError
from kaizen.infraestructura.seguridad.tokens import EmisorTokens

_ZONAS = available_timezones()
# auto_error=False: sin token respondemos nosotros con problem+json (401 token-invalido)
_bearer = HTTPBearer(auto_error=False, description="Token de acceso del login")


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


def servicio_habitos(request: Request) -> ServicioHabitos:
    servicio: ServicioHabitos = request.app.state.servicio_habitos
    return servicio


def servicio_registros(request: Request) -> ServicioRegistros:
    servicio: ServicioRegistros = request.app.state.servicio_registros
    return servicio


def usuario_actual(
    request: Request,
    credenciales: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> UsuarioActual:
    """Verifica el token de acceso (firma EdDSA, vencimiento, typ=acceso) y dice quién es."""
    if credenciales is None:
        raise TokenInvalido("Falta el token de acceso")
    emisor: EmisorTokens = request.app.state.emisor
    claims = emisor.verificar(credenciales.credentials, "acceso")
    try:
        return UsuarioActual(id=UUID(claims["sub"]), region=claims["region"], rol=claims["rol"])
    except (KeyError, ValueError) as error:
        raise TokenInvalido("Token sin los datos del usuario") from error
