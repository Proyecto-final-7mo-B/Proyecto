"""Pruebas del caso de uso de login con un repositorio falso (sin base de datos)."""

from datetime import timedelta

import pytest
from argon2 import PasswordHasher

from conftest import CLAVE, Reloj, RepoFalso
from kaizen.aplicacion.servicios.autenticacion import ServicioAutenticacion
from kaizen.dominio.excepciones import CredencialesInvalidas, CuentaBloqueada, CuentaSuspendida
from kaizen.infraestructura.seguridad.tokens import EmisorTokens


def test_login_correcto_emite_tokens_y_abre_sesion(
    servicio: ServicioAutenticacion, repo: RepoFalso, emisor: EmisorTokens
) -> None:
    cuenta = repo.agregar("demo@kaizen.test")
    sesion = servicio.iniciar_sesion("Demo@Kaizen.test ", CLAVE, "10.0.0.1")
    claims = emisor.verificar(sesion.par.acceso, "acceso")
    assert claims["sub"] == str(cuenta.id)
    assert repo.sesiones == [sesion.par]
    assert repo.bitacora[-1] == (cuenta.id, "auth.login", "exito")


def test_correo_inexistente_da_el_mismo_error(
    servicio: ServicioAutenticacion, repo: RepoFalso
) -> None:
    with pytest.raises(CredencialesInvalidas):
        servicio.iniciar_sesion("nadie@kaizen.test", CLAVE, None)
    assert repo.bitacora == [(None, "auth.login", "fallo")]


def test_contrasena_mala_suma_un_intento(servicio: ServicioAutenticacion, repo: RepoFalso) -> None:
    repo.agregar("demo@kaizen.test", intentos_fallidos=3)
    with pytest.raises(CredencialesInvalidas):
        servicio.iniciar_sesion("demo@kaizen.test", "otra-contraseña", None)
    assert next(iter(repo.cuentas.values())).intentos_fallidos == 4


def test_diez_fallos_bloquean_15_minutos(
    servicio: ServicioAutenticacion, repo: RepoFalso, reloj: Reloj
) -> None:
    repo.agregar("demo@kaizen.test", intentos_fallidos=9)
    with pytest.raises(CredencialesInvalidas):
        servicio.iniciar_sesion("demo@kaizen.test", "otra-contraseña", None)
    with pytest.raises(CuentaBloqueada) as bloqueo:  # ni con la correcta entra
        servicio.iniciar_sesion("demo@kaizen.test", CLAVE, None)
    assert 0 < bloqueo.value.segundos <= 15 * 60 + 1
    reloj.ahora += timedelta(minutes=16)
    assert servicio.iniciar_sesion("demo@kaizen.test", CLAVE, None).par.acceso


def test_suspendida_solo_se_revela_con_la_contrasena_correcta(
    servicio: ServicioAutenticacion, repo: RepoFalso
) -> None:
    repo.agregar("suspendido@kaizen.test", suspendida=True)
    with pytest.raises(CredencialesInvalidas):
        servicio.iniciar_sesion("suspendido@kaizen.test", "otra-contraseña", None)
    with pytest.raises(CuentaSuspendida):
        servicio.iniciar_sesion("suspendido@kaizen.test", CLAVE, None)
    assert repo.sesiones == []


def test_rehash_si_el_hash_tiene_parametros_viejos(
    servicio: ServicioAutenticacion, repo: RepoFalso
) -> None:
    viejo = PasswordHasher(time_cost=1, memory_cost=8192).hash(CLAVE)
    repo.agregar("demo@kaizen.test", password_hash=viejo)
    servicio.iniciar_sesion("demo@kaizen.test", CLAVE, None)
    assert next(iter(repo.cuentas.values())).password_hash != viejo
