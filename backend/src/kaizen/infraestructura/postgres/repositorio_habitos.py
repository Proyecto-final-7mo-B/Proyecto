"""Hábitos y catálogo sobre PostgreSQL (implementa aplicacion.puertos.RepositorioHabitos).

- Toda consulta va con parámetros %s; los nombres de columna del UPDATE salen de una lista fija
  y se componen con psycopg.sql.Identifier (nunca texto del usuario dentro del SQL).
- La RLS solo deja ver los hábitos del usuario de la transacción: un id de otro usuario
  simplemente no aparece (la API responde 404).
- Las zonas y rangos científicos vienen de v_habito_evidencia y fn_evaluar_meta:
  no se calculan aquí.
"""

from datetime import UTC, date
from decimal import Decimal
from typing import Any
from uuid import UUID

from psycopg import sql
from psycopg.rows import dict_row

from kaizen.aplicacion.puertos import (
    ConsultaEvaluacion,
    HabitoDesdeRecomendacion,
    NuevoHabito,
    Objeto,
    Recomendacion,
    UsuarioActual,
)
from kaizen.dominio.excepciones import SubcategoriaInactiva, UnidadNoPermitida, ValidacionError
from kaizen.infraestructura.postgres.conexion import UnidadDeTrabajo

SQL_CATALOGO = """
SELECT c.id AS c_id, c.clave AS c_clave, c.nombre AS c_nombre, c.color, c.icono AS c_icono,
       s.id AS s_id, s.clave AS s_clave, s.nombre AS s_nombre, s.icono AS s_icono, s.sentido,
       u.unidad, u.factor_a_base, u.paso, u.minimo, u.maximo AS u_maximo,
       r.periodo, r.unidad_base, r.optimo_desde, r.optimo_hasta, r.maximo AS r_maximo,
       r.piso_bajada, r.cita, r.fuentes, r.url, r.confianza, r.nota, r.id AS r_id
  FROM categoria c
  JOIN subcategoria s ON s.categoria_id = c.id AND s.activa
  LEFT JOIN unidad_subcategoria u ON u.subcategoria_id = s.id
  LEFT JOIN referencia_cientifica r ON r.subcategoria_id = s.id
 WHERE c.activa
 ORDER BY c.orden, c.nombre, s.orden, s.nombre, u.orden, u.unidad
"""

SQL_HABITOS = """
SELECT h.id, h.nombre, h.unidad, h.meta, n.nivel,
       c.id AS c_id, c.clave AS c_clave, c.nombre AS c_nombre, c.color, c.icono AS c_icono,
       s.id AS s_id, s.clave AS s_clave, s.nombre AS s_nombre, s.icono AS s_icono,
       s.sentido AS s_sentido,
       h.prioridad, h.intencion, h.frecuencia_tipo, h.dias_semana, h.veces_semana,
       h.escalera_activa, h.activo, h.fecha_creacion, h.recomendacion_id,
       r.racha_actual, r.racha_maxima, r.ultima_fecha, r.protector_usado_semana,
       e.zona, e.sentido, e.volumen, e.unidad_base, e.periodo, e.optimo_desde, e.optimo_hasta,
       e.maximo, e.meta_sugerida, e.paso, e.cita, e.fuentes, e.url, e.confianza, e.nota,
       fn_dia_programado(h.frecuencia_tipo, h.dias_semana, %(fecha)s) AS programado,
       g.id AS g_id, g.cumplido AS g_cumplido, g.valor AS g_valor
  FROM habito h
  JOIN categoria c ON c.id = h.categoria_id
  JOIN subcategoria s ON s.id = h.subcategoria_id
  LEFT JOIN nivel_habito n
         ON n.region = h.region AND n.habito_id = h.id AND n.vigente_hasta IS NULL
  LEFT JOIN v_racha_vigente r ON r.region = h.region AND r.habito_id = h.id
  LEFT JOIN v_habito_evidencia e ON e.region = h.region AND e.habito_id = h.id
  LEFT JOIN registro g ON g.region = h.region AND g.habito_id = h.id AND g.fecha = %(fecha)s
 WHERE h.region = %(region)s
   AND (h.activo OR %(archivados)s)
   AND (%(id)s::uuid IS NULL OR h.id = %(id)s::uuid)
 ORDER BY h.prioridad, h.nombre
"""

# fn_evaluar_meta no valida la unidad (regresa sin_referencia): se revisa antes, como el trigger
SQL_UNIDAD = """
SELECT s.activa, EXISTS (SELECT 1 FROM unidad_subcategoria u
                          WHERE u.subcategoria_id = s.id AND u.unidad = %s)
  FROM subcategoria s WHERE s.id = %s
"""

SQL_EVALUAR = "SELECT * FROM fn_evaluar_meta(%s, %s, %s, %s, %s::smallint, %s::smallint)"

SQL_CREAR = """
INSERT INTO habito (region, usuario_id, subcategoria_id, nombre, frecuencia_tipo, dias_semana,
                    veces_semana, meta, unidad, escalera_activa, prioridad, intencion)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
RETURNING id
"""

# Desde una recomendación: el trigger trg_habito_0_recomendacion copia lo demás (o lanza KZ018)
SQL_CREAR_RECOMENDADO = """
INSERT INTO habito (region, usuario_id, recomendacion_id, prioridad, escalera_activa)
VALUES (%s, %s, %s, %s, %s)
RETURNING id
"""

# Mismo resultado que v_habito_recomendado; con %(todas)s también las inactivas (administración)
SQL_RECOMENDADOS = """
SELECT r.id, r.clave, r.nombre, r.unidad, r.meta, r.frecuencia_tipo, r.dias_semana, r.veces_semana,
       r.momento, r.porque, r.fuentes, r.orden, r.activo AND s.activa AND c.activa AS activo,
       c.id AS c_id, c.clave AS c_clave, c.nombre AS c_nombre, c.color, c.icono AS c_icono,
       s.id AS s_id, s.clave AS s_clave, s.nombre AS s_nombre, s.icono AS s_icono,
       s.sentido AS s_sentido, e.zona, e.optimo_desde, e.optimo_hasta
  FROM habito_recomendado r
  JOIN subcategoria s ON s.id = r.subcategoria_id
  JOIN categoria c ON c.id = s.categoria_id
 CROSS JOIN LATERAL fn_evaluar_meta(r.subcategoria_id, r.unidad, r.meta, r.frecuencia_tipo,
                                    r.dias_semana, r.veces_semana) e
 WHERE (%(todas)s OR (r.activo AND s.activa AND c.activa))
   AND (%(clave)s::text IS NULL OR r.clave = %(clave)s::text)
 ORDER BY c.orden, s.orden, r.orden, r.nombre
"""

SQL_FUENTES = """
SELECT clave, tema, referencia, enlace, dato, verificada, confianza
  FROM fuente_cientifica ORDER BY clave
"""

SQL_GUARDAR_RECOMENDACION = """
CALL sp_admin_guardar_recomendacion(%s, %s, %s, %s, %s, %s, %s, %s::smallint, %s::smallint,
                                    %s, %s, %s, %s, %s::smallint, %s::inet, NULL)
"""

# Columnas que PATCH puede tocar (el servicio ya filtró los campos; esto es la segunda barrera)
COLUMNAS = (
    "nombre",
    "subcategoria_id",
    "unidad",
    "prioridad",
    "intencion",
    "escalera_activa",
    "activo",
)

CAMPOS_EVALUACION = (
    "zona", "sentido", "volumen", "unidad_base", "periodo", "optimo_desde", "optimo_hasta",
    "maximo", "meta_sugerida", "paso", "cita", "fuentes", "url", "confianza", "nota",
)  # fmt: skip


def numero(valor: Decimal | None) -> float | None:
    """numeric de PostgreSQL -> número JSON (el contrato pide números, no textos)."""
    return None if valor is None else float(valor)


def evaluacion(fila: dict[str, Any]) -> Objeto | None:
    if fila.get("zona") is None:
        return None
    return {
        k: numero(fila[k]) if isinstance(fila[k], Decimal) else fila[k] for k in CAMPOS_EVALUACION
    }


def habito(fila: dict[str, Any], fecha: date) -> Objeto:
    registro = None
    if fila["g_id"] is not None:
        registro = {
            "id": fila["g_id"],
            "cumplido": fila["g_cumplido"],
            "valor": numero(fila["g_valor"]),
        }
    return {
        "id": fila["id"],
        "nombre": fila["nombre"],
        "unidad": fila["unidad"],
        "meta": numero(fila["meta"]),
        "nivel": fila["nivel"] or 1,
        "categoria": {
            "id": fila["c_id"],
            "clave": fila["c_clave"],
            "nombre": fila["c_nombre"],
            "color": fila["color"],
            "icono": fila["c_icono"],
        },
        "subcategoria": {
            "id": fila["s_id"],
            "clave": fila["s_clave"],
            "nombre": fila["s_nombre"],
            "icono": fila["s_icono"],
            "sentido": fila["s_sentido"],
        },
        "prioridad": fila["prioridad"],
        "intencion": fila["intencion"],
        "frecuencia": {
            "tipo": fila["frecuencia_tipo"],
            "dias_semana": fila["dias_semana"],
            "veces_semana": fila["veces_semana"],
        },
        "escalera_activa": fila["escalera_activa"],
        "activo": fila["activo"],
        "fecha_creacion": fila["fecha_creacion"].astimezone(UTC),  # instantes siempre en UTC
        "recomendacion_id": fila["recomendacion_id"],
        "racha": {
            "actual": fila["racha_actual"] or 0,
            "maxima": fila["racha_maxima"] or 0,
            "ultima_fecha": fila["ultima_fecha"],
            "protegida_esta_semana": bool(fila["protector_usado_semana"]),
        },
        "evaluacion": evaluacion(fila),
        "hoy": {"fecha": fecha, "programado": bool(fila["programado"]), "registro": registro},
    }


def recomendacion(fila: dict[str, Any], con_activo: bool) -> Objeto:
    objeto: Objeto = {
        "id": fila["id"],
        "clave": fila["clave"],
        "nombre": fila["nombre"],
        "categoria": {
            "id": fila["c_id"],
            "clave": fila["c_clave"],
            "nombre": fila["c_nombre"],
            "color": fila["color"],
            "icono": fila["c_icono"],
        },
        "subcategoria": {
            "id": fila["s_id"],
            "clave": fila["s_clave"],
            "nombre": fila["s_nombre"],
            "icono": fila["s_icono"],
            "sentido": fila["s_sentido"],
        },
        "unidad": fila["unidad"],
        "meta": numero(fila["meta"]),
        "frecuencia": {
            "tipo": fila["frecuencia_tipo"],
            "dias_semana": fila["dias_semana"],
            "veces_semana": fila["veces_semana"],
        },
        "momento": fila["momento"],
        "porque": fila["porque"],
        "fuentes": fila["fuentes"],
        "zona": fila["zona"],
        "optimo_desde": numero(fila["optimo_desde"]),
        "optimo_hasta": numero(fila["optimo_hasta"]),
    }
    if con_activo:
        objeto["activo"] = fila["activo"]
        objeto["orden"] = fila["orden"]
    return objeto


def arbol(filas: list[dict[str, Any]]) -> list[Objeto]:
    """Filas planas (categoría × subcategoría × unidad) -> árbol del contrato §6.3."""
    categorias: dict[UUID, Objeto] = {}
    subcategorias: dict[UUID, Objeto] = {}
    for f in filas:
        cat = categorias.setdefault(
            f["c_id"],
            {
                "id": f["c_id"],
                "clave": f["c_clave"],
                "nombre": f["c_nombre"],
                "color": f["color"],
                "icono": f["c_icono"],
                "subcategorias": [],
            },
        )
        sub = subcategorias.get(f["s_id"])
        if sub is None:
            referencia = None
            if f["r_id"] is not None:
                referencia = {
                    "periodo": f["periodo"],
                    "unidad_base": f["unidad_base"],
                    "optimo_desde": numero(f["optimo_desde"]),
                    "optimo_hasta": numero(f["optimo_hasta"]),
                    "maximo": numero(f["r_maximo"]),
                    "piso_bajada": numero(f["piso_bajada"]),
                    "cita": f["cita"],
                    "fuentes": f["fuentes"],
                    "url": f["url"],
                    "confianza": f["confianza"],
                    "nota": f["nota"],
                }
            sub = {
                "id": f["s_id"],
                "clave": f["s_clave"],
                "nombre": f["s_nombre"],
                "icono": f["s_icono"],
                "sentido": f["sentido"],
                "unidades": [],
                "referencia": referencia,
            }
            subcategorias[f["s_id"]] = sub
            cat["subcategorias"].append(sub)
        if f["unidad"] is not None:
            sub["unidades"].append(
                {
                    "unidad": f["unidad"],
                    "factor_a_base": numero(f["factor_a_base"]),
                    "paso": numero(f["paso"]),
                    "minimo": numero(f["minimo"]),
                    "maximo": numero(f["u_maximo"]),
                }
            )
    return list(categorias.values())


class RepositorioHabitosPg:
    def __init__(self, uow: UnidadDeTrabajo) -> None:
        self._uow = uow

    def categorias(self, zona: str) -> list[Objeto]:
        with self._uow.transaccion(zona=zona) as conn:
            filas = conn.cursor(row_factory=dict_row).execute(SQL_CATALOGO).fetchall()
        return arbol(filas)

    def evaluar(self, usuario: UsuarioActual, zona: str, consulta: ConsultaEvaluacion) -> Objeto:
        f = consulta.frecuencia
        with self._uow.transaccion(usuario.id, zona) as conn:
            permitida = conn.execute(
                SQL_UNIDAD, (consulta.unidad, consulta.subcategoria_id)
            ).fetchone()
            if permitida is None:
                raise ValidacionError("La subcategoría no existe", campo="subcategoria_id")
            if not permitida[0]:
                raise SubcategoriaInactiva("La subcategoría está desactivada")
            if not permitida[1]:
                raise UnidadNoPermitida(
                    f'La unidad "{consulta.unidad}" no está permitida para esta subcategoría'
                )
            fila = (
                conn.cursor(row_factory=dict_row)
                .execute(
                    SQL_EVALUAR,
                    (
                        consulta.subcategoria_id,
                        consulta.unidad,
                        consulta.meta,
                        f.tipo,
                        f.dias_semana,
                        f.veces_semana,
                    ),
                )
                .fetchone()
            )
        resultado = evaluacion(fila or {})
        if resultado is None:  # pragma: no cover - la función siempre regresa una fila
            return {k: None for k in CAMPOS_EVALUACION} | {"zona": "sin_referencia"}
        return resultado

    def listar(
        self,
        usuario: UsuarioActual,
        zona: str,
        fecha: date,
        archivados: bool,
        habito_id: UUID | None = None,
    ) -> list[Objeto]:
        parametros = {
            "fecha": fecha,
            "region": usuario.region,
            "archivados": archivados,
            "id": habito_id,
        }
        with self._uow.transaccion(usuario.id, zona) as conn:
            filas = conn.cursor(row_factory=dict_row).execute(SQL_HABITOS, parametros).fetchall()
        return [habito(f, fecha) for f in filas]

    def crear(
        self, usuario: UsuarioActual, zona: str, nuevo: NuevoHabito | HabitoDesdeRecomendacion
    ) -> UUID:
        if isinstance(nuevo, HabitoDesdeRecomendacion):
            with self._uow.transaccion(usuario.id, zona) as conn:
                fila = conn.execute(
                    SQL_CREAR_RECOMENDADO,
                    (
                        usuario.region,
                        usuario.id,
                        nuevo.recomendacion_id,
                        nuevo.prioridad,
                        nuevo.escalera_activa,
                    ),
                ).fetchone()
            return self._id_creado(fila)
        f = nuevo.frecuencia
        with self._uow.transaccion(usuario.id, zona) as conn:
            fila = conn.execute(
                SQL_CREAR,
                (
                    usuario.region,
                    usuario.id,
                    nuevo.subcategoria_id,
                    nuevo.nombre,
                    f.tipo,
                    f.dias_semana,
                    f.veces_semana,
                    nuevo.meta,
                    nuevo.unidad,
                    nuevo.escalera_activa,
                    nuevo.prioridad,
                    nuevo.intencion,
                ),
            ).fetchone()
        return self._id_creado(fila)

    @staticmethod
    def _id_creado(fila: tuple[Any, ...] | None) -> UUID:
        if fila is None:  # pragma: no cover - INSERT ... RETURNING siempre regresa la fila
            raise RuntimeError("La base no regresó el id del hábito")
        habito_id: UUID = fila[0]
        return habito_id

    def actualizar(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, cambios: dict[str, Any]
    ) -> bool:
        columnas = [c for c in COLUMNAS if c in cambios]
        asignaciones = sql.SQL(", ").join(
            sql.SQL("{} = {}").format(sql.Identifier(c), sql.Placeholder()) for c in columnas
        )
        consulta = sql.SQL("UPDATE habito SET {} WHERE region = %s AND id = %s").format(
            asignaciones
        )
        valores = [cambios[c] for c in columnas] + [usuario.region, habito_id]
        with self._uow.transaccion(usuario.id, zona) as conn:
            cursor = conn.execute(consulta, valores)
        return cursor.rowcount == 1

    # ------------------------------------------------------------- v1.7

    def _recomendaciones(
        self, conn: Any, todas: bool, clave: str | None = None
    ) -> list[dict[str, Any]]:
        cursor = conn.cursor(row_factory=dict_row)
        filas: list[dict[str, Any]] = cursor.execute(
            SQL_RECOMENDADOS, {"todas": todas, "clave": clave}
        ).fetchall()
        return filas

    def recomendados(self, zona: str, incluir_inactivas: bool = False) -> list[Objeto]:
        with self._uow.transaccion(zona=zona) as conn:
            filas = self._recomendaciones(conn, incluir_inactivas)
        return [recomendacion(f, incluir_inactivas) for f in filas]

    def fuentes(self, zona: str) -> list[Objeto]:
        with self._uow.transaccion(zona=zona) as conn:
            filas: list[Objeto] = conn.cursor(row_factory=dict_row).execute(SQL_FUENTES).fetchall()
        return filas

    def dias_protegidos(
        self, usuario: UsuarioActual, zona: str, habito_id: UUID, desde: date, hasta: date
    ) -> list[date] | None:
        with self._uow.transaccion(usuario.id, zona) as conn:
            existe = conn.execute(  # la RLS esconde los hábitos de otros usuarios
                "SELECT 1 FROM habito WHERE region = %s AND id = %s", (usuario.region, habito_id)
            ).fetchone()
            if existe is None:
                return None
            filas = conn.execute(
                "SELECT d FROM fn_dias_protegidos(%s, %s, %s, %s) AS d ORDER BY d",
                (usuario.region, habito_id, desde, hasta),
            ).fetchall()
        return [f[0] for f in filas]

    def guardar_recomendacion(
        self, admin: UsuarioActual, zona: str, datos: Recomendacion, ip: str | None
    ) -> Objeto:
        f = datos.frecuencia
        with self._uow.transaccion(admin.id, zona) as conn:
            conn.execute(
                SQL_GUARDAR_RECOMENDACION,
                (
                    admin.id,
                    datos.clave,
                    datos.subcategoria_id,
                    datos.nombre,
                    datos.unidad,
                    datos.meta,
                    f.tipo,
                    f.dias_semana,
                    f.veces_semana,
                    datos.momento,
                    datos.porque,
                    datos.fuentes,
                    datos.activo,
                    datos.orden,
                    ip,
                ),
            )
            [fila] = self._recomendaciones(conn, True, datos.clave)
        return recomendacion(fila, True)
