"""Login contra el PostgreSQL local de Jael con las cuentas demo del poblador.

Se salta si no hay base: corre solo con KAIZEN_PRUEBAS_INTEGRACION=1 y el .env de desarrollo.
    PowerShell:  $env:KAIZEN_PRUEBAS_INTEGRACION=1; pytest tests/integracion
"""

import os

import pytest
from fastapi.testclient import TestClient

pytestmark = pytest.mark.skipif(
    os.environ.get("KAIZEN_PRUEBAS_INTEGRACION") != "1",
    reason="sin base de datos local (KAIZEN_PRUEBAS_INTEGRACION=1 para correrla)",
)

URL = "/api/v1/auth/login"
DEMO = os.environ.get("KAIZEN_DEMO_PASSWORD", "KaizenDemo2026!")


@pytest.fixture(scope="module")
def cliente() -> TestClient:
    from kaizen.api.main import crear_app

    with TestClient(crear_app()) as c:
        yield c  # type: ignore[misc]


def test_salud_con_la_base_real(cliente: TestClient) -> None:
    assert cliente.get("/api/v1/salud").json() == {"estado": "ok", "base_de_datos": "ok"}


def test_login_demo(cliente: TestClient) -> None:
    r = cliente.post(URL, json={"email": "demo@kaizen.test", "contrasena": DEMO})
    assert r.status_code == 200, r.text
    assert r.json()["usuario"]["region"] == "MX-NORTE"


def test_login_admin_trae_rol_admin(cliente: TestClient) -> None:
    r = cliente.post(URL, json={"email": "admin@kaizen.test", "contrasena": DEMO})
    assert r.json()["usuario"]["rol"] == "admin"


def test_login_latam(cliente: TestClient) -> None:
    r = cliente.post(URL, json={"email": "latam@kaizen.test", "contrasena": DEMO})
    assert r.json()["usuario"]["region"] == "LATAM"


def test_suspendido_da_403(cliente: TestClient) -> None:
    r = cliente.post(URL, json={"email": "suspendido@kaizen.test", "contrasena": DEMO})
    assert r.status_code == 403


def test_contrasena_mala_da_401(cliente: TestClient) -> None:
    r = cliente.post(URL, json={"email": "nuevo@kaizen.test", "contrasena": "no-es-esta"})
    assert r.status_code == 401
