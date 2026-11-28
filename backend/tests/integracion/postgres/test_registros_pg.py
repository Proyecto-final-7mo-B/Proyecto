"""Check-ins contra el PostgreSQL local: sp_registrar_checkin, la racha y los SAVEPOINT del lote.

Se salta sin base: corre con KAIZEN_PRUEBAS_INTEGRACION=1 y el .env de desarrollo.
Los hábitos que crea se archivan al final (no hay DELETE de hábitos).
"""

import os
import uuid
from collections.abc import Iterator
from datetime import date, timedelta
from typing import Any

import pytest
from fastapi.testclient import TestClient

pytestmark = pytest.mark.skipif(
    os.environ.get("KAIZEN_PRUEBAS_INTEGRACION") != "1",
    reason="sin base de datos local (KAIZEN_PRUEBAS_INTEGRACION=1 para correrla)",
)

DEMO = os.environ.get("KAIZEN_DEMO_PASSWORD", "KaizenDemo2026!")
ZONA = {"X-Zona-Horaria": "America/Mexico_City"}
CAMINAR_RAPIDO = "e34965d9-e9ee-9413-31db-81d7be7fef64"


@pytest.fixture(scope="module")
def cliente() -> Iterator[TestClient]:
    from kaizen.api.main import crear_app

    with TestClient(crear_app()) as c:
        yield c


def cabeceras_de(cliente: TestClient, correo: str) -> dict[str, str]:
    r = cliente.post("/api/v1/auth/login", json={"email": correo, "contrasena": DEMO})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token_acceso']}"} | ZONA


@pytest.fixture(scope="module")
def demo(cliente: TestClient) -> dict[str, str]:
    return cabeceras_de(cliente, "demo@kaizen.test")


@pytest.fixture
def habito(cliente: TestClient, demo: dict[str, str]) -> Iterator[dict[str, Any]]:
    """Un hábito diario nuevo (desde una recomendación), creado hoy."""
    r = cliente.post("/api/v1/habitos", json={"recomendacion_id": CAMINAR_RAPIDO}, headers=demo)
    assert r.status_code == 201, r.text
    yield r.json()
    cliente.patch(f"/api/v1/habitos/{r.json()['id']}", json={"activo": False}, headers=demo)


def hoy(cliente: TestClient, demo: dict[str, str], habito_id: str) -> date:
    """El "hoy" del usuario según la API (México), no el de la máquina."""
    return date.fromisoformat(
        cliente.get(f"/api/v1/habitos/{habito_id}", headers=demo).json()["hoy"]["fecha"]
    )


def checkin(habito_id: str, dia: date, **cambios: Any) -> dict[str, Any]:
    cuerpo = {"id": str(uuid.uuid4()), "habito_id": habito_id, "fecha": str(dia), "cumplido": True}
    return cuerpo | cambios


def test_checkin_sube_la_racha_y_es_idempotente(
    cliente: TestClient, demo: dict[str, str], habito: dict[str, Any]
) -> None:
    dia = hoy(cliente, demo, habito["id"])
    cuerpo = checkin(habito["id"], dia, valor=30)
    r = cliente.post("/api/v1/registros", json=cuerpo, headers=demo)
    assert r.status_code == 200, r.text
    assert r.json() == {"id": cuerpo["id"], "racha_actual": 1}
    # reenviar el mismo check-in con otro valor: no duplica, gana el último
    r = cliente.post("/api/v1/registros", json=cuerpo | {"valor": 45}, headers=demo)
    assert r.json()["racha_actual"] == 1
    # otro id para el mismo día: la base conserva el primer id
    r = cliente.post("/api/v1/registros", json=checkin(habito["id"], dia, valor=50), headers=demo)
    assert r.json()["id"] == cuerpo["id"]
    url = f"/api/v1/habitos/{habito['id']}/registros"
    [guardado] = cliente.get(
        url, params={"desde": str(dia), "hasta": str(dia)}, headers=demo
    ).json()
    assert (guardado["valor"], guardado["origen"]) == (50, "manual")
    assert cliente.get(f"/api/v1/habitos/{habito['id']}", headers=demo).json()["hoy"]["registro"]


def test_id_de_otro_dia_da_422(
    cliente: TestClient, demo: dict[str, str], habito: dict[str, Any]
) -> None:
    dia = hoy(cliente, demo, habito["id"])
    cuerpo = checkin(habito["id"], dia)
    cliente.post("/api/v1/registros", json=cuerpo, headers=demo)
    r = cliente.post(
        "/api/v1/registros", json=cuerpo | {"fecha": str(dia + timedelta(days=1))}, headers=demo
    )
    assert r.status_code == 422
    assert r.json()["errores"][0]["campo"] == "id"


def test_reglas_de_la_base(
    cliente: TestClient, demo: dict[str, str], habito: dict[str, Any]
) -> None:
    dia = hoy(cliente, demo, habito["id"])
    casos = [
        (checkin(habito["id"], dia + timedelta(days=2)), 422, "fecha-fuera-de-rango"),
        (checkin(habito["id"], dia - timedelta(days=30)), 422, "fecha-fuera-de-rango"),
        (checkin(str(uuid.uuid4()), dia), 404, "no-encontrado"),
    ]
    for cuerpo, status, tipo in casos:
        r = cliente.post("/api/v1/registros", json=cuerpo, headers=demo)
        assert (r.status_code, r.json()["type"].split("/")[-1]) == (status, tipo), cuerpo


def test_lote_guarda_los_buenos_aunque_falle_uno(
    cliente: TestClient, demo: dict[str, str], habito: dict[str, Any]
) -> None:
    dia = hoy(cliente, demo, habito["id"])
    bueno = checkin(habito["id"], dia, origen="offline", valor=20)
    malo = checkin(habito["id"], dia + timedelta(days=5), origen="offline")
    ajeno = checkin(str(uuid.uuid4()), dia, origen="offline")
    r = cliente.post(
        "/api/v1/registros/lote", json={"registros": [malo, bueno, ajeno]}, headers=demo
    )
    assert r.status_code == 200, r.text
    estados = [x["estado"] for x in r.json()["resultados"]]
    assert estados == ["rechazado", "aceptado", "rechazado"]
    assert r.json()["resultados"][1]["racha_actual"] == 1
    url = f"/api/v1/habitos/{habito['id']}/registros"
    guardados = cliente.get(url, params={"desde": str(dia), "hasta": str(dia)}, headers=demo).json()
    assert [g["origen"] for g in guardados] == ["offline"]  # el SAVEPOINT salvó al bueno


def test_historial_del_demo_y_de_otro_usuario(cliente: TestClient, demo: dict[str, str]) -> None:
    caminar = next(
        h for h in cliente.get("/api/v1/habitos", headers=demo).json() if h["nombre"] == "Caminar"
    )
    hasta = date.fromisoformat(caminar["hoy"]["fecha"])
    url = f"/api/v1/habitos/{caminar['id']}/registros"
    registros = cliente.get(
        url, params={"desde": str(hasta - timedelta(days=60)), "hasta": str(hasta)}, headers=demo
    ).json()
    assert len(registros) > 10  # el demo tiene historial
    fechas = [r["fecha"] for r in registros]
    assert fechas == sorted(fechas)
    admin = cabeceras_de(cliente, "admin@kaizen.test")
    rango = {"desde": str(hasta - timedelta(days=7)), "hasta": str(hasta)}
    assert cliente.get(url, params=rango, headers=admin).status_code == 404
