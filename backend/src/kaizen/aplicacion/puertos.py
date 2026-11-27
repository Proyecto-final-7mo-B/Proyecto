"""Puertos: interfaces (Protocol) que la infraestructura implementa.

El servicio de autenticación depende de estas interfaces, no de PostgreSQL. Así se prueba con
un repositorio falso en memoria y en producción se usa el de PostgreSQL (inversión de dependencias).
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Protocol
from uuid import UUID

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
