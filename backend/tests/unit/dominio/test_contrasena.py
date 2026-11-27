"""Pruebas de la política de contraseña."""

import pytest

from kaizen.dominio.excepciones import ValidacionError
from kaizen.dominio.reglas.contrasena import PoliticaContrasena

politica = PoliticaContrasena()
CORREO = "dani@correo.com"


@pytest.mark.parametrize("contrasena", ["a" * 12, "b" * 128, "mi perro se llama toby"])
def test_acepta_longitudes_validas(contrasena: str) -> None:
    politica.validar(contrasena, CORREO)  # no lanza error


@pytest.mark.parametrize("contrasena", ["", "a" * 11, "b" * 129])
def test_rechaza_longitudes_invalidas(contrasena: str) -> None:
    with pytest.raises(ValidacionError, match="entre 12 y 128"):
        politica.validar(contrasena, CORREO)


def test_rechaza_igual_al_correo_sin_importar_mayusculas() -> None:
    with pytest.raises(ValidacionError, match="correo"):
        politica.validar("DANI@correo.com", CORREO)


def test_rechaza_contrasenas_comunes() -> None:
    with pytest.raises(ValidacionError, match="común"):
        politica.validar("Password1234", CORREO)


def test_lista_de_comunes_personalizada() -> None:
    propia = PoliticaContrasena(comunes=frozenset({"kaizen2026!!"}))
    with pytest.raises(ValidacionError):
        propia.validar("KAIZEN2026!!", CORREO)
