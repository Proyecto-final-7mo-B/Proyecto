"""Prueba de humo: confirma que el paquete se instala y se importa."""

import kaizen


def test_el_paquete_se_importa() -> None:
    assert kaizen.__version__ == "0.1.0"
