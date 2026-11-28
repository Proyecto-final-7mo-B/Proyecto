"""Casos de uso de los check-ins (contrato v1.7, §6.5).

Las reglas de fondo las hace cumplir la base en sp_registrar_checkin y sus triggers:
que el hábito sea del usuario (KZ004), que no esté archivado (KZ007) y que la fecha vaya
de la creación del hábito a hoy+1 (KZ003). Aquí solo van las reglas que son de la API.
"""

from datetime import date
from uuid import UUID

from kaizen.aplicacion.puertos import (
    NuevoRegistro,
    Objeto,
    RepositorioRegistros,
    ResultadoRegistro,
    UsuarioActual,
)
from kaizen.aplicacion.servicios.habitos import validar_rango
from kaizen.dominio.excepciones import NoEncontrado


class ServicioRegistros:
    def __init__(self, repo: RepositorioRegistros) -> None:
        self._repo = repo

    def registrar(self, usuario: UsuarioActual, zona: str, registro: NuevoRegistro) -> Objeto:
        """Guarda (o reemplaza) el check-in del día y regresa la racha nueva."""
        return self._repo.registrar(usuario, zona, registro)

    def registrar_lote(
        self, usuario: UsuarioActual, zona: str, registros: list[NuevoRegistro]
    ) -> list[ResultadoRegistro]:
        """La cola sin conexión: cada check-in se acepta o se rechaza por separado."""
        return self._repo.registrar_lote(usuario, zona, registros)

    def historial(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, desde: date, hasta: date
    ) -> list[Objeto]:
        """Check-ins de un hábito entre dos fechas, para el calendario."""
        validar_rango(desde, hasta)
        registros = self._repo.historial(usuario, zona, habito_id, desde, hasta)
        if registros is None:  # no existe o es de otro usuario
            raise NoEncontrado("Hábito no encontrado")
        return registros
