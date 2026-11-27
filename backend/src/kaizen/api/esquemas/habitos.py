"""Esquemas de /categorias y /habitos (contrato v1.6, §4, §5, §6.3 y §6.4).

Las entradas rechazan campos de más (extra="forbid") y validan los límites del §4 antes de
llegar a la base. Las salidas son la forma exacta de los objetos del contrato.
"""

from datetime import date, datetime
from decimal import Decimal
from typing import Literal, Self
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from kaizen.aplicacion.puertos import ConsultaEvaluacion, FrecuenciaDatos, NuevoHabito


class Estricto(BaseModel):
    model_config = ConfigDict(extra="forbid")


Meta = Decimal  # > 0 y hasta 2 decimales: se valida con Field en cada modelo
Zona = Literal["bajo", "optimo", "alto", "excesivo", "sin_referencia"]
Sentido = Literal["aumentar", "reducir"]


# ---------------------------------------------------------------- entradas


class Frecuencia(Estricto):
    tipo: Literal["diaria", "dias_semana", "n_por_semana"]
    dias_semana: int | None = Field(default=None, ge=1, le=127)
    veces_semana: int | None = Field(default=None, ge=1, le=7)

    @model_validator(mode="after")
    def _coherente(self) -> Self:
        """dias_semana solo con 'dias_semana' y veces_semana solo con 'n_por_semana'."""
        if (self.tipo == "dias_semana") != (self.dias_semana is not None):
            raise ValueError("dias_semana va solo (y siempre) con tipo dias_semana")
        if (self.tipo == "n_por_semana") != (self.veces_semana is not None):
            raise ValueError("veces_semana va solo (y siempre) con tipo n_por_semana")
        return self

    def a_datos(self) -> FrecuenciaDatos:
        return FrecuenciaDatos(self.tipo, self.dias_semana, self.veces_semana)


class SolicitudEvaluacion(Estricto):
    subcategoria_id: UUID
    unidad: str = Field(min_length=1, max_length=30)
    meta: Meta = Field(gt=0, max_digits=10, decimal_places=2)
    frecuencia: Frecuencia

    def a_consulta(self) -> ConsultaEvaluacion:
        return ConsultaEvaluacion(
            self.subcategoria_id, self.unidad, self.meta, self.frecuencia.a_datos()
        )


class SolicitudHabito(Estricto):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [
                {
                    "nombre": "Caminar",
                    "subcategoria_id": "…",
                    "frecuencia": {"tipo": "diaria"},
                    "meta": 30,
                    "unidad": "min",
                    "prioridad": 1,
                    "intencion": "Después de comer",
                }
            ]
        },
    )

    nombre: str = Field(min_length=1, max_length=60)
    subcategoria_id: UUID
    frecuencia: Frecuencia
    meta: Meta = Field(gt=0, max_digits=10, decimal_places=2)
    unidad: str = Field(min_length=1, max_length=30)
    escalera_activa: bool = True
    prioridad: int = Field(default=2, ge=1, le=3)
    intencion: str | None = Field(default=None, min_length=1, max_length=120)

    def a_nuevo(self) -> NuevoHabito:
        return NuevoHabito(
            nombre=self.nombre,
            subcategoria_id=self.subcategoria_id,
            frecuencia=self.frecuencia.a_datos(),
            meta=self.meta,
            unidad=self.unidad,
            escalera_activa=self.escalera_activa,
            prioridad=self.prioridad,
            intencion=self.intencion,
        )


class CambiosHabito(BaseModel):
    """PATCH: cualquiera de estos campos. Los demás (meta, frecuencia, categoria_id…) dan 422."""

    model_config = ConfigDict(extra="forbid")

    nombre: str | None = Field(default=None, min_length=1, max_length=60)
    subcategoria_id: UUID | None = None
    unidad: str | None = Field(default=None, min_length=1, max_length=30)
    prioridad: int | None = Field(default=None, ge=1, le=3)
    intencion: str | None = Field(default=None, min_length=1, max_length=120)
    escalera_activa: bool | None = None
    activo: bool | None = None

    @model_validator(mode="after")
    def _sin_nulos(self) -> Self:
        """Solo intencion se puede borrar con null; los demás, si vienen, traen valor."""
        for campo in self.model_fields_set - {"intencion"}:
            if getattr(self, campo) is None:
                raise ValueError(f"{campo} no puede ser null")
        return self


# ---------------------------------------------------------------- salidas


class Evaluacion(BaseModel):
    zona: Zona
    sentido: Sentido | None = None
    volumen: float | None = None
    unidad_base: str | None = None
    periodo: Literal["dia", "semana"] | None = None
    optimo_desde: float | None = None
    optimo_hasta: float | None = None
    maximo: float | None = None
    meta_sugerida: float | None = None
    paso: float | None = None
    cita: str | None = None
    fuentes: str | None = None
    url: str | None = None
    confianza: str | None = None
    nota: str | None = None


class Unidad(BaseModel):
    unidad: str
    factor_a_base: float | None
    paso: float
    minimo: float
    maximo: float


class Referencia(BaseModel):
    periodo: Literal["dia", "semana"]
    unidad_base: str
    optimo_desde: float
    optimo_hasta: float
    maximo: float | None
    piso_bajada: float | None
    cita: str
    fuentes: str
    url: str
    confianza: str
    nota: str | None


class Subcategoria(BaseModel):
    id: UUID
    clave: str
    nombre: str
    icono: str
    sentido: Sentido
    unidades: list[Unidad]
    referencia: Referencia | None


class Categoria(BaseModel):
    id: UUID
    clave: str
    nombre: str
    color: str
    icono: str
    subcategorias: list[Subcategoria]


class CategoriaResumen(BaseModel):
    id: UUID
    clave: str
    nombre: str
    color: str
    icono: str


class SubcategoriaResumen(BaseModel):
    id: UUID
    clave: str
    nombre: str
    icono: str
    sentido: Sentido


class FrecuenciaSalida(BaseModel):
    tipo: Literal["diaria", "dias_semana", "n_por_semana"]
    dias_semana: int | None
    veces_semana: int | None


class Racha(BaseModel):
    actual: int
    maxima: int
    ultima_fecha: date | None
    protegida_esta_semana: bool


class RegistroHoy(BaseModel):
    id: UUID
    cumplido: bool
    valor: float | None


class Hoy(BaseModel):
    fecha: date
    programado: bool
    registro: RegistroHoy | None


class Habito(BaseModel):
    id: UUID
    nombre: str
    unidad: str
    meta: float
    nivel: int
    categoria: CategoriaResumen
    subcategoria: SubcategoriaResumen
    prioridad: int
    intencion: str | None
    frecuencia: FrecuenciaSalida
    escalera_activa: bool
    activo: bool
    fecha_creacion: datetime
    racha: Racha
    evaluacion: Evaluacion | None
    hoy: Hoy
