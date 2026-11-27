"""Pruebas de la calculadora de rachas (mismos casos que las pruebas SQL de fn_rachas)."""

from datetime import date, timedelta

from hypothesis import given
from hypothesis import strategies as st

from kaizen.dominio.reglas.frecuencia import Diaria, DiasSemana, Frecuencia, NPorSemana
from kaizen.dominio.reglas.rachas import CalculadoraRacha, Racha

INICIO = date(2026, 11, 2)  # lunes
calc = CalculadoraRacha()


def dias(*valores: bool | None, desde: date = INICIO) -> dict[date, bool]:
    """Arma un historial: True cumplido, False no cumplido, None sin registro."""
    return {desde + timedelta(i): v for i, v in enumerate(valores) if v is not None}


def test_sin_historial_racha_en_cero() -> None:
    assert calc.calcular(Diaria(), {}) == Racha(0, 0, None)


def test_diaria_diez_dias_seguidos() -> None:
    racha = calc.calcular(Diaria(), dias(*[True] * 10))
    assert racha == Racha(10, 10, INICIO + timedelta(9))


def test_una_falla_la_perdona_el_protector() -> None:
    # antes del protector daba actual 1, máxima 9
    racha = calc.calcular(Diaria(), dias(*[True] * 9, False, True))
    assert (racha.actual, racha.maxima) == (10, 10)
    assert racha.ultimo_protegido == INICIO + timedelta(9)


def test_dia_programado_sin_registro_lo_perdona_el_protector() -> None:
    # antes del protector daba 1
    racha = calc.calcular(Diaria(), dias(True, True, None, True))
    assert (racha.actual, racha.maxima) == (3, 3)


def test_falla_sin_racha_no_usa_el_protector() -> None:
    racha = calc.calcular(Diaria(), dias(False, True))
    assert racha == Racha(1, 1, INICIO + timedelta(1), None)


# Mismos casos que db/cambios/pruebas_evidencia.sql, sección 4: dos semanas de lunes a domingo.
def test_sql_una_falla_en_la_semana() -> None:
    racha = calc.calcular(Diaria(), dias(True, True, None, *[True] * 11))
    assert (racha.actual, racha.ultimo_protegido) == (13, INICIO + timedelta(2))


def test_sql_dos_fallas_en_la_misma_semana_rompen() -> None:
    racha = calc.calcular(Diaria(), dias(True, True, None, True, None, *[True] * 9))
    assert racha.actual == 9


def test_sql_una_falla_en_cada_semana() -> None:
    racha = calc.calcular(Diaria(), dias(True, True, None, *[True] * 6, None, *[True] * 4))
    assert racha.actual == 12


def test_hasta_cuenta_como_fallados_los_dias_sin_registro() -> None:
    historial = dias(*[True] * 5)  # lunes a viernes
    sabado, domingo = INICIO + timedelta(5), INICIO + timedelta(6)
    assert calc.calcular(Diaria(), historial, hasta=sabado).actual == 5  # protegido
    assert calc.calcular(Diaria(), historial, hasta=domingo).actual == 0  # segundo fallo
    assert calc.calcular(Diaria(), historial, hasta=INICIO).actual == 5  # antes del fin: igual


def test_lmv_no_se_rompe_en_dias_libres() -> None:
    # lunes a viernes: L cumple, M libre, X cumple, J libre, V cumple
    racha = calc.calcular(DiasSemana(1 + 4 + 16), dias(True, None, True, None, True))
    assert racha == Racha(3, 3, INICIO + timedelta(4))


def test_dia_no_programado_cumplido_no_suma() -> None:
    racha = calc.calcular(DiasSemana(1), dias(True, True))  # solo lunes; el martes no cuenta
    assert (racha.actual, racha.maxima) == (1, 1)


def test_n_por_semana_solo_cuentan_dias_con_registro() -> None:
    # L y J cumplen, M y X no cuentan, V lo perdona el protector, S rompe, D empieza otra
    racha = calc.calcular(NPorSemana(3), dias(True, None, None, True, False, False, True))
    assert (racha.actual, racha.maxima) == (1, 2)


FRECUENCIAS: list[Frecuencia] = [Diaria(), DiasSemana(21), DiasSemana(127), NPorSemana(3)]
historiales = st.lists(st.sampled_from([True, False, None]), max_size=60)


@given(historiales, st.sampled_from(FRECUENCIAS))
def test_propiedad_la_maxima_nunca_es_menor_que_la_actual(
    valores: list[bool | None], frecuencia: Frecuencia
) -> None:
    racha = calc.calcular(frecuencia, dias(*valores))
    assert 0 <= racha.actual <= racha.maxima


@given(historiales)
def test_propiedad_cumplir_un_dia_mas_suma_exactamente_uno(valores: list[bool | None]) -> None:
    historial = dias(*valores)
    antes = calc.calcular(Diaria(), historial)
    siguiente = (max(historial) + timedelta(1)) if historial else INICIO
    despues = calc.calcular(Diaria(), {**historial, siguiente: True})
    assert despues.actual == antes.actual + 1
