"""Pruebas HTTP de /salud y /auth/login con la app real y un repositorio falso."""

from fastapi.testclient import TestClient

from conftest import CLAVE, RepoFalso
from kaizen.api.main import construir_app

URL = "/api/v1/auth/login"


def test_salud_ok(cliente: TestClient) -> None:
    r = cliente.get("/api/v1/salud")
    assert r.status_code == 200
    assert r.json() == {"estado": "ok", "base_de_datos": "ok"}


def test_salud_sin_base_da_503(servicio, servicio_habitos, servicio_registros, emisor) -> None:  # type: ignore[no-untyped-def]
    r = TestClient(
        construir_app(
            servicio, servicio_habitos, servicio_registros, emisor, revisar_base=lambda: False
        )
    ).get("/api/v1/salud")
    assert r.status_code == 503


def test_login_200_con_la_forma_del_contrato(cliente: TestClient, repo: RepoFalso) -> None:
    cuenta = repo.agregar("demo@kaizen.test", nombre="Daniela")
    r = cliente.post(URL, json={"email": "demo@kaizen.test", "contrasena": CLAVE})
    assert r.status_code == 200
    assert r.headers["cache-control"] == "no-store"
    cuerpo = r.json()
    assert set(cuerpo) == {"token_acceso", "token_renovacion", "tipo", "expira_en", "usuario"}
    assert cuerpo["tipo"] == "Bearer" and cuerpo["expira_en"] == 900
    assert cuerpo["usuario"] == {
        "id": str(cuenta.id),
        "nombre": "Daniela",
        "rol": "usuario",
        "region": "MX-NORTE",
    }


def test_login_401_problem_json(cliente: TestClient) -> None:
    r = cliente.post(URL, json={"email": "nadie@kaizen.test", "contrasena": "x"})
    assert r.status_code == 401
    assert r.headers["content-type"] == "application/problem+json"
    assert r.json()["type"].endswith("/credenciales-invalidas")
    assert "id_peticion" in r.json()


def test_login_403_suspendida(cliente: TestClient, repo: RepoFalso) -> None:
    repo.agregar("suspendido@kaizen.test", suspendida=True)
    r = cliente.post(URL, json={"email": "suspendido@kaizen.test", "contrasena": CLAVE})
    assert r.status_code == 403
    assert r.json()["type"].endswith("/cuenta-suspendida")


def test_login_429_con_retry_after(cliente: TestClient, repo: RepoFalso) -> None:
    repo.agregar("demo@kaizen.test", intentos_fallidos=9)
    cliente.post(URL, json={"email": "demo@kaizen.test", "contrasena": "mala"})
    r = cliente.post(URL, json={"email": "demo@kaizen.test", "contrasena": CLAVE})
    assert r.status_code == 429
    assert int(r.headers["retry-after"]) > 0


def test_campos_de_mas_dan_422(cliente: TestClient) -> None:
    r = cliente.post(URL, json={"email": "a@b.co", "contrasena": "x", "region": "LATAM"})
    assert r.status_code == 422
    assert {"campo": "region", "detalle": "Extra inputs are not permitted"} in r.json()["errores"]


def test_inyeccion_sql_en_el_correo_no_pasa_la_validacion(cliente: TestClient) -> None:
    r = cliente.post(URL, json={"email": "' OR 1=1 --", "contrasena": "x"})
    assert r.status_code == 422


def test_zona_horaria_invalida_da_422(cliente: TestClient) -> None:
    r = cliente.post(
        URL,
        json={"email": "a@b.co", "contrasena": "x"},
        headers={"X-Zona-Horaria": "Marte/Base"},
    )
    assert r.status_code == 422
    assert r.json()["errores"][0]["campo"] == "X-Zona-Horaria"


def test_error_inesperado_da_500_sin_traza(
    servicio, servicio_habitos, servicio_registros, emisor
) -> None:  # type: ignore[no-untyped-def]
    def explota() -> bool:
        raise RuntimeError("detalle interno secreto")

    c = TestClient(
        construir_app(servicio, servicio_habitos, servicio_registros, emisor, revisar_base=explota),
        raise_server_exceptions=False,
    )
    r = c.get("/api/v1/salud")
    assert r.status_code == 500
    assert "secreto" not in r.text
