"""Administración de recomendaciones (contrato v1.7, §6.10).

Dos barreras: el rol del token (aquí, 403) y el procedimiento de la base, que vuelve a
comprobar que quien llama es admin activo (KZ010) y deja todo en la bitácora.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Path

from kaizen.api.dependencias import ip_cliente, servicio_habitos, usuario_actual, zona_horaria
from kaizen.api.esquemas.habitos import RecomendacionAdmin, SolicitudRecomendacion
from kaizen.aplicacion.puertos import Objeto, UsuarioActual
from kaizen.aplicacion.servicios.habitos import ServicioHabitos

router = APIRouter(prefix="/admin", tags=["admin"])

Usuario = Annotated[UsuarioActual, Depends(usuario_actual)]
ZonaHoraria = Annotated[str, Depends(zona_horaria)]
Servicio = Annotated[ServicioHabitos, Depends(servicio_habitos)]
Clave = Annotated[str, Path(pattern=r"^[a-z_0-9]{3,40}$")]


@router.get("/recomendaciones", response_model=list[RecomendacionAdmin])
def recomendaciones(usuario: Usuario, zona: ZonaHoraria, servicio: Servicio) -> list[Objeto]:
    """Todas las recomendaciones, también las inactivas."""
    return servicio.recomendaciones_admin(usuario, zona)


@router.put("/recomendaciones/{clave}", response_model=RecomendacionAdmin)
def guardar_recomendacion(
    clave: Clave,
    datos: SolicitudRecomendacion,
    usuario: Usuario,
    zona: ZonaHoraria,
    servicio: Servicio,
    ip: Annotated[str | None, Depends(ip_cliente)],
) -> Objeto:
    """Alta o cambio por clave. activo=false la oculta de /habitos/recomendados."""
    return servicio.guardar_recomendacion(usuario, zona, datos.a_recomendacion(clave), ip)
