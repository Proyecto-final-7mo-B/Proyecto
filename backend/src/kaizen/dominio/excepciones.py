"""Errores propios del sistema.

Todas heredan de KaizenError. La API las traduce a respuestas HTTP; su texto nunca se
muestra tal cual al usuario. La jerarquia completa (KZ001 a KZ015) se agrega con la API.
"""


class KaizenError(Exception):
    """Base de todos los errores de Kaizen."""


class ErrorDominio(KaizenError):
    """Una regla del negocio no se cumple."""


class ValidacionError(ErrorDominio):
    """El dato tiene la forma correcta pero un valor invalido (HTTP 422)."""
