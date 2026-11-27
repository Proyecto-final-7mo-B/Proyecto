"""HMAC-SHA256: buscar un correo sin guardarlo en claro y seudonimizar usuarios.

- Directorio de usuarios: HMAC(KAIZEN_EMAIL_HMAC_KEY, correo.strip().lower()), igual que poblar.py.
- Analítica (MongoDB): HMAC(KAIZEN_ANALITICA_HMAC_KEY, str(usuario_id).lower()).
"""

import hashlib
import hmac
from uuid import UUID


class GeneradorHmac:
    """Calcula HMAC-SHA256 en hexadecimal con una llave fija."""

    def __init__(self, llave_hex: str) -> None:
        self._llave = bytes.fromhex(llave_hex)

    def _hmac(self, texto: str) -> str:
        return hmac.new(self._llave, texto.encode("utf-8"), hashlib.sha256).hexdigest()

    def correo(self, correo: str) -> str:
        """Llave del directorio de usuarios (directorio_usuarios.email_hmac)."""
        return self._hmac(correo.strip().lower())

    def usuario(self, usuario_id: UUID) -> str:
        """Seudónimo usuario_sdn para MongoDB: no se puede revertir sin la llave."""
        return self._hmac(str(usuario_id).lower())
