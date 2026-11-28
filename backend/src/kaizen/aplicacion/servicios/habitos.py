"""Casos de uso de hábitos y del catálogo (contrato v1.6, §6.3 y §6.4).

Las reglas con respaldo científico (rangos, zonas, topes) viven en PostgreSQL: aquí no se
reimplementan. El servicio pone las reglas que son de la API: qué fecha es "hoy" para el
usuario, qué campos se pueden cambiar y que un hábito de otro usuario dé 404.
"""

from collections.abc import Callable
from datetime import UTC, date, datetime
from typing import Any
from uuid import UUID
from zoneinfo import ZoneInfo

from kaizen.aplicacion.puertos import (
    ConsultaEvaluacion,
    HabitoDesdeRecomendacion,
    NuevoHabito,
    Objeto,
    Recomendacion,
    RepositorioHabitos,
    UsuarioActual,
)
from kaizen.dominio.excepciones import (
    FechaFueraDeRango,
    NoEncontrado,
    RolInsuficiente,
    ValidacionError,
)

MAX_DIAS_RANGO = 366  # contrato §4: desde ≤ hasta, máximo 366 días

# Campos que acepta PATCH /habitos/{id}. meta, frecuencia y categoria_id NO (contrato §6.4).
EDITABLES = frozenset(
    {"nombre", "subcategoria_id", "unidad", "prioridad", "intencion", "escalera_activa", "activo"}
)


def _ahora() -> datetime:
    return datetime.now(UTC)


class ServicioHabitos:
    def __init__(self, repo: RepositorioHabitos, reloj: Callable[[], datetime] = _ahora) -> None:
        self._repo = repo
        self._reloj = reloj

    def hoy(self, zona: str) -> date:
        """La fecha de hoy en la zona del usuario (no la de UTC)."""
        return self._reloj().astimezone(ZoneInfo(zona)).date()

    def validar_fecha(self, fecha: date | None, zona: str) -> date:
        """?fecha= solo puede ser de hoy-1 a hoy+1 (contrato §1). Sin fecha: hoy."""
        hoy = self.hoy(zona)
        if fecha is None:
            return hoy
        if abs((fecha - hoy).days) > 1:
            raise FechaFueraDeRango("La fecha debe estar entre ayer y mañana")
        return fecha

    def categorias(self, zona: str) -> list[Objeto]:
        return self._repo.categorias(zona)

    def evaluar(self, usuario: UsuarioActual, zona: str, consulta: ConsultaEvaluacion) -> Objeto:
        return self._repo.evaluar(usuario, zona, consulta)

    def listar(
        self, usuario: UsuarioActual, zona: str, fecha: date | None, archivados: bool = False
    ) -> list[Objeto]:
        dia = self.validar_fecha(fecha, zona)
        return self._repo.listar(usuario, zona, dia, archivados)

    def obtener(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, fecha: date | None = None
    ) -> Objeto:
        dia = self.validar_fecha(fecha, zona)
        encontrados = self._repo.listar(usuario, zona, dia, True, habito_id)
        if not encontrados:  # no existe o es de otro usuario: la misma respuesta
            raise NoEncontrado("Hábito no encontrado")
        return encontrados[0]

    def crear(
        self, usuario: UsuarioActual, zona: str, nuevo: NuevoHabito | HabitoDesdeRecomendacion
    ) -> Objeto:
        """Personalizado o desde una recomendación (la base copia los datos de la recomendación)."""
        habito_id = self._repo.crear(usuario, zona, nuevo)
        return self.obtener(usuario, zona, habito_id)

    def actualizar(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, cambios: dict[str, Any]
    ) -> Objeto:
        no_permitidos = set(cambios) - EDITABLES
        if no_permitidos:
            campo = sorted(no_permitidos)[0]
            raise ValidacionError("Este campo no se puede cambiar", campo=campo)
        if "subcategoria_id" in cambios and "unidad" not in cambios:
            raise ValidacionError(
                "Al cambiar la subcategoría manda también una unidad válida", campo="unidad"
            )
        if cambios and not self._repo.actualizar(usuario, zona, habito_id, cambios):
            raise NoEncontrado("Hábito no encontrado")
        return self.obtener(usuario, zona, habito_id)

    # ------------------------------------------------------------- v1.7

    def recomendados(self, zona: str) -> list[Objeto]:
        """Los hábitos recomendados activos (20 por categoría)."""
        return self._repo.recomendados(zona)

    def fuentes(self, zona: str) -> list[Objeto]:
        """Las fuentes científicas de "Acerca de Kaizen"."""
        return self._repo.fuentes(zona)

    def dias_protegidos(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, desde: date, hasta: date
    ) -> list[date]:
        """Días que perdonó el protector de racha (escudo del calendario)."""
        if desde > hasta:
            raise ValidacionError("desde no puede ser después de hasta", campo="desde")
        if (hasta - desde).days > MAX_DIAS_RANGO:
            raise ValidacionError(f"El rango es de máximo {MAX_DIAS_RANGO} días", campo="hasta")
        fechas = self._repo.dias_protegidos(usuario, zona, habito_id, desde, hasta)
        if fechas is None:  # no existe o es de otro usuario
            raise NoEncontrado("Hábito no encontrado")
        return fechas

    # ------------------------------------------------------------- administración

    @staticmethod
    def exigir_admin(usuario: UsuarioActual) -> None:
        """Primera barrera: el rol del token. La base lo vuelve a comprobar (KZ010)."""
        if usuario.rol != "admin":
            raise RolInsuficiente("Se necesita el rol de administrador")

    def recomendaciones_admin(self, usuario: UsuarioActual, zona: str) -> list[Objeto]:
        self.exigir_admin(usuario)
        return self._repo.recomendados(zona, incluir_inactivas=True)

    def guardar_recomendacion(
        self, usuario: UsuarioActual, zona: str, datos: Recomendacion, ip: str | None
    ) -> Objeto:
        self.exigir_admin(usuario)
        return self._repo.guardar_recomendacion(usuario, zona, datos, ip)
