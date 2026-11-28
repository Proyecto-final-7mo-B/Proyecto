"""Filas de PostgreSQL -> objetos del contrato (funciones puras del repositorio)."""

import uuid
from datetime import UTC, date, datetime, timedelta, timezone
from decimal import Decimal
from typing import Any

from kaizen.infraestructura.postgres.repositorio_habitos import (
    arbol,
    evaluacion,
    habito,
    recomendacion,
)

C1, S1, S2 = uuid.uuid4(), uuid.uuid4(), uuid.uuid4()


def fila_catalogo(sub: uuid.UUID, unidad: str | None, con_referencia: bool) -> dict[str, Any]:
    return {
        "c_id": C1, "c_clave": "ejercicio", "c_nombre": "Ejercicio", "color": "#D9480F",
        "c_icono": "fitness_center", "s_id": sub, "s_clave": f"s{sub}", "s_nombre": "Sub",
        "s_icono": "x", "sentido": "aumentar", "unidad": unidad,
        "factor_a_base": Decimal("1.000000") if unidad else None, "paso": Decimal("5.00"),
        "minimo": Decimal("1.00"), "u_maximo": Decimal("1440.00"),
        "r_id": uuid.uuid4() if con_referencia else None, "periodo": "semana",
        "unidad_base": "min", "optimo_desde": Decimal("150.00"), "optimo_hasta": Decimal("300.00"),
        "r_maximo": None, "piso_bajada": None, "cita": "OMS 2020", "fuentes": "F11",
        "url": "https://doi.org/x", "confianza": "alta", "nota": None,
    }  # fmt: skip


def test_arbol_agrupa_unidades_y_referencia() -> None:
    filas = [
        fila_catalogo(S1, "min", True),
        fila_catalogo(S1, "h", True),
        fila_catalogo(S2, None, False),  # subcategoría sin unidades ni rango
    ]
    [cat] = arbol(filas)
    s1, s2 = cat["subcategorias"]
    assert [u["unidad"] for u in s1["unidades"]] == ["min", "h"]
    assert s1["referencia"]["optimo_desde"] == 150.0  # número, no texto
    assert s1["referencia"]["maximo"] is None
    assert s2["unidades"] == [] and s2["referencia"] is None


def fila_habito(**cambios: Any) -> dict[str, Any]:
    fila: dict[str, Any] = {
        "id": uuid.uuid4(), "nombre": "Leer", "unidad": "páginas", "meta": Decimal("15.00"),
        "nivel": None, "c_id": C1, "c_clave": "educacion", "c_nombre": "Educación",
        "color": "#2563EB", "c_icono": "school", "s_id": S1, "s_clave": "lectura",
        "s_nombre": "Lectura", "s_icono": "menu_book", "s_sentido": "aumentar", "prioridad": 2,
        "intencion": None, "frecuencia_tipo": "diaria", "dias_semana": None,
        "veces_semana": None, "escalera_activa": True, "activo": True,
        "fecha_creacion": datetime(2026, 9, 1, 8, 0, tzinfo=timezone(timedelta(hours=-6))),
        "recomendacion_id": None,
        "racha_actual": None, "racha_maxima": None, "ultima_fecha": None,
        "protector_usado_semana": None, "zona": "bajo", "sentido": "aumentar",
        "volumen": Decimal("131.25"), "unidad_base": "min", "periodo": "semana",
        "optimo_desde": Decimal("24"), "optimo_hasta": Decimal("48"), "maximo": None,
        "meta_sugerida": Decimal("24"), "paso": Decimal("1"), "cita": "Bavishi 2016",
        "fuentes": "F28", "url": "https://x", "confianza": "baja", "nota": None,
        "programado": True, "g_id": None, "g_cumplido": None, "g_valor": None,
    }  # fmt: skip
    return fila | cambios


def test_habito_sin_racha_ni_registro() -> None:
    h = habito(fila_habito(), date(2026, 11, 26))
    assert h["meta"] == 15.0 and h["nivel"] == 1
    assert h["racha"] == {
        "actual": 0,
        "maxima": 0,
        "ultima_fecha": None,
        "protegida_esta_semana": False,
    }
    assert h["hoy"]["registro"] is None
    assert h["fecha_creacion"] == datetime(2026, 9, 1, 14, 0, tzinfo=UTC)  # en UTC
    assert h["evaluacion"]["volumen"] == 131.25


def test_habito_con_registro_de_hoy() -> None:
    rid = uuid.uuid4()
    h = habito(fila_habito(g_id=rid, g_cumplido=True, g_valor=Decimal("18")), date(2026, 11, 26))
    assert h["hoy"]["registro"] == {"id": rid, "cumplido": True, "valor": 18.0}


def test_evaluacion_vacia_es_none() -> None:
    assert evaluacion({}) is None


def fila_recomendacion(**cambios: Any) -> dict[str, Any]:
    fila: dict[str, Any] = {
        "id": uuid.uuid4(),
        "clave": "caminar_rapido",
        "nombre": "Caminar a paso rápido",
        "unidad": "min",
        "meta": Decimal("30.00"),
        "frecuencia_tipo": "dias_semana",
        "dias_semana": 31,
        "veces_semana": None,
        "momento": "Después de comer",
        "porque": "La OMS recomienda 150 a 300 minutos a la semana.",
        "fuentes": "F11",
        "orden": 1,
        "activo": True,
        "c_id": uuid.uuid4(),
        "c_clave": "ejercicio",
        "c_nombre": "Ejercicio",
        "color": "#D9480F",
        "c_icono": "fitness_center",
        "s_id": uuid.uuid4(),
        "s_clave": "aerobico_moderado",
        "s_nombre": "Aeróbico moderado",
        "s_icono": "directions_walk",
        "s_sentido": "aumentar",
        "zona": "optimo",
        "optimo_desde": Decimal("30"),
        "optimo_hasta": Decimal("60"),
    }
    return fila | cambios


def test_recomendacion_para_usuario_y_para_admin() -> None:
    usuario = recomendacion(fila_recomendacion(), con_activo=False)
    assert usuario["meta"] == 30
    assert usuario["frecuencia"] == {"tipo": "dias_semana", "dias_semana": 31, "veces_semana": None}
    assert usuario["categoria"]["clave"] == "ejercicio"
    assert "activo" not in usuario
    admin = recomendacion(fila_recomendacion(activo=False), con_activo=True)
    assert (admin["activo"], admin["orden"]) == (False, 1)


def test_recomendacion_sin_referencia() -> None:
    r = recomendacion(
        fila_recomendacion(zona="sin_referencia", optimo_desde=None, optimo_hasta=None), False
    )
    assert (r["optimo_desde"], r["optimo_hasta"]) == (None, None)
