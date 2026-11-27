"""Guardar y verificar contraseñas con Argon2id.

Se usa PasswordHasher() con sus valores por defecto, igual que poblar.py, para que las
cuentas demo de la base se puedan verificar con este mismo código.
"""

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError


class HasherContrasenas:
    """Convierte una contraseña en un hash irreversible y la verifica después."""

    def __init__(self) -> None:
        self._ph = PasswordHasher()  # Argon2id, sal aleatoria por contraseña

    def hashear(self, contrasena: str) -> str:
        """Regresa el texto que se guarda en usuario.password_hash."""
        return self._ph.hash(contrasena)

    def verificar(self, hash_guardado: str, contrasena: str) -> bool:
        """True si la contraseña corresponde al hash. Nunca lanza error por contraseña mala."""
        try:
            return self._ph.verify(hash_guardado, contrasena)
        except (VerificationError, InvalidHashError):
            return False

    def necesita_rehash(self, hash_guardado: str) -> bool:
        """True si el hash se hizo con parámetros viejos y conviene recalcularlo al entrar."""
        return self._ph.check_needs_rehash(hash_guardado)
