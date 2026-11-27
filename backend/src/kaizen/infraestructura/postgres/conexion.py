"""Pool de conexiones y unidad de trabajo.

Cada operación abre UNA transacción y, antes de tocar datos, fija con set_config(..., true):
- kaizen.usuario_id: la Row-Level Security solo deja ver las filas de ese usuario;
- TimeZone: la zona del usuario, para que "hoy" (current_date) sea su día y no el de UTC.
El `true` hace que ambos valgan solo para esa transacción (seguro con el pool).
"""

from collections.abc import Iterator
from contextlib import contextmanager
from uuid import UUID

from psycopg import Connection
from psycopg_pool import ConnectionPool

from kaizen.config import Configuracion


def crear_pool(cfg: Configuracion) -> ConnectionPool:
    return ConnectionPool(
        cfg.db_conninfo,
        kwargs={"password": cfg.db_password.get_secret_value()},
        min_size=1,
        max_size=cfg.db_pool_max,
        open=True,
    )


class UnidadDeTrabajo:
    """Abre transacciones con el contexto de seguridad ya puesto."""

    def __init__(self, pool: ConnectionPool, zona_defecto: str = "UTC") -> None:
        self._pool = pool
        self._zona_defecto = zona_defecto

    @contextmanager
    def transaccion(
        self, usuario_id: UUID | None = None, zona: str | None = None
    ) -> Iterator[Connection]:
        with self._pool.connection() as conn, conn.transaction():
            conn.execute(
                "SELECT set_config('kaizen.usuario_id', %s, true),"
                " set_config('TimeZone', %s, true)",
                (str(usuario_id) if usuario_id else "", zona or self._zona_defecto),
            )
            yield conn  # commit al salir sin error; rollback si hay excepción

    def base_disponible(self) -> bool:
        try:
            with self._pool.connection(timeout=2) as conn:
                conn.execute("SELECT 1")
            return True
        except Exception:
            return False
