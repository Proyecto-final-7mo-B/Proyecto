"""Reglas del servicio de hábitos que son de la API (no de la base)."""

from datetime import UTC, date, datetime

import pytest

from conftest import RepoHabitosFalso
from kaizen.aplicacion.servicios.habitos import ServicioHabitos
from kaizen.dominio.excepciones import FechaFueraDeRango

MX = "America/Mexico_City"


def servicio_a_las(instante: datetime) -> ServicioHabitos:
    return ServicioHabitos(RepoHabitosFalso(), lambda: instante)


def test_hoy_es_el_dia_del_usuario_no_el_de_utc() -> None:
    # 27-nov 03:00 UTC = 26-nov 21:00 en México: para el usuario todavía es el 26
    s = servicio_a_las(datetime(2026, 11, 27, 3, 0, tzinfo=UTC))
    assert s.hoy(MX) == date(2026, 11, 26)
    assert s.hoy("UTC") == date(2026, 11, 27)


def test_fecha_acepta_ayer_hoy_y_manana() -> None:
    s = servicio_a_las(datetime(2026, 11, 27, 18, 0, tzinfo=UTC))
    for dia in (26, 27, 28):
        assert s.validar_fecha(date(2026, 11, dia), MX) == date(2026, 11, dia)
    assert s.validar_fecha(None, MX) == date(2026, 11, 27)


@pytest.mark.parametrize("dia", [25, 29])
def test_fecha_fuera_de_rango(dia: int) -> None:
    s = servicio_a_las(datetime(2026, 11, 27, 18, 0, tzinfo=UTC))
    with pytest.raises(FechaFueraDeRango):
        s.validar_fecha(date(2026, 11, dia), MX)


def test_actualizar_rechaza_campos_no_editables_aunque_no_pase_por_la_api() -> None:
    import uuid

    from kaizen.aplicacion.puertos import UsuarioActual
    from kaizen.dominio.excepciones import ValidacionError

    s = ServicioHabitos(RepoHabitosFalso())  # reloj real
    yo = UsuarioActual(uuid.uuid4(), "MX-NORTE", "usuario")
    with pytest.raises(ValidacionError) as error:
        s.actualizar(yo, MX, uuid.uuid4(), {"meta": 99})
    assert error.value.campo == "meta"


def test_admin_exige_rol_aunque_no_pase_por_la_api() -> None:
    import uuid

    from kaizen.aplicacion.puertos import UsuarioActual
    from kaizen.dominio.excepciones import RolInsuficiente

    s = ServicioHabitos(RepoHabitosFalso())
    yo = UsuarioActual(uuid.uuid4(), "MX-NORTE", "usuario")
    with pytest.raises(RolInsuficiente):
        s.recomendaciones_admin(yo, MX)
