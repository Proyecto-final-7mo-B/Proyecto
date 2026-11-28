"""Rutas de los check-ins (contrato v1.7, §6.5) y el historial de un hábito (§6.4).

El usuario y su región salen del token. Un hábito de otro usuario da 404.
"""

from datetime import date
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends

from kaizen.api.dependencias import servicio_registros, usuario_actual, zona_horaria
from kaizen.api.errores import resumen_de
from kaizen.api.esquemas.registros import (
    Registro,
    RegistroGuardado,
    RespuestaLote,
    SolicitudLote,
    SolicitudRegistro,
)
from kaizen.aplicacion.puertos import Objeto, UsuarioActual
from kaizen.aplicacion.servicios.registros import ServicioRegistros

router = APIRouter(tags=["registros"])

Usuario = Annotated[UsuarioActual, Depends(usuario_actual)]
ZonaHoraria = Annotated[str, Depends(zona_horaria)]
Servicio = Annotated[ServicioRegistros, Depends(servicio_registros)]


@router.post("/registros", response_model=RegistroGuardado)
def registrar(
    datos: SolicitudRegistro, usuario: Usuario, zona: ZonaHoraria, servicio: Servicio
) -> Objeto:
    """Check-in del día. Reenviarlo no duplica; con otro valor, reemplaza (gana el último)."""
    return servicio.registrar(usuario, zona, datos.a_nuevo())


@router.post("/registros/lote", response_model=RespuestaLote)
def registrar_lote(
    datos: SolicitudLote, usuario: Usuario, zona: ZonaHoraria, servicio: Servicio
) -> Objeto:
    """Cola sin conexión: hasta 100 check-ins; cada uno se acepta o se rechaza aparte."""
    resultados = servicio.registrar_lote(usuario, zona, [r.a_nuevo() for r in datos.registros])
    return {
        "resultados": [
            {"id": r.id, "estado": "aceptado", "racha_actual": r.racha_actual}
            if r.error is None
            else {"id": r.id, "estado": "rechazado", "error": resumen_de(r.error)}
            for r in resultados
        ]
    }


@router.get("/habitos/{habito_id}/registros", response_model=list[Registro])
def historial(
    habito_id: UUID,
    desde: date,
    hasta: date,
    usuario: Usuario,
    zona: ZonaHoraria,
    servicio: Servicio,
) -> list[Objeto]:
    """Check-ins del hábito entre dos fechas (máximo 366 días), ordenados por fecha."""
    return servicio.historial(usuario, zona, habito_id, desde, hasta)
