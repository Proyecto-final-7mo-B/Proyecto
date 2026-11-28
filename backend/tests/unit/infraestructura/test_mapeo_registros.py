"""Fila de PostgreSQL -> Registro del contrato, y el resumen de error del lote."""

import uuid
from datetime import UTC, date, datetime, timedelta, timezone
from decimal import Decimal

from kaizen.api.errores import resumen_de
from kaizen.dominio.excepciones import HabitoArchivado, KaizenError
from kaizen.infraestructura.postgres.repositorio_registros import registro


def test_registro_con_valor_e_instante_en_utc() -> None:
    fila = {
        "id": uuid.uuid4(),
        "habito_id": uuid.uuid4(),
        "fecha": date(2026, 11, 23),
        "cumplido": True,
        "valor": Decimal("18.50"),
        "origen": "offline",
        "registrado_en": datetime(2026, 11, 23, 8, 5, tzinfo=timezone(timedelta(hours=-6))),
    }
    r = registro(fila)
    assert r["valor"] == 18.5
    assert r["registrado_en"] == datetime(2026, 11, 23, 14, 5, tzinfo=UTC)


def test_registro_sin_valor() -> None:
    fila = {
        "id": uuid.uuid4(),
        "habito_id": uuid.uuid4(),
        "fecha": date(2026, 11, 23),
        "cumplido": False,
        "valor": None,
        "origen": "manual",
        "registrado_en": datetime(2026, 11, 23, 14, 5, tzinfo=UTC),
    }
    assert registro(fila)["valor"] is None


def test_resumen_de_error() -> None:
    assert resumen_de(HabitoArchivado("x")) == {
        "type": "https://kaizen.app/errores/habito-archivado",
        "status": 409,
        "title": "El hábito está archivado",
    }
    assert resumen_de(KaizenError("raro"))["status"] == 500  # uno sin tipo propio
