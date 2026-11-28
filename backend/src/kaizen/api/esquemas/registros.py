"""Esquemas de los check-ins (contrato v1.7, §4 y §6.5)."""

from datetime import date, datetime
from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from kaizen.aplicacion.puertos import NuevoRegistro

MAX_LOTE = 100  # contrato §6.5: hasta 100 check-ins por lote
Origen = Literal["manual", "rapido", "offline"]


class SolicitudRegistro(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [
                {
                    "id": "0b6f8c1e-5d2a-4f3b-9a7e-1c2d3e4f5a6b",
                    "habito_id": "…",
                    "fecha": "2026-11-23",
                    "cumplido": True,
                    "valor": 18,
                    "origen": "manual",
                }
            ]
        },
    )

    id: UUID  # lo genera la app: el mismo id reenviado no duplica el check-in
    habito_id: UUID
    fecha: date  # día LOCAL del usuario; la base revisa que vaya de la creación a hoy+1
    cumplido: bool
    valor: Decimal | None = Field(default=None, ge=0, max_digits=10, decimal_places=2)
    origen: Origen = "manual"

    def a_nuevo(self) -> NuevoRegistro:
        return NuevoRegistro(
            self.id, self.habito_id, self.fecha, self.cumplido, self.valor, self.origen
        )


class SolicitudLote(BaseModel):
    model_config = ConfigDict(extra="forbid")

    registros: list[SolicitudRegistro] = Field(min_length=1, max_length=MAX_LOTE)


class RegistroGuardado(BaseModel):
    id: UUID
    racha_actual: int


class ErrorElemento(BaseModel):
    type: str
    status: int
    title: str


class ResultadoElemento(BaseModel):
    id: UUID
    estado: Literal["aceptado", "rechazado"]
    racha_actual: int | None = None
    error: ErrorElemento | None = None


class RespuestaLote(BaseModel):
    resultados: list[ResultadoElemento]


class Registro(BaseModel):
    id: UUID
    habito_id: UUID
    fecha: date
    cumplido: bool
    valor: float | None
    origen: Origen
    registrado_en: datetime
