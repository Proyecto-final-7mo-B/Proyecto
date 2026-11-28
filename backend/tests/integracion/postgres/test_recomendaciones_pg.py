"""v1.7 contra el PostgreSQL local: recomendados, protegidos, fuentes y administración.

Se salta sin base: corre con KAIZEN_PRUEBAS_INTEGRACION=1 y el .env de desarrollo.
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
URL = "/api/v1/habitos"
# md5('kaizen-recomendacion:' || clave)::uuid: el mismo id en el clúster, local y la app
CAMINAR_RAPIDO = "e34965d9-e9ee-9413-31db-81d7be7fef64"


@pytest.fixture(scope="module")
def cliente() -> Iterator[TestClient]:
    from kaizen.api.main import crear_app

    with TestClient(crear_app()) as c:
        yield c


def cabeceras_de(cliente: TestClient, correo: str) -> dict[str, str]:
    r = cliente.post("/api/v1/auth/login", json={"email": correo, "contrasena": DEMO})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token_acceso']}"}


@pytest.fixture(scope="module")
def demo(cliente: TestClient) -> dict[str, str]:
    return cabeceras_de(cliente, "demo@kaizen.test")


@pytest.fixture(scope="module")
def admin(cliente: TestClient) -> dict[str, str]:
    return cabeceras_de(cliente, "admin@kaizen.test")


def test_cien_recomendados_veinte_por_categoria(cliente: TestClient, demo: dict[str, str]) -> None:
    r = cliente.get(f"{URL}/recomendados", headers=demo)
    assert r.status_code == 200
    recs = r.json()
    assert len(recs) == 100
    por_categoria: dict[str, int] = {}
    for rec in recs:
        por_categoria[rec["categoria"]["clave"]] = (
            por_categoria.get(rec["categoria"]["clave"], 0) + 1
        )
    assert set(por_categoria.values()) == {20}
    caminar = next(x for x in recs if x["clave"] == "caminar_rapido")
    assert caminar["id"] == CAMINAR_RAPIDO
    assert caminar["zona"] == "optimo"


def test_crear_desde_recomendacion(cliente: TestClient, demo: dict[str, str]) -> None:
    cuerpo = {"recomendacion_id": CAMINAR_RAPIDO, "prioridad": 3, "nombre": "se ignora"}
    r = cliente.post(URL, json=cuerpo, headers=demo)
    assert r.status_code == 201, r.text
    h = r.json()
    try:
        assert h["recomendacion_id"] == CAMINAR_RAPIDO
        assert h["nombre"] == "Caminar a paso rápido"  # lo copió el trigger
        assert h["intencion"]  # el momento sugerido se vuelve la intención
        assert h["prioridad"] == 3
        assert h["subcategoria"]["clave"] == "aerobico_moderado"
    finally:
        cliente.patch(f"{URL}/{h['id']}", json={"activo": False}, headers=demo)


def test_recomendacion_que_no_existe_da_kz018(cliente: TestClient, demo: dict[str, str]) -> None:
    r = cliente.post(URL, json={"recomendacion_id": str(uuid.uuid4())}, headers=demo)
    assert r.status_code == 422
    assert r.json()["type"].endswith("/recomendacion-no-disponible")


def test_protegidos_del_demo(cliente: TestClient, demo: dict[str, str]) -> None:
    hasta = date.today()
    desde = hasta - timedelta(days=90)
    habitos: list[dict[str, Any]] = cliente.get(URL, headers=demo).json()
    total = 0
    for h in habitos:
        r = cliente.get(
            f"{URL}/{h['id']}/protegidos",
            params={"desde": str(desde), "hasta": str(hasta)},
            headers=demo,
        )
        assert r.status_code == 200, r.text
        fechas = [date.fromisoformat(f) for f in r.json()["fechas"]]
        assert fechas == sorted(fechas)
        assert all(desde <= f <= hasta for f in fechas)
        semanas = [f.isocalendar()[:2] for f in fechas]
        assert len(semanas) == len(set(semanas))  # el protector se usa máximo una vez por semana
        total += len(fechas)
    assert total > 0  # los datos del demo tienen fallas perdonadas


def test_protegidos_de_otro_usuario_da_404(
    cliente: TestClient, demo: dict[str, str], admin: dict[str, str]
) -> None:
    ajeno = cliente.get(URL, headers=demo).json()[0]["id"]
    r = cliente.get(
        f"{URL}/{ajeno}/protegidos",
        params={"desde": "2026-11-01", "hasta": "2026-11-28"},
        headers=admin,
    )
    assert r.status_code == 404


def test_fuentes(cliente: TestClient, demo: dict[str, str]) -> None:
    fuentes = cliente.get("/api/v1/fuentes", headers=demo).json()
    assert len(fuentes) == 53
    assert fuentes[0]["clave"] == "F01"
    assert [f["clave"] for f in fuentes] == sorted(f["clave"] for f in fuentes)


def test_admin_recomendaciones(
    cliente: TestClient, demo: dict[str, str], admin: dict[str, str]
) -> None:
    assert cliente.get("/api/v1/admin/recomendaciones", headers=demo).status_code == 403
    todas = cliente.get("/api/v1/admin/recomendaciones", headers=admin).json()
    assert len(todas) >= 100
    caminar = next(x for x in todas if x["clave"] == "caminar_rapido")
    cuerpo = {
        "subcategoria_id": caminar["subcategoria"]["id"],
        "nombre": "Prueba de integración",
        "unidad": "min",
        "meta": 25,
        "frecuencia": {"tipo": "n_por_semana", "veces_semana": 3},
        "momento": "Al salir del trabajo",
        "porque": "Solo para la prueba de integración de la API.",
        "fuentes": "F11",
        "activo": False,  # inactiva: no aparece en /habitos/recomendados
        "orden": 99,
    }
    r = cliente.put("/api/v1/admin/recomendaciones/prueba_api", json=cuerpo, headers=admin)
    assert r.status_code == 200, r.text
    assert (r.json()["nombre"], r.json()["activo"]) == ("Prueba de integración", False)
    claves = {x["clave"] for x in cliente.get(f"{URL}/recomendados", headers=demo).json()}
    assert "prueba_api" not in claves
    r = cliente.put(
        "/api/v1/admin/recomendaciones/prueba_api",
        json=cuerpo | {"fuentes": "F99"},  # fuente que no existe
        headers=admin,
    )
    assert r.status_code == 422
