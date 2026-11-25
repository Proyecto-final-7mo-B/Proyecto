"""Pruebas de las frecuencias."""

from datetime import date

import pytest

from kaizen.dominio.excepciones import ValidacionError
from kaizen.dominio.reglas.frecuencia import Diaria, DiasSemana, NPorSemana

LUNES = date(2026, 11, 23)
MARTES = date(2026, 11, 24)
MIERCOLES = date(2026, 11, 25)
DOMINGO = date(2026, 11, 29)


def test_diaria_toca_todos_los_dias() -> None:
    assert Diaria().es_programado(LUNES)
    assert Diaria().es_programado(DOMINGO)


def test_dias_semana_lunes_miercoles_viernes() -> None:
    lmv = DiasSemana(1 + 4 + 16)
    assert lmv.mascara == 21
    assert lmv.es_programado(LUNES)
    assert not lmv.es_programado(MARTES)
    assert lmv.es_programado(MIERCOLES)
    assert not lmv.es_programado(DOMINGO)


def test_dias_semana_domingo_es_el_bit_6() -> None:
    assert DiasSemana(64).es_programado(DOMINGO)


@pytest.mark.parametrize("mascara", [0, 128, -1])
def test_dias_semana_rechaza_mascaras_invalidas(mascara: int) -> None:
    with pytest.raises(ValidacionError):
        DiasSemana(mascara)


def test_n_por_semana_no_tiene_dias_fijos_ni_rompe() -> None:
    tres = NPorSemana(3)
    assert tres.veces == 3
    assert not tres.es_programado(LUNES)
    assert not tres.rompe_si_falta()


@pytest.mark.parametrize("veces", [0, 8])
def test_n_por_semana_rechaza_valores_invalidos(veces: int) -> None:
    with pytest.raises(ValidacionError):
        NPorSemana(veces)
