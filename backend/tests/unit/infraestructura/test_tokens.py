"""Pruebas de los JWT EdDSA."""

import base64
import uuid
from datetime import UTC, datetime, timedelta

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from kaizen.dominio.excepciones import TokenInvalido
from kaizen.infraestructura.seguridad.tokens import EmisorTokens

SEMILLA = base64.b64encode(bytes(range(32))).decode()
emisor = EmisorTokens(SEMILLA, "kaizen-test")
UID = uuid.uuid4()


def test_par_de_tokens_con_los_claims_del_contrato() -> None:
    par = emisor.emitir_par(UID, "MX-NORTE", "usuario")
    acceso = emisor.verificar(par.acceso, "acceso")
    renov = emisor.verificar(par.renovacion, "renovacion")
    assert acceso["sub"] == renov["sub"] == str(UID)
    assert acceso["region"] == "MX-NORTE"
    assert acceso["rol"] == "usuario"
    assert acceso["sid"] == renov["jti"] == str(par.jti_sesion)
    assert renov["fam"] == str(par.familia)
    assert acceso["exp"] - acceso["iat"] == 15 * 60
    assert par.expira_en == 900


def test_la_cabecera_lleva_kid_y_eddsa() -> None:
    cabecera = jwt.get_unverified_header(emisor.emitir_par(UID, "LATAM", "admin").acceso)
    assert cabecera == {"alg": "EdDSA", "kid": "kaizen-test", "typ": "JWT"}


def test_rotacion_conserva_la_familia() -> None:
    primero = emisor.emitir_par(UID, "LATAM", "usuario")
    rotado = emisor.emitir_par(UID, "LATAM", "usuario", familia=primero.familia)
    assert rotado.familia == primero.familia
    assert rotado.jti_sesion != primero.jti_sesion


def test_rechaza_el_tipo_equivocado() -> None:
    par = emisor.emitir_par(UID, "LATAM", "usuario")
    with pytest.raises(TokenInvalido):
        emisor.verificar(par.renovacion, "acceso")


def test_rechaza_tokens_vencidos() -> None:
    viejo = emisor.emitir_par(UID, "LATAM", "usuario", ahora=datetime.now(UTC) - timedelta(hours=1))
    with pytest.raises(TokenInvalido):
        emisor.verificar(viejo.acceso, "acceso")


def test_rechaza_firma_de_otra_llave() -> None:
    otra = EmisorTokens(base64.b64encode(b"\x07" * 32).decode(), "kaizen-test")
    with pytest.raises(TokenInvalido):
        emisor.verificar(otra.emitir_par(UID, "LATAM", "admin").acceso, "acceso")


def test_rechaza_token_alterado() -> None:
    token = emisor.emitir_par(UID, "LATAM", "usuario").acceso
    cabecera, cuerpo, firma = token.split(".")
    with pytest.raises(TokenInvalido):
        emisor.verificar(f"{cabecera}.{cuerpo}x.{firma}", "acceso")


def test_rechaza_alg_none() -> None:
    falso = jwt.encode({"sub": str(UID), "typ": "acceso"}, key=None, algorithm="none")
    with pytest.raises(TokenInvalido):
        emisor.verificar(falso, "acceso")


def test_compatible_con_la_forma_de_cargar_la_llave_del_leeme() -> None:
    privada = Ed25519PrivateKey.from_private_bytes(base64.b64decode(SEMILLA))
    token = emisor.emitir_par(UID, "LATAM", "usuario").acceso
    claims = jwt.decode(token, privada.public_key(), algorithms=["EdDSA"])
    assert claims["typ"] == "acceso"
