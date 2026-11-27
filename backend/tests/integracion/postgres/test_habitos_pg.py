"""Hábitos y catálogo contra el PostgreSQL local de Jael (esquema y catálogo del 27-nov).

Se salta sin base: corre con KAIZEN_PRUEBAS_INTEGRACION=1 y el .env de desarrollo.
Los hábitos que crea se archivan al final (no hay DELETE de hábitos: el historial se conserva).
"""

import os
from collections.abc import Iterator
from typing import Any

import pytest
from fastapi.testclient import TestClient

pytestmark = pytest.mark.skipif(
    os.environ.get("KAIZEN_PRUEBAS_INTEGRACION") != "1",
    reason="sin base de datos local (KAIZEN_PRUEBAS_INTEGRACION=1 para correrla)",
)

DEMO = os.environ.get("KAIZEN_DEMO_PASSWORD", "KaizenDemo2026!")
URL = "/api/v1/habitos"


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
def subcategorias(cliente: TestClient, demo: dict[str, str]) -> dict[str, dict[str, Any]]:
    arbol = cliente.get("/api/v1/categorias", headers=demo).json()
    return {s["clave"]: s for c in arbol for s in c["subcategorias"]}


@pytest.fixture
def nuevo(
    cliente: TestClient, demo: dict[str, str], subcategorias: dict[str, dict[str, Any]]
) -> Iterator[dict[str, Any]]:
    cuerpo = {
        "nombre": "Prueba integración",
        "subcategoria_id": subcategorias["aerobico_moderado"]["id"],
        "frecuencia": {"tipo": "dias_semana", "dias_semana": 21},
        "meta": 40,
        "unidad": "min",
        "prioridad": 3,
        "intencion": "Al salir del trabajo",
    }
    r = cliente.post(URL, json=cuerpo, headers=demo)
    assert r.status_code == 201, r.text
    yield r.json()
    cliente.patch(f"{URL}/{r.json()['id']}", json={"activo": False}, headers=demo)


def test_catalogo_cientifico(cliente: TestClient, demo: dict[str, str]) -> None:
    arbol = cliente.get("/api/v1/categorias", headers=demo).json()
    claves = [c["clave"] for c in arbol]
    assert claves == ["ejercicio", "salud", "educacion", "bienestar", "finanzas"]
    subs = {s["clave"]: s for c in arbol for s in c["subcategorias"]}
    assert len(subs) == 22
    ref = subs["aerobico_moderado"]["referencia"]
    assert (ref["optimo_desde"], ref["optimo_hasta"], ref["maximo"]) == (150, 300, 600)


def test_demo_tiene_un_habito_de_cada_zona(cliente: TestClient, demo: dict[str, str]) -> None:
    habitos = {h["nombre"]: h for h in cliente.get(URL, headers=demo).json()}
    assert habitos["Caminar"]["evaluacion"]["zona"] == "optimo"
    assert habitos["Leer"]["evaluacion"]["zona"] == "bajo"
    excesivo = habitos["Repasar apuntes"]["evaluacion"]
    assert (excesivo["zona"], excesivo["meta_sugerida"]) == ("excesivo", 240)
    prioridades = [h["prioridad"] for h in cliente.get(URL, headers=demo).json()]
    assert prioridades == sorted(prioridades)


def test_evaluar_meta_excesiva(
    cliente: TestClient, demo: dict[str, str], subcategorias: dict[str, dict[str, Any]]
) -> None:
    cuerpo = {
        "subcategoria_id": subcategorias["aerobico_moderado"]["id"],
        "unidad": "min",
        "meta": 200,
        "frecuencia": {"tipo": "diaria"},
    }
    r = cliente.post(f"{URL}/evaluar", json=cuerpo, headers=demo)
    assert r.status_code == 200
    assert r.json()["zona"] == "excesivo"
    r = cliente.post(f"{URL}/evaluar", json=cuerpo | {"unidad": "vasos"}, headers=demo)
    assert r.json()["type"].endswith("/unidad-no-permitida")


def test_crear_lo_pone_la_base(nuevo: dict[str, Any]) -> None:
    assert nuevo["categoria"]["clave"] == "ejercicio"  # la fija el trigger
    assert (nuevo["nivel"], nuevo["prioridad"]) == (1, 3)
    assert nuevo["evaluacion"]["zona"] is not None
    assert nuevo["fecha_creacion"].endswith("Z")


def test_errores_de_la_base(
    cliente: TestClient, demo: dict[str, str], subcategorias: dict[str, dict[str, Any]]
) -> None:
    base = {
        "nombre": "x",
        "subcategoria_id": subcategorias["aerobico_moderado"]["id"],
        "frecuencia": {"tipo": "diaria"},
        "meta": 30,
        "unidad": "min",
    }
    r = cliente.post(URL, json=base | {"unidad": "vasos"}, headers=demo)
    assert (r.status_code, r.json()["type"][-19:]) == (422, "unidad-no-permitida")
    r = cliente.post(URL, json=base | {"meta": 5000}, headers=demo)  # fuera de 1–1440 (KZ011)
    assert r.json()["type"].endswith("/validacion")


def test_patch_cambia_subcategoria_y_categoria(
    cliente: TestClient,
    demo: dict[str, str],
    nuevo: dict[str, Any],
    subcategorias: dict[str, dict[str, Any]],
) -> None:
    cambio = {"subcategoria_id": subcategorias["lectura"]["id"], "unidad": "páginas"}
    r = cliente.patch(f"{URL}/{nuevo['id']}", json=cambio, headers=demo)
    assert r.status_code == 200, r.text
    assert (r.json()["subcategoria"]["clave"], r.json()["categoria"]["clave"]) == (
        "lectura",
        "educacion",
    )


def test_rls_otro_usuario_no_ve_ni_cambia(cliente: TestClient, nuevo: dict[str, Any]) -> None:
    otro = cabeceras_de(cliente, "latam@kaizen.test")
    assert cliente.get(f"{URL}/{nuevo['id']}", headers=otro).status_code == 404
    r = cliente.patch(f"{URL}/{nuevo['id']}", json={"nombre": "mío"}, headers=otro)
    assert r.status_code == 404
