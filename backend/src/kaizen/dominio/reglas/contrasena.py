"""Política de contraseña (contrato v1.4, §2.3).

- De 12 a 128 caracteres, sin reglas de composición (ASVS 2.1).
- No puede ser igual al correo.
- Se rechaza si está en la lista de contraseñas comunes.
"""

from kaizen.dominio.excepciones import ValidacionError

MINIMO = 12
MAXIMO = 128

# Lista corta de ejemplo; se puede cargar una más grande desde un archivo.
COMUNES = frozenset(
    {
        "123456789012",
        "contrasena123",
        "contraseña123",
        "password1234",
        "qwertyuiop12",
        "kaizenkaizen",
    }
)


class PoliticaContrasena:
    """Valida una contraseña nueva antes de guardarla."""

    def __init__(self, comunes: frozenset[str] = COMUNES) -> None:
        self._comunes = frozenset(c.lower() for c in comunes)

    def validar(self, contrasena: str, correo: str) -> None:
        """Lanza ValidacionError si la contraseña no cumple. Si cumple, no regresa nada."""
        if not MINIMO <= len(contrasena) <= MAXIMO:
            raise ValidacionError(f"La contraseña debe tener entre {MINIMO} y {MAXIMO} caracteres")
        if contrasena.strip().lower() == correo.strip().lower():
            raise ValidacionError("La contraseña no puede ser igual al correo")
        if contrasena.lower() in self._comunes:
            raise ValidacionError("La contraseña es demasiado común")
