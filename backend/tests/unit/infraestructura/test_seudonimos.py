"""Pruebas del HMAC del correo y del seudónimo para la analítica."""

import hashlib
import hmac
import uuid

from kaizen.infraestructura.seguridad.seudonimos import GeneradorHmac

LLAVE_HEX = "6b" * 32
gen = GeneradorHmac(LLAVE_HEX)


def test_hmac_del_correo_igual_que_el_poblador() -> None:
    esperado = hmac.new(bytes.fromhex(LLAVE_HEX), b"demo@kaizen.test", hashlib.sha256).hexdigest()
    assert gen.correo("demo@kaizen.test") == esperado


def test_ignora_mayusculas_y_espacios() -> None:
    assert gen.correo("  Demo@Kaizen.TEST ") == gen.correo("demo@kaizen.test")


def test_es_hex_de_64_y_no_contiene_el_correo() -> None:
    h = gen.correo("demo@kaizen.test")
    assert len(h) == 64
    assert "demo" not in h


def test_otra_llave_da_otro_hmac() -> None:
    assert GeneradorHmac("00" * 32).correo("a@b.co") != gen.correo("a@b.co")


def test_seudonimo_de_usuario_estable() -> None:
    uid = uuid.uuid4()
    assert gen.usuario(uid) == gen.usuario(uid)
    assert str(uid) not in gen.usuario(uid)
