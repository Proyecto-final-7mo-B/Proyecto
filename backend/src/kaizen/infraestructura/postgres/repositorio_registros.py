"""Check-ins sobre PostgreSQL (implementa aplicacion.puertos.RepositorioRegistros).

- Guardar usa CALL sp_registrar_checkin (de Jael): revisa que el hábito sea del usuario, hace
  el "upsert" del día y la racha se recalcula sola con un trigger.
- Cada check-in va en su propio SAVEPOINT: en el lote, si uno falla, los demás se guardan.
"""

from datetime import UTC, date
from typing import Any
from uuid import UUID

from psycopg import Connection, Error
from psycopg.errors import UniqueViolation
from psycopg.rows import dict_row

from kaizen.aplicacion.puertos import NuevoRegistro, Objeto, ResultadoRegistro, UsuarioActual
from kaizen.dominio.excepciones import KaizenError, ValidacionError
from kaizen.infraestructura.postgres.conexion import UnidadDeTrabajo
from kaizen.infraestructura.postgres.errores import traducir
from kaizen.infraestructura.postgres.repositorio_habitos import numero

SQL_CHECKIN = "CALL sp_registrar_checkin(%s, %s, %s, %s, %s, %s, %s, %s, NULL)"

# Un día tiene un solo check-in: si la app mandó otro id para el mismo día, se queda el primero
SQL_ID_DEL_DIA = "SELECT id FROM registro WHERE region = %s AND habito_id = %s AND fecha = %s"

SQL_EXISTE_HABITO = "SELECT 1 FROM habito WHERE region = %s AND id = %s"

SQL_HISTORIAL = """
SELECT id, habito_id, fecha, cumplido, valor, origen, registrado_en
  FROM registro
 WHERE region = %s AND habito_id = %s AND fecha BETWEEN %s AND %s
 ORDER BY fecha
"""


def registro(fila: dict[str, Any]) -> Objeto:
    return {
        "id": fila["id"],
        "habito_id": fila["habito_id"],
        "fecha": fila["fecha"],
        "cumplido": fila["cumplido"],
        "valor": numero(fila["valor"]),
        "origen": fila["origen"],
        "registrado_en": fila["registrado_en"].astimezone(UTC),  # instantes siempre en UTC
    }


class RepositorioRegistrosPg:
    def __init__(self, uow: UnidadDeTrabajo) -> None:
        self._uow = uow

    @staticmethod
    def _un_checkin(conn: Connection, usuario: UsuarioActual, r: NuevoRegistro) -> Objeto:
        """Un check-in dentro de su SAVEPOINT. Los errores de la base salen ya traducidos."""
        try:
            with conn.transaction():  # anidada = SAVEPOINT: si falla, solo se deshace esto
                fila = conn.execute(
                    SQL_CHECKIN,
                    (
                        usuario.region,
                        usuario.id,
                        r.id,
                        r.habito_id,
                        r.fecha,
                        r.cumplido,
                        r.valor,
                        r.origen,
                    ),
                ).fetchone()
                guardado = conn.execute(
                    SQL_ID_DEL_DIA, (usuario.region, r.habito_id, r.fecha)
                ).fetchone()
        except UniqueViolation as error:  # ese id ya es el check-in de otro hábito u otro día
            raise ValidacionError("Ese id ya es de otro check-in", campo="id") from error
        except Error as error:
            propio = traducir(error)
            if propio is None:
                raise
            raise propio from error
        racha = fila[0] if fila else None
        return {"id": guardado[0] if guardado else r.id, "racha_actual": racha or 0}

    def registrar(self, usuario: UsuarioActual, zona: str, registro: NuevoRegistro) -> Objeto:
        with self._uow.transaccion(usuario.id, zona) as conn:
            return self._un_checkin(conn, usuario, registro)

    def registrar_lote(
        self, usuario: UsuarioActual, zona: str, registros: list[NuevoRegistro]
    ) -> list[ResultadoRegistro]:
        resultados: list[ResultadoRegistro] = []
        with self._uow.transaccion(usuario.id, zona) as conn:
            for r in registros:
                try:
                    hecho = self._un_checkin(conn, usuario, r)
                    resultados.append(ResultadoRegistro(r.id, hecho["racha_actual"]))
                except KaizenError as error:  # se rechaza este y se sigue con el siguiente
                    resultados.append(ResultadoRegistro(r.id, error=error))
        return resultados

    def historial(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, desde: date, hasta: date
    ) -> list[Objeto] | None:
        with self._uow.transaccion(usuario.id, zona) as conn:
            # la RLS esconde los hábitos de otros usuarios: no existe = 404
            if conn.execute(SQL_EXISTE_HABITO, (usuario.region, habito_id)).fetchone() is None:
                return None
            filas = (
                conn.cursor(row_factory=dict_row)
                .execute(SQL_HISTORIAL, (usuario.region, habito_id, desde, hasta))
                .fetchall()
            )
        return [registro(f) for f in filas]
