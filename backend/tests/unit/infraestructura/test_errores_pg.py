"""Traducción de SQLSTATE (KZ0xx) a errores de Kaizen."""

from types import SimpleNamespace

import pytest

from kaizen.dominio.excepciones import (
    FechaFueraDeRango,
    KaizenError,
    NoEncontrado,
    SubcategoriaInactiva,
    UnidadNoPermitida,
    ValidacionError,
)
from kaizen.infraestructura.postgres.errores import traducir


def error_pg(sqlstate: str, mensaje: str | None = "texto de la base") -> object:
    """Imita un psycopg.Error: solo usa sqlstate y diag.message_primary."""
    return SimpleNamespace(sqlstate=sqlstate, diag=SimpleNamespace(message_primary=mensaje))


@pytest.mark.parametrize(
    ("codigo", "clase"),
    [
        ("KZ003", FechaFueraDeRango),
        ("KZ004", NoEncontrado),
        ("KZ016", UnidadNoPermitida),
        ("KZ017", SubcategoriaInactiva),
        ("KZ011", ValidacionError),
    ],
)
def test_codigos_propios(codigo: str, clase: type[KaizenError]) -> None:
    error = traducir(error_pg(codigo))  # type: ignore[arg-type]
    assert isinstance(error, clase)
    assert str(error) == "texto de la base"


def test_check_no_muestra_el_nombre_de_la_restriccion() -> None:
    error = traducir(error_pg("23514", 'violates check constraint "capsula_racha_objetivo_check"'))  # type: ignore[arg-type]
    assert isinstance(error, ValidacionError)
    assert "capsula" not in str(error)


def test_error_desconocido_no_se_traduce() -> None:
    assert traducir(error_pg("57014")) is None  # type: ignore[arg-type]  # statement_timeout


def test_sin_mensaje_usa_uno_generico() -> None:
    assert str(traducir(error_pg("KZ011", None))) == "Dato inválido"  # type: ignore[arg-type]
