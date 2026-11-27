"""Repositorio de autenticación sobre PostgreSQL (implementa aplicacion.puertos.RepositorioAuth).

Siempre parámetros %s: nunca SQL armado con texto (evita inyección SQL).
"""

from datetime import datetime
from uuid import UUID

from kaizen.aplicacion.puertos import CuentaLogin
from kaizen.infraestructura.postgres.conexion import UnidadDeTrabajo
from kaizen.infraestructura.seguridad.tokens import ParTokens

SQL_AUDITAR = (
    "INSERT INTO bitacora_auditoria (usuario_id, region, accion, resultado, ip)"
    " VALUES (%s, %s, %s, %s, %s)"
)


class RepositorioAuthPg:
    def __init__(self, uow: UnidadDeTrabajo) -> None:
        self._uow = uow

    def buscar_cuenta(self, email_hmac: str) -> CuentaLogin | None:
        with self._uow.transaccion() as conn:
            fila = conn.execute(
                "SELECT usuario_id, region FROM directorio_usuarios WHERE email_hmac = %s",
                (email_hmac,),
            ).fetchone()
        if fila is None:
            return None
        usuario_id, region = fila
        with self._uow.transaccion(usuario_id) as conn:
            datos = conn.execute(
                "SELECT nombre, rol, password_hash, intentos_fallidos, bloqueado_hasta,"
                " suspendido_en IS NOT NULL"
                " FROM usuario WHERE region = %s AND id = %s",
                (region, usuario_id),
            ).fetchone()
        if datos is None:  # pragma: no cover - el directorio y usuario se borran juntos
            return None
        nombre, rol, password_hash, intentos, bloqueado, suspendida = datos
        return CuentaLogin(
            id=usuario_id,
            region=region,
            nombre=nombre,
            rol=rol,
            password_hash=password_hash,
            intentos_fallidos=intentos,
            bloqueado_hasta=bloqueado,
            suspendida=suspendida,
        )

    def registrar_fallo(
        self, cuenta: CuentaLogin, intentos: int, bloqueado_hasta: datetime | None, ip: str | None
    ) -> None:
        with self._uow.transaccion(cuenta.id) as conn:
            conn.execute(
                "UPDATE usuario SET intentos_fallidos = %s, bloqueado_hasta = %s"
                " WHERE region = %s AND id = %s",
                (intentos, bloqueado_hasta, cuenta.region, cuenta.id),
            )
            conn.execute(SQL_AUDITAR, (cuenta.id, cuenta.region, "auth.login", "fallo", ip))

    def registrar_exito(
        self, cuenta: CuentaLogin, par: ParTokens, nuevo_hash: str | None, ip: str | None
    ) -> None:
        with self._uow.transaccion(cuenta.id) as conn:
            conn.execute(
                "UPDATE usuario SET intentos_fallidos = 0, bloqueado_hasta = NULL,"
                " password_hash = COALESCE(%s, password_hash)"
                " WHERE region = %s AND id = %s",
                (nuevo_hash, cuenta.region, cuenta.id),
            )
            conn.execute(
                "INSERT INTO sesion (jti, region, usuario_id, familia, expira_en)"
                " VALUES (%s, %s, %s, %s, %s)",
                (par.jti_sesion, cuenta.region, cuenta.id, par.familia, par.expira_renovacion),
            )
            conn.execute(SQL_AUDITAR, (cuenta.id, cuenta.region, "auth.login", "exito", ip))

    def auditar(
        self,
        usuario_id: UUID | None,
        region: str | None,
        accion: str,
        resultado: str,
        ip: str | None,
    ) -> None:
        with self._uow.transaccion(usuario_id) as conn:
            conn.execute(SQL_AUDITAR, (usuario_id, region, accion, resultado, ip))
