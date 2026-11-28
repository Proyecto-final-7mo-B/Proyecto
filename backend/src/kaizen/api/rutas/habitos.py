"""Rutas de /habitos (contrato v1.7, §6.4).

El usuario y su región salen del token (nunca del cuerpo). Un hábito de otro usuario da 404.
"""

from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status

from kaizen.api.dependencias import servicio_habitos, usuario_actual, zona_horaria
from kaizen.api.esquemas.habitos import (
    CambiosHabito,
    DiasProtegidos,
    Evaluacion,
    Habito,
    HabitoRecomendado,
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


# Va antes de /{habito_id}: si no, "recomendados" se leería como un id
@router.get("/recomendados", response_model=list[HabitoRecomendado])
def recomendados(_usuario: Usuario, zona: ZonaHoraria, servicio: Servicio) -> list[Objeto]:
    """Los 100 hábitos recomendados activos, en el orden de categoría y subcategoría."""
    return servicio.recomendados(zona)


@router.post("", response_model=Habito, status_code=status.HTTP_201_CREATED)
def crear(
    datos: SolicitudHabito, usuario: Usuario, zona: ZonaHoraria, servicio: Servicio
) -> Objeto:
    """Crea el hábito, personalizado o desde una recomendación (solo recomendacion_id)."""
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


@router.get("/{habito_id}/protegidos", response_model=DiasProtegidos)
def protegidos(
    habito_id: UUID,
    desde: date,
    hasta: date,
    usuario: Usuario,
    zona: ZonaHoraria,
    servicio: Servicio,
) -> Objeto:
    """Días fallados que perdonó el protector de racha (escudo del calendario)."""
    return {"fechas": servicio.dias_protegidos(usuario, zona, habito_id, desde, hasta)}
