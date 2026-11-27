"""Pruebas del hasher de contraseñas (Argon2id)."""

from argon2 import PasswordHasher

from kaizen.infraestructura.seguridad.contrasenas import HasherContrasenas

hasher = HasherContrasenas()
CLAVE = "mi perro se llama toby"


def test_el_hash_es_argon2id_y_no_contiene_la_contrasena() -> None:
    h = hasher.hashear(CLAVE)
    assert h.startswith("$argon2id$")
    assert CLAVE not in h


def test_misma_contrasena_da_hashes_distintos_por_la_sal() -> None:
    assert hasher.hashear(CLAVE) != hasher.hashear(CLAVE)


def test_verifica_la_correcta_y_rechaza_la_incorrecta() -> None:
    h = hasher.hashear(CLAVE)
    assert hasher.verificar(h, CLAVE)
    assert not hasher.verificar(h, "otra contraseña")


def test_hash_danado_regresa_false_sin_lanzar_error() -> None:
    assert not hasher.verificar("esto no es un hash", CLAVE)


def test_compatible_con_hashes_del_poblador() -> None:
    # poblar.py usa PasswordHasher() por defecto: sus hashes deben verificarse aquí
    h = PasswordHasher().hash(CLAVE)
    assert hasher.verificar(h, CLAVE)
    assert not hasher.necesita_rehash(h)


def test_detecta_hashes_con_parametros_viejos() -> None:
    viejo = PasswordHasher(time_cost=1, memory_cost=8192).hash(CLAVE)
    assert hasher.necesita_rehash(viejo)
