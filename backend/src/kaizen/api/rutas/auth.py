"""Rutas de /auth (contrato v1.4, §6.1). Por ahora: login."""

from typing import Annotated

from fastapi import APIRouter, Depends, Response

from kaizen.api.dependencias import ip_cliente, servicio_auth, zona_horaria
from kaizen.api.esquemas.auth import RespuestaTokens, SolicitudLogin, UsuarioResumen
from kaizen.aplicacion.servicios.autenticacion import ServicioAutenticacion

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=RespuestaTokens)
def login(
    datos: SolicitudLogin,
    response: Response,
    servicio: Annotated[ServicioAutenticacion, Depends(servicio_auth)],
    ip: Annotated[str | None, Depends(ip_cliente)],
    _zona: Annotated[str, Depends(zona_horaria)],
) -> RespuestaTokens:
    response.headers["Cache-Control"] = "no-store"
    sesion = servicio.iniciar_sesion(datos.email, datos.contrasena, ip)
    c = sesion.cuenta
    return RespuestaTokens(
        token_acceso=sesion.par.acceso,
        token_renovacion=sesion.par.renovacion,
        expira_en=sesion.par.expira_en,
        usuario=UsuarioResumen(id=c.id, nombre=c.nombre, rol=c.rol, region=c.region),  # type: ignore[arg-type]
    )
