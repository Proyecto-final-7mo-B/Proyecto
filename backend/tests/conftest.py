"""Piezas compartidas por las pruebas: un repositorio falso en memoria y la app armada con él."""

import base64
import uuid
from dataclasses import replace
from datetime import UTC, date, datetime
from typing import Any
from uuid import UUID

import pytest
from fastapi.testclient import TestClient

from kaizen.api.main import construir_app
from kaizen.aplicacion.puertos import (
    ConsultaEvaluacion,
    CuentaLogin,
    NuevoHabito,
    Objeto,
    UsuarioActual,
)
from kaizen.aplicacion.servicios.autenticacion import ServicioAutenticacion
from kaizen.aplicacion.servicios.habitos import ServicioHabitos
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


CATEGORIA = {
    "id": uuid.uuid4(),
    "clave": "ejercicio",
    "nombre": "Ejercicio",
    "color": "#D9480F",
    "icono": "fitness_center",
}
SUBCATEGORIA = {
    "id": uuid.uuid4(),
    "clave": "aerobico_moderado",
    "nombre": "Aeróbico moderado",
    "icono": "directions_bike",
    "sentido": "aumentar",
}
EVALUACION_OPTIMA = {"zona": "optimo", "sentido": "aumentar", "paso": 5.0}


class RepoHabitosFalso:
    """Implementa RepositorioHabitos en memoria. Cada hábito recuerda a su dueño (como la RLS)."""

    def __init__(self) -> None:
        self.habitos: dict[UUID, tuple[UUID, Objeto]] = {}  # id -> (dueño, hábito)
        self.consultas: list[ConsultaEvaluacion] = []

    def categorias(self, zona: str) -> list[Objeto]:
        unidad = {"unidad": "min", "factor_a_base": 1, "paso": 5, "minimo": 1, "maximo": 1440}
        sub = SUBCATEGORIA | {"unidades": [unidad], "referencia": None}
        return [CATEGORIA | {"subcategorias": [sub]}]

    def evaluar(self, usuario: UsuarioActual, zona: str, consulta: ConsultaEvaluacion) -> Objeto:
        self.consultas.append(consulta)
        return EVALUACION_OPTIMA

    def listar(
        self,
        usuario: UsuarioActual,
        zona: str,
        fecha: date,
        archivados: bool,
        habito_id: UUID | None = None,
    ) -> list[Objeto]:
        visibles = [
            h | {"hoy": {"fecha": fecha, "programado": True, "registro": None}}
            for dueno, h in self.habitos.values()
            if dueno == usuario.id
            and (archivados or h["activo"])
            and (habito_id is None or h["id"] == habito_id)
        ]
        return sorted(visibles, key=lambda h: (h["prioridad"], h["nombre"]))

    def crear(self, usuario: UsuarioActual, zona: str, nuevo: NuevoHabito) -> UUID:
        habito_id = uuid.uuid4()
        f = nuevo.frecuencia
        self.habitos[habito_id] = (
            usuario.id,
            {
                "id": habito_id,
                "nombre": nuevo.nombre,
                "unidad": nuevo.unidad,
                "meta": float(nuevo.meta),
                "nivel": 1,
                "categoria": CATEGORIA,
                "subcategoria": SUBCATEGORIA,
                "prioridad": nuevo.prioridad,
                "intencion": nuevo.intencion,
                "frecuencia": {
                    "tipo": f.tipo,
                    "dias_semana": f.dias_semana,
                    "veces_semana": f.veces_semana,
                },
                "escalera_activa": nuevo.escalera_activa,
                "activo": True,
                "fecha_creacion": datetime.now(UTC),
                "racha": {
                    "actual": 0,
                    "maxima": 0,
                    "ultima_fecha": None,
                    "protegida_esta_semana": False,
                },
                "evaluacion": EVALUACION_OPTIMA,
            },
        )
        return habito_id

    def actualizar(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, cambios: dict[str, Any]
    ) -> bool:
        dueno, h = self.habitos.get(habito_id, (None, {}))
        if dueno != usuario.id:
            return False
        h.update({k: v for k, v in cambios.items() if k != "subcategoria_id"})
        return True


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
def repo_habitos() -> RepoHabitosFalso:
    return RepoHabitosFalso()


@pytest.fixture
def servicio_habitos(repo_habitos: RepoHabitosFalso, reloj: Reloj) -> ServicioHabitos:
    return ServicioHabitos(repo_habitos, reloj)


@pytest.fixture
def cliente(
    servicio: ServicioAutenticacion, servicio_habitos: ServicioHabitos, emisor: EmisorTokens
) -> TestClient:
    return TestClient(construir_app(servicio, servicio_habitos, emisor, revisar_base=lambda: True))


@pytest.fixture
def usuario_id() -> UUID:
    return uuid.uuid4()


@pytest.fixture
def cabeceras(emisor: EmisorTokens, usuario_id: UUID) -> dict[str, str]:
    """Cabecera Authorization con un token de acceso válido (como el que da el login)."""
    par = emisor.emitir_par(usuario_id, "MX-NORTE", "usuario")
    return {"Authorization": f"Bearer {par.acceso}"}
