"""Errores propios del sistema.

Todas heredan de KaizenError. La API las traduce a respuestas HTTP (application/problem+json);
su texto nunca se muestra tal cual al usuario.
"""


class KaizenError(Exception):
    """Base de todos los errores de Kaizen."""


class ErrorDominio(KaizenError):
    """Una regla del negocio no se cumple."""


class ValidacionError(ErrorDominio):
    """El dato tiene la forma correcta pero un valor inválido (HTTP 422)."""

    def __init__(self, mensaje: str, campo: str | None = None) -> None:
        super().__init__(mensaje)
        self.campo = campo


class ErrorSeguridad(KaizenError):
    """Base de los errores de criptografía y autenticación."""


class DatoAlterado(ErrorSeguridad):
    """Un dato cifrado no pasó la verificación de integridad (tag de AES-GCM)."""


class TokenInvalido(ErrorSeguridad):
    """El JWT no es válido: firma, tipo, emisor o vencimiento (HTTP 401)."""


class CredencialesInvalidas(ErrorSeguridad):
    """Correo o contraseña incorrectos; el mismo error exista o no la cuenta (HTTP 401)."""


class CuentaSuspendida(ErrorSeguridad):
    """El administrador suspendió la cuenta (HTTP 403, KZ012)."""


class CuentaBloqueada(ErrorSeguridad):
    """Demasiados intentos fallidos: bloqueada por un tiempo (HTTP 429)."""

    def __init__(self, segundos: int) -> None:
        super().__init__(f"Cuenta bloqueada por {segundos} s")
        self.segundos = segundos
