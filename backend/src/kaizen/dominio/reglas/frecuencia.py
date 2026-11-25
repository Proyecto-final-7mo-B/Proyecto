"""Frecuencias de un hábito: qué días exige cumplirlo.

Cada tipo de frecuencia es una clase. La calculadora de rachas recibe cualquiera de ellas
sin saber cuál es (polimorfismo), así que no hay un "if por tipo" repartido en el código.
"""

from abc import ABC, abstractmethod
from datetime import date

from kaizen.dominio.excepciones import ValidacionError


class Frecuencia(ABC):
    """Cuándo exige un hábito su cumplimiento."""

    @abstractmethod
    def es_programado(self, dia: date) -> bool:
        """¿El hábito tocaba ese día?"""

    def rompe_si_falta(self) -> bool:
        """Un día programado sin registro rompe la racha (NPorSemana lo cambia)."""
        return True


class Diaria(Frecuencia):
    """Todos los días."""

    def es_programado(self, dia: date) -> bool:
        return True


class DiasSemana(Frecuencia):
    """Días fijos de la semana, guardados como máscara de 7 bits (lunes = bit 0).

    Ejemplo: lunes, miércoles y viernes = 1 + 4 + 16 = 21. Es la misma convención que
    fn_dia_programado en PostgreSQL, para que Python y SQL calculen igual.
    """

    def __init__(self, mascara: int) -> None:
        if not 1 <= mascara <= 127:
            raise ValidacionError("La máscara de días debe estar entre 1 y 127")
        self._mascara = mascara  # encapsulado: no se cambia después de crear

    @property
    def mascara(self) -> int:
        return self._mascara

    def es_programado(self, dia: date) -> bool:
        return bool(self._mascara & (1 << dia.weekday()))  # weekday(): lunes = 0


class NPorSemana(Frecuencia):
    """N veces por semana, sin días fijos: solo cuentan los días con registro."""

    def __init__(self, veces: int) -> None:
        if not 1 <= veces <= 7:
            raise ValidacionError("Las veces por semana deben estar entre 1 y 7")
        self._veces = veces

    @property
    def veces(self) -> int:
        return self._veces

    def es_programado(self, dia: date) -> bool:
        return False

    def rompe_si_falta(self) -> bool:
        return False
