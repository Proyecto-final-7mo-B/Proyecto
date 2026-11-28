"""Check-ins (POST /registros, /registros/lote) e historial, con los repositorios falsos."""

import uuid
from datetime import date, timedelta
from typing import Any

from fastapi.testclient import TestClient

from conftest import SUBCATEGORIA

HOY = date.today()
HABITO: dict[str, Any] = {
    "nombre": "Caminar",
    "subcategoria_id": str(SUBCATEGORIA["id"]),
    "frecuencia": {"tipo": "diaria"},
    "meta": 30,
    "unidad": "min",
}


def nuevo_habito(cliente: TestClient, cabeceras: dict[str, str]) -> str:
    r = cliente.post("/api/v1/habitos", json=HABITO, headers=cabeceras)
    assert r.status_code == 201, r.text
    habito_id: str = r.json()["id"]
    return habito_id


def checkin(habito_id: str, dia: date = HOY, **cambios: Any) -> dict[str, Any]:
    cuerpo = {
        "id": str(uuid.uuid4()),
        "habito_id": habito_id,
        "fecha": str(dia),
        "cumplido": True,
        "valor": 20,
    }
    return cuerpo | cambios


# ---------------------------------------------------------------- POST /registros


def test_registrar_regresa_id_y_racha(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = nuevo_habito(cliente, cabeceras)
    cuerpo = checkin(h)
    r = cliente.post("/api/v1/registros", json=cuerpo, headers=cabeceras)
    assert r.status_code == 200, r.text
    assert r.json() == {"id": cuerpo["id"], "racha_actual": 1}


def test_reenviar_no_duplica_y_gana_el_ultimo(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    h = nuevo_habito(cliente, cabeceras)
    cuerpo = checkin(h)
    cliente.post("/api/v1/registros", json=cuerpo, headers=cabeceras)
    r = cliente.post("/api/v1/registros", json=cuerpo | {"valor": 35}, headers=cabeceras)
    assert r.json()["racha_actual"] == 1  # sigue siendo un solo día
    [guardado] = cliente.get(
        f"/api/v1/habitos/{h}/registros",
        params={"desde": str(HOY), "hasta": str(HOY)},
        headers=cabeceras,
    ).json()
    assert guardado["valor"] == 35


def test_dias_atrasados_si_se_aceptan(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = nuevo_habito(cliente, cabeceras)  # (la base además exige que sea después de crearlo)
    r = cliente.post(
        "/api/v1/registros", json=checkin(h, HOY - timedelta(days=5)), headers=cabeceras
    )
    assert r.status_code == 200


def test_errores_de_registrar(
    cliente: TestClient, cabeceras: dict[str, str], cabeceras_admin: dict[str, str]
) -> None:
    h = nuevo_habito(cliente, cabeceras)
    r = cliente.post("/api/v1/registros", json=checkin(h), headers=cabeceras_admin)
    assert r.status_code == 404  # el hábito es de otro usuario
    r = cliente.post(
        "/api/v1/registros", json=checkin(h, HOY + timedelta(days=3)), headers=cabeceras
    )
    assert r.json()["type"].endswith("/fecha-fuera-de-rango")
    cliente.patch(f"/api/v1/habitos/{h}", json={"activo": False}, headers=cabeceras)
    r = cliente.post("/api/v1/registros", json=checkin(h), headers=cabeceras)
    assert (r.status_code, r.json()["type"].split("/")[-1]) == (409, "habito-archivado")


def test_validaciones_de_forma(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = nuevo_habito(cliente, cabeceras)
    malos = [
        checkin(h, valor=-1),
        checkin(h, valor=1.234),
        checkin(h, origen="robot"),
        checkin(h, usuario_id=str(uuid.uuid4())),  # el usuario sale del token, nunca del cuerpo
        {k: v for k, v in checkin(h).items() if k != "id"},  # el id lo manda la app
    ]
    for cuerpo in malos:
        r = cliente.post("/api/v1/registros", json=cuerpo, headers=cabeceras)
        assert r.status_code == 422, cuerpo


def test_sin_token_da_401(cliente: TestClient) -> None:
    assert cliente.post("/api/v1/registros", json={}).status_code == 401


# ---------------------------------------------------------------- POST /registros/lote


def test_lote_acepta_y_rechaza_por_separado(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = nuevo_habito(cliente, cabeceras)
    bueno = checkin(h, HOY - timedelta(days=1), origen="offline")
    ajeno = checkin(str(uuid.uuid4()), origen="offline")
    futuro = checkin(h, HOY + timedelta(days=9), origen="offline")
    r = cliente.post(
        "/api/v1/registros/lote", json={"registros": [bueno, ajeno, futuro]}, headers=cabeceras
    )
    assert r.status_code == 200
    a, b, c = r.json()["resultados"]
    assert (a["id"], a["estado"], a["racha_actual"]) == (bueno["id"], "aceptado", 1)
    assert (b["estado"], b["error"]["status"]) == ("rechazado", 404)
    assert b["error"]["type"].endswith("/no-encontrado")
    assert c["error"]["type"].endswith("/fecha-fuera-de-rango")


def test_lote_valida_el_tamano(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = nuevo_habito(cliente, cabeceras)
    vacio = cliente.post("/api/v1/registros/lote", json={"registros": []}, headers=cabeceras)
    assert vacio.status_code == 422
    muchos = {"registros": [checkin(h) for _ in range(101)]}
    assert cliente.post("/api/v1/registros/lote", json=muchos, headers=cabeceras).status_code == 422


def test_lote_con_un_elemento_mal_formado_da_422(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    h = nuevo_habito(cliente, cabeceras)
    lote = {"registros": [checkin(h), checkin(h, cumplido="tal vez")]}
    assert cliente.post("/api/v1/registros/lote", json=lote, headers=cabeceras).status_code == 422


# ---------------------------------------------------------------- historial


def test_historial_en_orden_y_dentro_del_rango(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    h = nuevo_habito(cliente, cabeceras)
    for atras in (1, 9, 4):
        dia = HOY - timedelta(days=atras)
        cliente.post("/api/v1/registros", json=checkin(h, dia), headers=cabeceras)
    r = cliente.get(
        f"/api/v1/habitos/{h}/registros",
        params={"desde": str(HOY - timedelta(days=5)), "hasta": str(HOY)},
        headers=cabeceras,
    )
    assert r.status_code == 200
    fechas = [x["fecha"] for x in r.json()]
    assert fechas == [str(HOY - timedelta(days=4)), str(HOY - timedelta(days=1))]
    assert r.json()[0]["origen"] == "manual"


def test_historial_de_otro_y_rango_invalido(
    cliente: TestClient, cabeceras: dict[str, str], cabeceras_admin: dict[str, str]
) -> None:
    h = nuevo_habito(cliente, cabeceras)
    url = f"/api/v1/habitos/{h}/registros"
    rango = {"desde": str(HOY - timedelta(days=7)), "hasta": str(HOY)}
    assert cliente.get(url, params=rango, headers=cabeceras_admin).status_code == 404
    largo = {"desde": str(HOY - timedelta(days=400)), "hasta": str(HOY)}
    r = cliente.get(url, params=largo, headers=cabeceras)
    assert (r.status_code, r.json()["errores"][0]["campo"]) == (422, "hasta")
