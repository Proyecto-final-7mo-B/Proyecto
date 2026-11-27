"""GET /categorias (contrato v1.6, §6.3): el árbol categoría → subcategorías → unidades y rango."""

from typing import Annotated

from fastapi import APIRouter, Depends, Response

from kaizen.api.dependencias import servicio_habitos, usuario_actual, zona_horaria
from kaizen.api.esquemas.habitos import Categoria
from kaizen.aplicacion.puertos import Objeto, UsuarioActual
from kaizen.aplicacion.servicios.habitos import ServicioHabitos

router = APIRouter(tags=["categorias"])


@router.get("/categorias", response_model=list[Categoria])
def categorias(
    response: Response,
    _usuario: Annotated[UsuarioActual, Depends(usuario_actual)],
    zona: Annotated[str, Depends(zona_horaria)],
    servicio: Annotated[ServicioHabitos, Depends(servicio_habitos)],
) -> list[Objeto]:
    response.headers["Cache-Control"] = "max-age=3600"  # el catálogo cambia muy poco
    return servicio.categorias(zona)
