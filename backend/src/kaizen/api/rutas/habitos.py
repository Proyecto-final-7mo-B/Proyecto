"""Rutas de /habitos (contrato v1.6, §6.4).

El usuario y su región salen del token (nunca del cuerpo). Un hábito de otro usuario da 404.
"""

from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status

from kaizen.api.dependencias import servicio_habitos, usuario_actual, zona_horaria
from kaizen.api.esquemas.habitos import (
    CambiosHabito,
    Evaluacion,
    Habito,
    SolicitudEvaluacion,
    SolicitudHabito,
)
from kaizen.aplicacion.puertos import Objeto, UsuarioActual
from kaizen.aplicacion.servicios.habitos import ServicioHabitos

router = APIRouter(prefix="/habitos", tags=["habitos"])

Usuario = Annotated[UsuarioActual, Depends(usuario_actual)]
ZonaHoraria = Annotated[str, Depends(zona_horaria)]
Servicio = Annotated[ServicioHabitos, Depends(servicio_habitos)]


@router.get("", response_model=list[Habito])
def listar(
    usuario: Usuario,
    zona: ZonaHoraria,
    servicio: Servicio,
    fecha: date | None = None,
    archivados: bool = False,
) -> list[Objeto]:
    """Hábitos del usuario, ordenados por prioridad y después por nombre."""
    return servicio.listar(usuario, zona, fecha, archivados)


@router.post("/evaluar", response_model=Evaluacion)
def evaluar(
    datos: SolicitudEvaluacion, usuario: Usuario, zona: ZonaHoraria, servicio: Servicio
) -> Objeto:
    """Evalúa una meta contra la evidencia científica, sin guardar nada."""
    return servicio.evaluar(usuario, zona, datos.a_consulta())


@router.post("", response_model=Habito, status_code=status.HTTP_201_CREATED)
def crear(
    datos: SolicitudHabito, usuario: Usuario, zona: ZonaHoraria, servicio: Servicio
) -> Objeto:
    """Crea el hábito. Una meta excesiva se acepta: la Escalera propone bajarla."""
    return servicio.crear(usuario, zona, datos.a_nuevo())


@router.get("/{habito_id}", response_model=Habito)
def obtener(
    habito_id: UUID,
    usuario: Usuario,
    zona: ZonaHoraria,
    servicio: Servicio,
    fecha: date | None = None,
) -> Objeto:
    return servicio.obtener(usuario, zona, habito_id, fecha)


@router.patch("/{habito_id}", response_model=Habito)
def actualizar(
    habito_id: UUID,
    cambios: CambiosHabito,
    usuario: Usuario,
    zona: ZonaHoraria,
    servicio: Servicio,
) -> Objeto:
    """Cambia nombre, subcategoría (con unidad), prioridad, intención, Escalera o archiva."""
    return servicio.actualizar(usuario, zona, habito_id, cambios.model_dump(exclude_unset=True))
