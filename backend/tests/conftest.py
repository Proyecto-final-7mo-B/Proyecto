"""Piezas compartidas por las pruebas: un repositorio falso en memoria y la app armada con él."""

import base64
import uuid
from dataclasses import replace
from datetime import UTC, datetime
from uuid import UUID

import pytest
from fastapi.testclient import TestClient

from kaizen.api.main import construir_app
from kaizen.aplicacion.puertos import CuentaLogin
from kaizen.aplicacion.servicios.autenticacion import ServicioAutenticacion
from kaizen.infraestructura.seguridad.contrasenas import HasherContrasenas
from kaizen.infraestructura.seguridad.seudonimos import GeneradorHmac
from kaizen.infraestructura.seguridad.tokens import EmisorTokens, ParTokens

CLAVE = "KaizenDemo2026!"
SEMILLA = base64.b64encode(bytes(range(32))).decode()
HMAC_HEX = "11" * 32
_hasher = HasherContrasenas()
_hash_demo = _hasher.hashear(CLAVE)  # se calcula una vez: Argon2 es lento a propósito


class RepoFalso:
    """Implementa RepositorioAuth en memoria (mismo contrato que el de PostgreSQL)."""

    def __init__(self) -> None:
        self.cuentas: dict[str, CuentaLogin] = {}
        self.sesiones: list[ParTokens] = []
        self.bitacora: list[tuple[UUID | None, str, str]] = []

    def agregar(self, correo: str, **cambios: object) -> CuentaLogin:
        cuenta = CuentaLogin(
            id=uuid.uuid4(),
            region="MX-NORTE",
            nombre="Demo",
            rol="usuario",
            password_hash=_hash_demo,
            intentos_fallidos=0,
            bloqueado_hasta=None,
            suspendida=False,
        )
        cuenta = replace(cuenta, **cambios)  # type: ignore[arg-type]
        self.cuentas[GeneradorHmac(HMAC_HEX).correo(correo)] = cuenta
        return cuenta

    def _guardar(self, cuenta: CuentaLogin) -> None:
        for k, v in self.cuentas.items():
            if v.id == cuenta.id:
                self.cuentas[k] = cuenta

    def buscar_cuenta(self, email_hmac: str) -> CuentaLogin | None:
        return self.cuentas.get(email_hmac)

    def registrar_fallo(
        self, cuenta: CuentaLogin, intentos: int, bloqueado_hasta: datetime | None, ip: str | None
    ) -> None:
        self._guardar(replace(cuenta, intentos_fallidos=intentos, bloqueado_hasta=bloqueado_hasta))
        self.bitacora.append((cuenta.id, "auth.login", "fallo"))

    def registrar_exito(
        self, cuenta: CuentaLogin, par: ParTokens, nuevo_hash: str | None, ip: str | None
    ) -> None:
        self._guardar(
            replace(
                cuenta,
                intentos_fallidos=0,
                bloqueado_hasta=None,
                password_hash=nuevo_hash or cuenta.password_hash,
            )
        )
        self.sesiones.append(par)
        self.bitacora.append((cuenta.id, "auth.login", "exito"))

    def auditar(
        self,
        usuario_id: UUID | None,
        region: str | None,
        accion: str,
        resultado: str,
        ip: str | None,
    ) -> None:
        self.bitacora.append((usuario_id, accion, resultado))


class Reloj:
    """Reloj controlable para probar el bloqueo de 15 minutos sin esperar."""

    def __init__(self) -> None:
        self.ahora = datetime.now(UTC)

    def __call__(self) -> datetime:
        return self.ahora


@pytest.fixture
def repo() -> RepoFalso:
    return RepoFalso()


@pytest.fixture
def reloj() -> Reloj:
    return Reloj()


@pytest.fixture
def emisor() -> EmisorTokens:
    return EmisorTokens(SEMILLA, "kaizen-test")


@pytest.fixture
def servicio(repo: RepoFalso, reloj: Reloj, emisor: EmisorTokens) -> ServicioAutenticacion:
    return ServicioAutenticacion(repo, _hasher, GeneradorHmac(HMAC_HEX), emisor, reloj)


@pytest.fixture
def cliente(servicio: ServicioAutenticacion) -> TestClient:
    return TestClient(construir_app(servicio, revisar_base=lambda: True))
