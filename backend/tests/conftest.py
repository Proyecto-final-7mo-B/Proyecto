"""Piezas compartidas por las pruebas: un repositorio falso en memoria y la app armada con él."""

import base64
import uuid
from dataclasses import replace
from datetime import UTC, date, datetime, timedelta
from typing import Any
from uuid import UUID

import pytest
from fastapi.testclient import TestClient

from kaizen.api.main import construir_app
from kaizen.aplicacion.puertos import (
    ConsultaEvaluacion,
    CuentaLogin,
    HabitoDesdeRecomendacion,
    NuevoHabito,
    NuevoRegistro,
    Objeto,
    Recomendacion,
    ResultadoRegistro,
    UsuarioActual,
)
from kaizen.aplicacion.servicios.autenticacion import ServicioAutenticacion
from kaizen.aplicacion.servicios.habitos import ServicioHabitos
from kaizen.aplicacion.servicios.registros import ServicioRegistros
from kaizen.dominio.excepciones import (
    FechaFueraDeRango,
    HabitoArchivado,
    KaizenError,
    NoEncontrado,
    RecomendacionNoDisponible,
    ValidacionError,
)
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
RECOMENDACION = {
    "id": uuid.uuid4(),
    "clave": "caminar_rapido",
    "nombre": "Caminar a paso rápido",
    "categoria": CATEGORIA,
    "subcategoria": SUBCATEGORIA,
    "unidad": "min",
    "meta": 30.0,
    "frecuencia": {"tipo": "dias_semana", "dias_semana": 31, "veces_semana": None},
    "momento": "Después de comer",
    "porque": "La OMS recomienda de 150 a 300 minutos a la semana.",
    "fuentes": "F11",
    "zona": "optimo",
    "optimo_desde": 30.0,
    "optimo_hasta": 60.0,
}
FUENTE = {
    "clave": "F01",
    "tema": "formacion",
    "referencia": "Lally y otros (2010). How are habits formed.",
    "enlace": "10.1002/ejsp.674",
    "dato": "De 18 a 254 días; mediana 66.",
    "verificada": "Sí",
    "confianza": "Media",
}


class RepoHabitosFalso:
    """Implementa RepositorioHabitos en memoria. Cada hábito recuerda a su dueño (como la RLS)."""

    def __init__(self) -> None:
        self.habitos: dict[UUID, tuple[UUID, Objeto]] = {}  # id -> (dueño, hábito)
        self.consultas: list[ConsultaEvaluacion] = []
        # clave -> recomendación (con activo y orden, como la tabla)
        self.recomendaciones: dict[str, Objeto] = {
            "caminar_rapido": RECOMENDACION | {"activo": True, "orden": 1}
        }
        self.protegidos: dict[UUID, list[date]] = {}  # id de hábito -> días perdonados
        self.guardadas: list[tuple[UUID, str | None]] = []  # (admin, ip) de cada PUT

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

    def crear(
        self, usuario: UsuarioActual, zona: str, nuevo: NuevoHabito | HabitoDesdeRecomendacion
    ) -> UUID:
        if isinstance(nuevo, HabitoDesdeRecomendacion):  # lo que hace el trigger de la base
            rec = next(
                (r for r in self.recomendaciones.values() if r["id"] == nuevo.recomendacion_id),
                None,
            )
            if rec is None or not rec["activo"]:
                raise RecomendacionNoDisponible("Esa recomendación ya no está disponible")
            datos = {
                "nombre": rec["nombre"],
                "unidad": rec["unidad"],
                "meta": rec["meta"],
                "intencion": rec["momento"],
                "frecuencia": rec["frecuencia"],
                "recomendacion_id": rec["id"],
            }
        else:
            f = nuevo.frecuencia
            datos = {
                "nombre": nuevo.nombre,
                "unidad": nuevo.unidad,
                "meta": float(nuevo.meta),
                "intencion": nuevo.intencion,
                "frecuencia": {
                    "tipo": f.tipo,
                    "dias_semana": f.dias_semana,
                    "veces_semana": f.veces_semana,
                },
                "recomendacion_id": None,
            }
        habito_id = uuid.uuid4()
        self.habitos[habito_id] = (
            usuario.id,
            datos
            | {
                "id": habito_id,
                "nivel": 1,
                "categoria": CATEGORIA,
                "subcategoria": SUBCATEGORIA,
                "prioridad": nuevo.prioridad,
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

    def recomendados(self, zona: str, incluir_inactivas: bool = False) -> list[Objeto]:
        filas = sorted(self.recomendaciones.values(), key=lambda r: (r["orden"], r["nombre"]))
        if incluir_inactivas:
            return filas
        return [
            {k: v for k, v in r.items() if k not in ("activo", "orden")}
            for r in filas
            if r["activo"]
        ]

    def dias_protegidos(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, desde: date, hasta: date
    ) -> list[date] | None:
        dueno, _ = self.habitos.get(habito_id, (None, {}))
        if dueno != usuario.id:
            return None
        return [d for d in self.protegidos.get(habito_id, []) if desde <= d <= hasta]

    def fuentes(self, zona: str) -> list[Objeto]:
        return [FUENTE]

    def guardar_recomendacion(
        self, admin: UsuarioActual, zona: str, datos: Recomendacion, ip: str | None
    ) -> Objeto:
        self.guardadas.append((admin.id, ip))
        f = datos.frecuencia
        previa = self.recomendaciones.get(datos.clave, {"id": uuid.uuid4()})
        fila = RECOMENDACION | {
            "id": previa["id"],
            "clave": datos.clave,
            "nombre": datos.nombre,
            "unidad": datos.unidad,
            "meta": float(datos.meta),
            "frecuencia": {
                "tipo": f.tipo,
                "dias_semana": f.dias_semana,
                "veces_semana": f.veces_semana,
            },
            "momento": datos.momento,
            "porque": datos.porque,
            "fuentes": datos.fuentes,
            "activo": datos.activo,
            "orden": datos.orden,
        }
        self.recomendaciones[datos.clave] = fila
        return fila


class RepoRegistrosFalso:
    """Implementa RepositorioRegistros en memoria, con las reglas de sp_registrar_checkin.

    Usa los hábitos del repositorio falso de hábitos (mismo dueño, archivado o no).
    La racha falsa es simplemente cuántos días cumplidos hay (la real la calcula la base).
    """

    def __init__(self, habitos: RepoHabitosFalso) -> None:
        self._habitos = habitos
        self.registros: dict[tuple[UUID, date], Objeto] = {}  # (hábito, fecha) -> registro

    def _un_checkin(self, usuario: UsuarioActual, r: NuevoRegistro) -> Objeto:
        dueno, h = self._habitos.habitos.get(r.habito_id, (None, {}))
        if dueno != usuario.id:
            raise NoEncontrado("Hábito no encontrado")
        if not h["activo"]:
            raise HabitoArchivado("El hábito está archivado")
        if r.fecha > date.today() + timedelta(days=1):
            raise FechaFueraDeRango("No se puede registrar una fecha futura")
        otro = next((x for x in self.registros.values() if x["id"] == r.id), None)
        if otro and (otro["habito_id"], otro["fecha"]) != (r.habito_id, r.fecha):
            raise ValidacionError("Ese id ya es de otro check-in", campo="id")
        previo = self.registros.get((r.habito_id, r.fecha))
        self.registros[(r.habito_id, r.fecha)] = {
            "id": previo["id"] if previo else r.id,  # un día = un check-in: se queda el primero
            "habito_id": r.habito_id,
            "fecha": r.fecha,
            "cumplido": r.cumplido,
            "valor": None if r.valor is None else float(r.valor),
            "origen": r.origen,
            "registrado_en": datetime.now(UTC),
        }
        racha = sum(
            1 for x in self.registros.values() if x["habito_id"] == r.habito_id and x["cumplido"]
        )
        return {"id": self.registros[(r.habito_id, r.fecha)]["id"], "racha_actual": racha}

    def registrar(self, usuario: UsuarioActual, zona: str, registro: NuevoRegistro) -> Objeto:
        return self._un_checkin(usuario, registro)

    def registrar_lote(
        self, usuario: UsuarioActual, zona: str, registros: list[NuevoRegistro]
    ) -> list[ResultadoRegistro]:
        resultados = []
        for r in registros:
            try:
                resultados.append(
                    ResultadoRegistro(r.id, self._un_checkin(usuario, r)["racha_actual"])
                )
            except KaizenError as error:
                resultados.append(ResultadoRegistro(r.id, error=error))
        return resultados

    def historial(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, desde: date, hasta: date
    ) -> list[Objeto] | None:
        dueno, _ = self._habitos.habitos.get(habito_id, (None, {}))
        if dueno != usuario.id:
            return None
        return sorted(
            (x for (h, f), x in self.registros.items() if h == habito_id and desde <= f <= hasta),
            key=lambda x: x["fecha"],
        )


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
def repo_registros(repo_habitos: RepoHabitosFalso) -> RepoRegistrosFalso:
    return RepoRegistrosFalso(repo_habitos)


@pytest.fixture
def servicio_registros(repo_registros: RepoRegistrosFalso) -> ServicioRegistros:
    return ServicioRegistros(repo_registros)


@pytest.fixture
def cliente(
    servicio: ServicioAutenticacion,
    servicio_habitos: ServicioHabitos,
    servicio_registros: ServicioRegistros,
    emisor: EmisorTokens,
) -> TestClient:
    app = construir_app(
        servicio, servicio_habitos, servicio_registros, emisor, revisar_base=lambda: True
    )
    return TestClient(app)


@pytest.fixture
def usuario_id() -> UUID:
    return uuid.uuid4()


@pytest.fixture
def cabeceras(emisor: EmisorTokens, usuario_id: UUID) -> dict[str, str]:
    """Cabecera Authorization con un token de acceso válido (como el que da el login)."""
    par = emisor.emitir_par(usuario_id, "MX-NORTE", "usuario")
    return {"Authorization": f"Bearer {par.acceso}"}


@pytest.fixture
def cabeceras_admin(emisor: EmisorTokens) -> dict[str, str]:
    par = emisor.emitir_par(uuid.uuid4(), "MX-CENTRO-SUR", "admin")
    return {"Authorization": f"Bearer {par.acceso}"}
