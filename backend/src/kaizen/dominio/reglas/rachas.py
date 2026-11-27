"""Cálculo de rachas: días seguidos cumpliendo un hábito.

Es la misma regla que fn_rachas en PostgreSQL:
- Se recorren los días desde el primer registro hasta el último.
- Un día programado cumplido suma 1; uno programado sin cumplir (o sin registro) la rompe.
- Protector (contrato v1.6): el primer día fallado de cada semana ISO (lunes a domingo)
  no la rompe si la racha va en más de 0. Ese día no suma. El segundo fallo de la misma
  semana sí la rompe.
- Un día no programado no suma ni rompe.
- En NPorSemana solo cuentan los días con registro.
- Con `hasta`, se recorre hasta esa fecha: los días sin registro cuentan como fallados
  (así lo hace v_racha_vigente, hasta ayer).
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
    ultimo_protegido: date | None = None  # último día fallado que perdonó el protector


def lunes_de(dia: date) -> date:
    """Lunes de la semana ISO de ese día."""
    return dia - timedelta(days=dia.weekday())


class CalculadoraRacha:
    """Calcula la racha de un hábito a partir de su historial."""

    def calcular(
        self, frecuencia: Frecuencia, historial: Mapping[date, bool], hasta: date | None = None
    ) -> Racha:
        """historial: {fecha: cumplido}. Los días sin registro simplemente no están."""
        if not historial:
            return Racha(actual=0, maxima=0, ultima_fecha=None)

        actual = maxima = 0
        ultima: date | None = None
        protegido: date | None = None
        semana_protegida: date | None = None  # lunes de la semana en que ya se usó el protector
        dia, fin = min(historial), max(historial)
        if hasta is not None:
            fin = max(fin, hasta)
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
                elif actual > 0 and semana_protegida != lunes_de(dia):
                    semana_protegida = lunes_de(dia)
                    protegido = dia
                else:
                    actual = 0
            dia += timedelta(days=1)

        return Racha(actual=actual, maxima=maxima, ultima_fecha=ultima, ultimo_protegido=protegido)
