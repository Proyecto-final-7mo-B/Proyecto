"""Pruebas del cifrado de cápsulas (AES-256-GCM)."""

import uuid

import pytest
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from kaizen.dominio.excepciones import DatoAlterado, ValidacionError
from kaizen.infraestructura.seguridad.cifrado import CifradorCapsulas

LLAVE_HEX = "00" * 32
cifrador = CifradorCapsulas.desde_hex(LLAVE_HEX)
ID = uuid.uuid4()


def test_cifra_y_descifra_el_mismo_mensaje() -> None:
    blob = cifrador.cifrar("Lo lograste, sigue así", ID)
    assert cifrador.descifrar(blob, ID) == "Lo lograste, sigue así"


def test_formato_nonce_cifrado_tag() -> None:
    blob = cifrador.cifrar("hola", ID)
    assert len(blob) == 12 + len(b"hola") + 16
    assert b"hola" not in blob


def test_mismo_mensaje_da_cifrados_distintos_por_el_nonce() -> None:
    assert cifrador.cifrar("hola", ID) != cifrador.cifrar("hola", ID)


def test_no_se_puede_mover_a_otra_capsula() -> None:
    blob = cifrador.cifrar("hola", ID)
    with pytest.raises(DatoAlterado):
        cifrador.descifrar(blob, uuid.uuid4())


def test_detecta_un_byte_alterado() -> None:
    blob = bytearray(cifrador.cifrar("hola", ID))
    blob[15] ^= 1
    with pytest.raises(DatoAlterado):
        cifrador.descifrar(bytes(blob), ID)


def test_compatible_con_el_formato_del_poblador() -> None:
    # poblar.py: nonce + AESGCM.encrypt(nonce, mensaje, capsula_id.bytes)
    nonce = b"\x01" * 12
    blob = nonce + AESGCM(bytes.fromhex(LLAVE_HEX)).encrypt(nonce, b"desde poblar", ID.bytes)
    assert cifrador.descifrar(blob, ID) == "desde poblar"


def test_rechaza_mensajes_de_mas_de_4096_bytes() -> None:
    with pytest.raises(ValidacionError):
        cifrador.cifrar("a" * 4097, ID)


def test_rechaza_llaves_de_tamano_incorrecto() -> None:
    with pytest.raises(ValueError, match="32 bytes"):
        CifradorCapsulas(b"corta")
