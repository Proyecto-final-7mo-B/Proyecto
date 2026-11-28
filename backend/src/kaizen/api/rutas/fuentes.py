"""GET /fuentes (contrato v1.7, §6.14): las fuentes científicas de "Acerca de Kaizen"."""

from typing import Annotated

from fastapi import APIRouter, Depends, Response

from kaizen.api.dependencias import servicio_habitos, usuario_actual, zona_horaria
from kaizen.api.esquemas.habitos import Fuente
from kaizen.aplicacion.puertos import Objeto, UsuarioActual
from kaizen.aplicacion.servicios.habitos import ServicioHabitos

router = APIRouter(tags=["fuentes"])


@router.get("/fuentes", response_model=list[Fuente])
def fuentes(
    response: Response,
    _usuario: Annotated[UsuarioActual, Depends(usuario_actual)],
    zona: Annotated[str, Depends(zona_horaria)],
    servicio: Annotated[ServicioHabitos, Depends(servicio_habitos)],
) -> list[Objeto]:
    response.headers["Cache-Control"] = "max-age=3600"  # cambian muy rara vez
    return servicio.fuentes(zona)
