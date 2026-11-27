"""Cifrado de las cápsulas con AES-256-GCM.

Formato guardado en capsula.mensaje_cifrado: nonce(12) || cifrado || tag(16), igual que poblar.py.
AAD = los 16 bytes del UUID de la cápsula: así un mensaje no se puede copiar a otra cápsula.
"""

import os
from uuid import UUID

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from kaizen.dominio.excepciones import DatoAlterado, ValidacionError

TAM_NONCE = 12
TAM_LLAVE = 32  # AES-256
MAX_MENSAJE = 4096  # bytes, contrato §6.9


class CifradorCapsulas:
    """Cifra y descifra el mensaje de una cápsula con una llave simétrica."""

    def __init__(self, llave: bytes, version: int = 1) -> None:
        if len(llave) != TAM_LLAVE:
            raise ValueError("La llave de cápsulas debe tener 32 bytes (64 caracteres hex)")
        self._aes = AESGCM(llave)
        self.version = version

    @classmethod
    def desde_hex(cls, llave_hex: str, version: int = 1) -> "CifradorCapsulas":
        """Crea el cifrador con la llave tal como viene en KAIZEN_CAPSULA_KEY_V1."""
        return cls(bytes.fromhex(llave_hex), version)

    def cifrar(self, mensaje: str, capsula_id: UUID) -> bytes:
        datos = mensaje.encode("utf-8")
        if len(datos) > MAX_MENSAJE:
            raise ValidacionError(f"El mensaje no puede pasar de {MAX_MENSAJE} bytes")
        nonce = os.urandom(TAM_NONCE)  # nunca se repite con la misma llave
        return nonce + self._aes.encrypt(nonce, datos, capsula_id.bytes)

    def descifrar(self, blob: bytes, capsula_id: UUID) -> str:
        try:
            datos = self._aes.decrypt(blob[:TAM_NONCE], blob[TAM_NONCE:], capsula_id.bytes)
        except InvalidTag as error:
            raise DatoAlterado("La cápsula fue alterada o no corresponde a este id") from error
        return datos.decode("utf-8")
