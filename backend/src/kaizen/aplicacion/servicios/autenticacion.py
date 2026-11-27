"""Caso de uso: iniciar sesión (contrato v1.4, §6.1 POST /auth/login y §2.2 bloqueo)."""

from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from kaizen.aplicacion.puertos import CuentaLogin, RepositorioAuth
from kaizen.dominio.excepciones import CredencialesInvalidas, CuentaBloqueada, CuentaSuspendida
from kaizen.infraestructura.seguridad.contrasenas import HasherContrasenas
from kaizen.infraestructura.seguridad.seudonimos import GeneradorHmac
from kaizen.infraestructura.seguridad.tokens import EmisorTokens, ParTokens

MAX_FALLOS = 10
TIEMPO_BLOQUEO = timedelta(minutes=15)


@dataclass(frozen=True, slots=True)
class SesionIniciada:
    par: ParTokens
    cuenta: CuentaLogin


class ServicioAutenticacion:
    def __init__(
        self,
        repo: RepositorioAuth,
        hasher: HasherContrasenas,
        hmac: GeneradorHmac,
        emisor: EmisorTokens,
        reloj: Callable[[], datetime] = lambda: datetime.now(UTC),
    ) -> None:
        self._repo = repo
        self._hasher = hasher
        self._hmac = hmac
        self._emisor = emisor
        self._reloj = reloj
        # Hash de relleno: si el correo no existe se verifica contra él, para que la respuesta
        # tarde lo mismo y no delate qué correos están registrados.
        self._hash_relleno = hasher.hashear("relleno-para-tiempo-constante")

    def iniciar_sesion(self, email: str, contrasena: str, ip: str | None) -> SesionIniciada:
        ahora = self._reloj()
        cuenta = self._repo.buscar_cuenta(self._hmac.correo(email))

        if cuenta is None:
            self._hasher.verificar(self._hash_relleno, contrasena)
            self._repo.auditar(None, None, "auth.login", "fallo", ip)
            raise CredencialesInvalidas("Correo o contraseña incorrectos")

        if cuenta.bloqueado_hasta is not None and cuenta.bloqueado_hasta > ahora:
            self._repo.auditar(cuenta.id, cuenta.region, "auth.login", "denegado", ip)
            raise CuentaBloqueada(int((cuenta.bloqueado_hasta - ahora).total_seconds()) + 1)

        if not self._hasher.verificar(cuenta.password_hash, contrasena):
            intentos = cuenta.intentos_fallidos + 1
            bloqueo = ahora + TIEMPO_BLOQUEO if intentos >= MAX_FALLOS else None
            self._repo.registrar_fallo(cuenta, 0 if bloqueo else intentos, bloqueo, ip)
            raise CredencialesInvalidas("Correo o contraseña incorrectos")

        # La suspensión solo se revela si la contraseña fue correcta (contrato §6.1)
        if cuenta.suspendida:
            self._repo.auditar(cuenta.id, cuenta.region, "auth.login", "denegado", ip)
            raise CuentaSuspendida("La cuenta está suspendida")

        par = self._emisor.emitir_par(cuenta.id, cuenta.region, cuenta.rol, ahora=ahora)
        nuevo_hash = (
            self._hasher.hashear(contrasena)
            if self._hasher.necesita_rehash(cuenta.password_hash)
            else None
        )
        self._repo.registrar_exito(cuenta, par, nuevo_hash, ip)
        return SesionIniciada(par=par, cuenta=cuenta)
