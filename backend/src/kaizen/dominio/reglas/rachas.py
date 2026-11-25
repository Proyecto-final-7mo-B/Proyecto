"""Cálculo de rachas: días seguidos cumpliendo un hábito.

Es la misma regla que fn_rachas en PostgreSQL:
- Se recorren los días desde el primer registro hasta el último.
- Un día programado cumplido suma 1; uno programado sin cumplir (o sin registro) la rompe.
- Un día no programado no suma ni rompe.
- En NPorSemana solo cuentan los días con registro.
"""

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import date, timedelta

from kaizen.dominio.reglas.frecuencia import Frecuencia


@dataclass(frozen=True, slots=True)
class Racha:
    """Resultado del cálculo (inmutable)."""

    actual: int
    maxima: int
    ultima_fecha: date | None  # último día cumplido


class CalculadoraRacha:
    """Calcula la racha de un hábito a partir de su historial."""

    def calcular(self, frecuencia: Frecuencia, historial: Mapping[date, bool]) -> Racha:
        """historial: {fecha: cumplido}. Los días sin registro simplemente no están."""
        if not historial:
            return Racha(actual=0, maxima=0, ultima_fecha=None)

        actual = maxima = 0
        ultima: date | None = None
        dia, fin = min(historial), max(historial)
        while dia <= fin:
            registro = historial.get(dia)  # True, False o None (sin registro)
            if frecuencia.es_programado(dia):
                cuenta, cumplido = True, bool(registro)
            elif not frecuencia.rompe_si_falta() and registro is not None:
                cuenta, cumplido = True, registro
            else:
                cuenta, cumplido = False, False

            if cuenta:
                if cumplido:
                    actual += 1
                    maxima = max(maxima, actual)
                    ultima = dia
                else:
                    actual = 0
            dia += timedelta(days=1)

        return Racha(actual=actual, maxima=maxima, ultima_fecha=ultima)
