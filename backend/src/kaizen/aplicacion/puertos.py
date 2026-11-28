"""Puertos: interfaces (Protocol) que la infraestructura implementa.

El servicio de autenticación depende de estas interfaces, no de PostgreSQL. Así se prueba con
un repositorio falso en memoria y en producción se usa el de PostgreSQL (inversión de dependencias).
"""

from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Protocol
from uuid import UUID

from kaizen.dominio.excepciones import KaizenError
from kaizen.infraestructura.seguridad.tokens import ParTokens


@dataclass(frozen=True, slots=True)
class CuentaLogin:
    """Lo que el login necesita saber de un usuario."""

    id: UUID
    region: str
    nombre: str
    rol: str
    password_hash: str
    intentos_fallidos: int
    bloqueado_hasta: datetime | None
    suspendida: bool


class RepositorioAuth(Protocol):
    def buscar_cuenta(self, email_hmac: str) -> CuentaLogin | None: ...

    def registrar_fallo(
        self, cuenta: CuentaLogin, intentos: int, bloqueado_hasta: datetime | None, ip: str | None
    ) -> None: ...

    def registrar_exito(
        self, cuenta: CuentaLogin, par: ParTokens, nuevo_hash: str | None, ip: str | None
    ) -> None: ...

    def auditar(
        self,
        usuario_id: UUID | None,
        region: str | None,
        accion: str,
        resultado: str,
        ip: str | None,
    ) -> None: ...


# ---------------------------------------------------------------------------------------------
# Hábitos y catálogo (contrato v1.6, §6.3 y §6.4)
# ---------------------------------------------------------------------------------------------


@dataclass(frozen=True, slots=True)
class UsuarioActual:
    """Quién hace la petición: sale del token de acceso, nunca del cuerpo (anti-IDOR)."""

    id: UUID
    region: str
    rol: str


@dataclass(frozen=True, slots=True)
class FrecuenciaDatos:
    tipo: str  # diaria | dias_semana | n_por_semana
    dias_semana: int | None = None
    veces_semana: int | None = None


@dataclass(frozen=True, slots=True)
class NuevoHabito:
    nombre: str
    subcategoria_id: UUID
    frecuencia: FrecuenciaDatos
    meta: Decimal
    unidad: str
    escalera_activa: bool = True
    prioridad: int = 2
    intencion: str | None = None


@dataclass(frozen=True, slots=True)
class HabitoDesdeRecomendacion:
    """Crear desde una recomendación: la base copia nombre, meta, unidad, frecuencia e intención."""

    recomendacion_id: UUID
    prioridad: int = 2
    escalera_activa: bool = True


@dataclass(frozen=True, slots=True)
class Recomendacion:
    """Alta o cambio de una recomendación (administración)."""

    clave: str
    subcategoria_id: UUID
    nombre: str
    unidad: str
    meta: Decimal
    frecuencia: FrecuenciaDatos
    momento: str
    porque: str
    fuentes: str
    activo: bool = True
    orden: int = 99


@dataclass(frozen=True, slots=True)
class ConsultaEvaluacion:
    subcategoria_id: UUID
    unidad: str
    meta: Decimal
    frecuencia: FrecuenciaDatos


# Los repositorios regresan diccionarios con la forma de los objetos del contrato (§5);
# la API los valida con sus modelos de Pydantic antes de responder.
Objeto = dict[str, Any]


class RepositorioHabitos(Protocol):
    def categorias(self, zona: str) -> list[Objeto]: ...

    def evaluar(
        self, usuario: UsuarioActual, zona: str, consulta: ConsultaEvaluacion
    ) -> Objeto: ...

    def listar(
        self,
        usuario: UsuarioActual,
        zona: str,
        fecha: date,
        archivados: bool,
        habito_id: UUID | None = None,
    ) -> list[Objeto]: ...

    def crear(
        self, usuario: UsuarioActual, zona: str, nuevo: NuevoHabito | HabitoDesdeRecomendacion
    ) -> UUID: ...

    def actualizar(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, cambios: dict[str, Any]
    ) -> bool: ...

    def recomendados(self, zona: str, incluir_inactivas: bool = False) -> list[Objeto]: ...

    def dias_protegidos(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, desde: date, hasta: date
    ) -> list[date] | None: ...

    def fuentes(self, zona: str) -> list[Objeto]: ...

    def guardar_recomendacion(
        self, admin: UsuarioActual, zona: str, datos: Recomendacion, ip: str | None
    ) -> Objeto: ...


# ---------------------------------------------------------------- check-ins (§6.5)


@dataclass(frozen=True, slots=True)
class NuevoRegistro:
    """Un check-in. El id lo genera la app: reenviarlo no duplica (idempotencia)."""

    id: UUID
    habito_id: UUID
    fecha: date
    cumplido: bool
    valor: Decimal | None = None
    origen: str = "manual"


@dataclass(frozen=True, slots=True)
class ResultadoRegistro:
    """Resultado de un elemento del lote: la racha nueva, o el error por el que se rechazó."""

    id: UUID
    racha_actual: int | None = None
    error: KaizenError | None = None


class RepositorioRegistros(Protocol):
    def registrar(self, usuario: UsuarioActual, zona: str, registro: NuevoRegistro) -> Objeto: ...

    def registrar_lote(
        self, usuario: UsuarioActual, zona: str, registros: list[NuevoRegistro]
    ) -> list[ResultadoRegistro]: ...

    def historial(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, desde: date, hasta: date
    ) -> list[Objeto] | None: ...
