"""Traduce los errores de PostgreSQL (SQLSTATE) a errores de Kaizen.

La base hace cumplir las reglas con códigos propios KZ001–KZ017 (RAISE ... USING ERRCODE).
Aquí se convierten en excepciones del dominio, y la API las vuelve problem+json (contrato §3).
El texto de la base (message_primary) es en español y sin datos internos: sirve como detalle.
"""

from psycopg import Error

from kaizen.dominio.excepciones import (
    CategoriaInactiva,
    ConsentimientoRequerido,
    CuentaSuspendida,
    FechaFueraDeRango,
    HabitoArchivado,
    KaizenError,
    NoEncontrado,
    NombreDuplicado,
    OperacionNoPermitida,
    RegionInvalida,
    RolInsuficiente,
    SubcategoriaInactiva,
    UnidadNoPermitida,
    ValidacionError,
)

# SQLSTATE -> excepción. KZ001, KZ005 y KZ015 dependen del endpoint: se traducen ahí.
TABLA: dict[str, type[KaizenError]] = {
    "KZ002": RegionInvalida,
    "KZ003": FechaFueraDeRango,
    "KZ004": NoEncontrado,
    "KZ006": OperacionNoPermitida,
    "KZ007": HabitoArchivado,
    "KZ008": ConsentimientoRequerido,
    "KZ010": RolInsuficiente,
    "KZ012": CuentaSuspendida,
    "KZ013": NombreDuplicado,
    "KZ014": CategoriaInactiva,
    "KZ016": UnidadNoPermitida,
    "KZ017": SubcategoriaInactiva,
}

# Errores de validación: KZ011 (regla de la base) y 23514 (CHECK de una columna)
VALIDACION = frozenset({"KZ011", "23514"})


def traducir(error: Error) -> KaizenError | None:
    """Regresa el error de Kaizen que corresponde, o None si es un error inesperado."""
    codigo = error.sqlstate or ""
    mensaje = error.diag.message_primary or "Dato inválido"
    if codigo in VALIDACION:
        if codigo == "23514":  # el texto de un CHECK nombra la restricción: no se muestra
            mensaje = "Un valor está fuera de lo permitido"
        return ValidacionError(mensaje)
    clase = TABLA.get(codigo)
    return clase(mensaje) if clase else None
