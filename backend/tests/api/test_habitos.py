"""Pruebas de /categorias y /habitos con el repositorio falso (sin base de datos)."""

import uuid
from datetime import timedelta
from typing import Any

from fastapi.testclient import TestClient

from conftest import SUBCATEGORIA, Reloj, RepoHabitosFalso
from kaizen.infraestructura.seguridad.tokens import EmisorTokens

URL = "/api/v1/habitos"
NUEVO: dict[str, Any] = {
    "nombre": "Caminar",
    "subcategoria_id": str(SUBCATEGORIA["id"]),
    "frecuencia": {"tipo": "diaria"},
    "meta": 30,
    "unidad": "min",
}


def crear(cliente: TestClient, cabeceras: dict[str, str], **cambios: Any) -> dict[str, Any]:
    r = cliente.post(URL, json=NUEVO | cambios, headers=cabeceras)
    assert r.status_code == 201, r.text
    datos: dict[str, Any] = r.json()
    return datos


# ---------------------------------------------------------------- token


def test_sin_token_da_401(cliente: TestClient) -> None:
    r = cliente.get(URL)
    assert r.status_code == 401
    assert r.json()["type"].endswith("/token-invalido")


def test_token_alterado_da_401(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    r = cliente.get(URL, headers={"Authorization": cabeceras["Authorization"] + "x"})
    assert r.status_code == 401


def test_token_de_renovacion_no_sirve_como_acceso(
    cliente: TestClient, emisor: EmisorTokens
) -> None:
    par = emisor.emitir_par(uuid.uuid4(), "MX-NORTE", "usuario")
    r = cliente.get(URL, headers={"Authorization": f"Bearer {par.renovacion}"})
    assert r.status_code == 401


# ---------------------------------------------------------------- categorías


def test_categorias_trae_el_arbol_y_cache(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    r = cliente.get("/api/v1/categorias", headers=cabeceras)
    assert r.status_code == 200
    assert r.headers["cache-control"] == "max-age=3600"
    sub = r.json()[0]["subcategorias"][0]
    assert sub["clave"] == "aerobico_moderado"
    assert sub["unidades"][0]["unidad"] == "min"
    assert sub["referencia"] is None


# ---------------------------------------------------------------- crear y listar


def test_crear_responde_201_con_el_habito(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = crear(cliente, cabeceras, prioridad=1, intencion="Después de comer")
    assert (h["nombre"], h["meta"], h["prioridad"]) == ("Caminar", 30, 1)
    assert h["categoria"]["clave"] == "ejercicio"
    assert h["racha"]["protegida_esta_semana"] is False


def test_crear_rechaza_campos_de_mas(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    for extra in ({"categoria_id": str(uuid.uuid4())}, {"usuario_id": str(uuid.uuid4())}):
        r = cliente.post(URL, json=NUEVO | extra, headers=cabeceras)
        assert r.status_code == 422, extra
        assert r.json()["type"].endswith("/validacion")


def test_crear_valida_los_limites(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    malos = [
        {"meta": 0},
        {"meta": 1.234},
        {"nombre": ""},
        {"nombre": "x" * 61},
        {"prioridad": 4},
        {"intencion": "x" * 121},
        {"frecuencia": {"tipo": "semanal"}},
        {"frecuencia": {"tipo": "dias_semana"}},  # falta la máscara
        {"frecuencia": {"tipo": "dias_semana", "dias_semana": 128}},
        {"frecuencia": {"tipo": "diaria", "veces_semana": 3}},  # no va con diaria
        {"frecuencia": {"tipo": "n_por_semana", "veces_semana": 8}},
    ]
    for cambio in malos:
        assert cliente.post(URL, json=NUEVO | cambio, headers=cabeceras).status_code == 422, cambio


def test_listar_ordena_por_prioridad_y_nombre(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    crear(cliente, cabeceras, nombre="Zumba", prioridad=1)
    crear(cliente, cabeceras, nombre="Agua", prioridad=2)
    crear(cliente, cabeceras, nombre="Bici", prioridad=1)
    nombres = [h["nombre"] for h in cliente.get(URL, headers=cabeceras).json()]
    assert nombres == ["Bici", "Zumba", "Agua"]


def test_fecha_fuera_de_rango(cliente: TestClient, cabeceras: dict[str, str], reloj: Reloj) -> None:
    hoy = reloj.ahora.date()
    lejos = (hoy - timedelta(days=5)).isoformat()
    r = cliente.get(URL, params={"fecha": lejos}, headers=cabeceras)
    assert r.status_code == 422
    assert r.json()["type"].endswith("/fecha-fuera-de-rango")


def test_zona_horaria_invalida(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    r = cliente.get(URL, headers=cabeceras | {"X-Zona-Horaria": "Marte/Base"})
    assert r.status_code == 422
    assert r.json()["errores"][0]["campo"] == "X-Zona-Horaria"


# ---------------------------------------------------------------- otro usuario (IDOR)


def test_habito_de_otro_usuario_da_404(
    cliente: TestClient, cabeceras: dict[str, str], emisor: EmisorTokens
) -> None:
    h = crear(cliente, cabeceras)
    otro = emisor.emitir_par(uuid.uuid4(), "MX-NORTE", "usuario").acceso
    ajenas = {"Authorization": f"Bearer {otro}"}
    assert cliente.get(f"{URL}/{h['id']}", headers=ajenas).status_code == 404
    r = cliente.patch(f"{URL}/{h['id']}", json={"nombre": "mío"}, headers=ajenas)
    assert r.status_code == 404
    assert r.json()["type"].endswith("/no-encontrado")
    assert cliente.get(URL, headers=ajenas).json() == []


def test_id_que_no_existe_da_404(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    assert cliente.get(f"{URL}/{uuid.uuid4()}", headers=cabeceras).status_code == 404


# ---------------------------------------------------------------- PATCH


def test_patch_cambia_prioridad_y_archiva(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = crear(cliente, cabeceras)
    r = cliente.patch(f"{URL}/{h['id']}", json={"prioridad": 3, "activo": False}, headers=cabeceras)
    assert r.status_code == 200
    assert (r.json()["prioridad"], r.json()["activo"]) == (3, False)
    assert cliente.get(URL, headers=cabeceras).json() == []
    assert len(cliente.get(URL, params={"archivados": True}, headers=cabeceras).json()) == 1


def test_patch_no_acepta_meta_frecuencia_ni_categoria(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    h = crear(cliente, cabeceras)
    for cambio in (
        {"meta": 10},
        {"frecuencia": {"tipo": "diaria"}},
        {"categoria_id": str(uuid.uuid4())},
    ):
        r = cliente.patch(f"{URL}/{h['id']}", json=cambio, headers=cabeceras)
        assert r.status_code == 422, cambio


def test_patch_subcategoria_exige_unidad(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = crear(cliente, cabeceras)
    r = cliente.patch(
        f"{URL}/{h['id']}", json={"subcategoria_id": str(uuid.uuid4())}, headers=cabeceras
    )
    assert r.status_code == 422
    assert r.json()["errores"][0]["campo"] == "unidad"


def test_patch_no_acepta_null_salvo_intencion(
    cliente: TestClient, cabeceras: dict[str, str]
) -> None:
    h = crear(cliente, cabeceras, intencion="Al despertar")
    url = f"{URL}/{h['id']}"
    assert cliente.patch(url, json={"nombre": None}, headers=cabeceras).status_code == 422
    r = cliente.patch(url, json={"intencion": None}, headers=cabeceras)
    assert r.status_code == 200
    assert r.json()["intencion"] is None


def test_patch_vacio_regresa_el_habito(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    h = crear(cliente, cabeceras)
    r = cliente.patch(f"{URL}/{h['id']}", json={}, headers=cabeceras)
    assert r.status_code == 200
    assert r.json()["id"] == h["id"]


# ---------------------------------------------------------------- evaluar


def test_evaluar_no_guarda_nada(
    cliente: TestClient, cabeceras: dict[str, str], repo_habitos: RepoHabitosFalso
) -> None:
    cuerpo = {k: NUEVO[k] for k in ("subcategoria_id", "unidad", "meta", "frecuencia")}
    r = cliente.post(f"{URL}/evaluar", json=cuerpo, headers=cabeceras)
    assert r.status_code == 200
    assert r.json()["zona"] == "optimo"
    assert repo_habitos.habitos == {}
    assert repo_habitos.consultas[0].meta == 30


def test_evaluar_rechaza_nombre(cliente: TestClient, cabeceras: dict[str, str]) -> None:
    cuerpo = {k: NUEVO[k] for k in ("subcategoria_id", "unidad", "meta", "frecuencia")}
    r = cliente.post(f"{URL}/evaluar", json=cuerpo | {"nombre": "x"}, headers=cabeceras)
    assert r.status_code == 422
