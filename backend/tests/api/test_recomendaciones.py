"""Lo nuevo en v1.7 (repositorio falso): recomendados, protegidos, fuentes y admin."""

import uuid
from datetime import date, timedelta
from typing import Any

from fastapi.testclient import TestClient

from conftest import RECOMENDACION, SUBCATEGORIA, RepoHabitosFalso

URL = "/api/v1/habitos"
ADMIN = "/api/v1/admin/recomendaciones"
CUERPO_ADMIN: dict[str, Any] = {
    "subcategoria_id": str(SUBCATEGORIA["id"]),
    "nombre": "Bici al trabajo",
    "unidad": "min",
    "meta": 20,
    "frecuencia": {"tipo": "n_por_semana", "veces_semana": 3},
    "momento": "Al salir de casa",
    "porque": "Suma minutos de actividad moderada sin apartar tiempo extra.",
    "fuentes": "F11, F14",
    "orden": 5,
}


def crear_recomendado(
    cliente: TestClient, cabeceras: dict[str, str], **extra: Any
) -> dict[str, Any]:
    cuerpo = {"recomendacion_id": str(RECOMENDACION["id"])} | extra
    r = cliente.post(URL, json=cuerpo, headers=cabeceras)
    assert r.status_code == 201, r.text
    datos: dict[str, Any] = r.json()
    return datos


# ---------------------------------------------------------------- recomendados


def test_recomendados_trae_la_lista(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    r = cliente.get(f"{URL}/recomendados", headers=cabeceras)
    assert r.status_code == 200
    [rec] = r.json()
    assert rec["clave"] == "caminar_rapido"
    assert rec["frecuencia"] == {"tipo": "dias_semana", "dias_semana": 31, "veces_semana": None}
    assert "activo" not in rec  # eso solo lo ve administración


def test_recomendados_esconde_las_inactivas(
    cliente: TestClient, cabeceras: dict[str, str], repo_habitos: RepoHabitosFalso
) -> None:
    repo_habitos.recomendaciones["caminar_rapido"]["activo"] = False
    assert cliente.get(f"{URL}/recomendados", headers=cabeceras).json() == []


def test_recomendados_pide_token(cliente: TestClient) -> None:
    assert cliente.get(f"{URL}/recomendados").status_code == 401


def test_crear_desde_recomendacion_copia_los_datos(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    h = crear_recomendado(cliente, cabeceras, prioridad=1)
    assert h["recomendacion_id"] == str(RECOMENDACION["id"])
    assert (h["nombre"], h["meta"], h["intencion"]) == (
        "Caminar a paso rápido",
        30,
        "Después de comer",
    )
    assert h["prioridad"] == 1


def test_con_recomendacion_los_demas_campos_se_ignoran(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    h = crear_recomendado(cliente, cabeceras, nombre="Otro", meta=999, campo_raro=True)
    assert (h["nombre"], h["meta"]) == ("Caminar a paso rápido", 30)


def test_recomendacion_inactiva_da_422(
    cliente: TestClient, cabeceras: dict[str, str], repo_habitos: RepoHabitosFalso
) -> None:
    repo_habitos.recomendaciones["caminar_rapido"]["activo"] = False
    r = cliente.post(URL, json={"recomendacion_id": str(RECOMENDACION["id"])}, headers=cabeceras)
    assert r.status_code == 422
    assert r.json()["type"].endswith("/recomendacion-no-disponible")


def test_personalizado_sigue_pidiendo_sus_campos(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    r = cliente.post(URL, json={"nombre": "Caminar", "prioridad": 1}, headers=cabeceras)
    assert r.status_code == 422
    assert "subcategoria_id" in r.json()["errores"][0]["detalle"]


def test_personalizado_tiene_recomendacion_id_null(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    cuerpo = {
        "nombre": "Caminar",
        "subcategoria_id": str(SUBCATEGORIA["id"]),
        "frecuencia": {"tipo": "diaria"},
        "meta": 30,
        "unidad": "min",
    }
    r = cliente.post(URL, json=cuerpo, headers=cabeceras)
    assert r.status_code == 201
    assert r.json()["recomendacion_id"] is None


def test_patch_no_cambia_recomendacion_id(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = crear_recomendado(cliente, cabeceras)
    r = cliente.patch(
        f"{URL}/{h['id']}", json={"recomendacion_id": str(uuid.uuid4())}, headers=cabeceras
    )
    assert r.status_code == 422


# ---------------------------------------------------------------- protegidos


def test_protegidos_filtra_el_rango(
    cliente: TestClient, cabeceras: dict[str, str], repo_habitos: RepoHabitosFalso
) -> None:
    h = crear_recomendado(cliente, cabeceras)
    repo_habitos.protegidos[uuid.UUID(h["id"])] = [date(2026, 11, 3), date(2026, 11, 18)]
    r = cliente.get(
        f"{URL}/{h['id']}/protegidos",
        params={"desde": "2026-11-10", "hasta": "2026-11-30"},
        headers=cabeceras,
    )
    assert r.status_code == 200
    assert r.json() == {"fechas": ["2026-11-18"]}


def test_protegidos_de_otro_usuario_da_404(
    cliente: TestClient, cabeceras: dict[str, str], cabeceras_admin: dict[str, str]
) -> None:
    h = crear_recomendado(cliente, cabeceras)
    r = cliente.get(
        f"{URL}/{h['id']}/protegidos",
        params={"desde": "2026-11-01", "hasta": "2026-11-30"},
        headers=cabeceras_admin,
    )
    assert r.status_code == 404


def test_protegidos_valida_el_rango(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = crear_recomendado(cliente, cabeceras)
    hoy = date(2026, 11, 28)
    casos = [
        ({"desde": "2026-11-20", "hasta": "2026-11-10"}, "desde"),  # al revés
        ({"desde": str(hoy - timedelta(days=367)), "hasta": str(hoy)}, "hasta"),  # más de 366
    ]
    for params, campo in casos:
        r = cliente.get(f"{URL}/{h['id']}/protegidos", params=params, headers=cabeceras)
        assert r.status_code == 422, params
        assert r.json()["errores"][0]["campo"] == campo
    r = cliente.get(
        f"{URL}/{h['id']}/protegidos", params={"desde": "2026-11-01"}, headers=cabeceras
    )
    assert r.status_code == 422  # falta hasta
    r = cliente.get(
        f"{URL}/{h['id']}/protegidos",
        params={"desde": str(hoy - timedelta(days=366)), "hasta": str(hoy)},
        headers=cabeceras,
    )
    assert r.status_code == 200  # 366 justos sí


# ---------------------------------------------------------------- fuentes


def test_fuentes(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    r = cliente.get("/api/v1/fuentes", headers=cabeceras)
    assert r.status_code == 200
    assert r.headers["cache-control"] == "max-age=3600"
    assert r.json()[0]["clave"] == "F01"
    assert cliente.get("/api/v1/fuentes").status_code == 401


# ---------------------------------------------------------------- administración


def test_usuario_normal_no_entra_a_admin(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    assert cliente.get(ADMIN, headers=cabeceras).status_code == 403
    r = cliente.put(f"{ADMIN}/bici", json=CUERPO_ADMIN, headers=cabeceras)
    assert r.status_code == 403
    assert r.json()["type"].endswith("/rol-insuficiente")


def test_admin_ve_tambien_las_inactivas(
    cliente: TestClient, cabeceras_admin: dict[str, str], repo_habitos: RepoHabitosFalso
) -> None:
    repo_habitos.recomendaciones["caminar_rapido"]["activo"] = False
    [rec] = cliente.get(ADMIN, headers=cabeceras_admin).json()
    assert (rec["activo"], rec["orden"]) == (False, 1)


def test_admin_da_de_alta_y_cambia(
    cliente: TestClient, cabeceras_admin: dict[str, str], repo_habitos: RepoHabitosFalso
) -> None:
    r = cliente.put(f"{ADMIN}/bici_trabajo", json=CUERPO_ADMIN, headers=cabeceras_admin)
    assert r.status_code == 200, r.text
    assert r.json()["frecuencia"]["veces_semana"] == 3
    primero = r.json()["id"]
    r = cliente.put(
        f"{ADMIN}/bici_trabajo", json=CUERPO_ADMIN | {"activo": False}, headers=cabeceras_admin
    )
    assert (r.json()["id"], r.json()["activo"]) == (primero, False)
    assert len(repo_habitos.guardadas) == 2


def test_admin_valida_clave_y_cuerpo(cliente: TestClient, cabeceras_admin: dict[str, str]) -> None:
    malos = [
        ("Con Mayus", CUERPO_ADMIN),
        ("bici", CUERPO_ADMIN | {"fuentes": "F1"}),
        ("bici", CUERPO_ADMIN | {"meta": 0}),
        ("bici", CUERPO_ADMIN | {"clave": "otra"}),  # la clave va en la ruta
        ("bici", CUERPO_ADMIN | {"frecuencia": {"tipo": "diaria", "veces_semana": 3}}),
    ]
    for clave, cuerpo in malos:
        r = cliente.put(f"{ADMIN}/{clave}", json=cuerpo, headers=cabeceras_admin)
        assert r.status_code == 422, (clave, cuerpo)
