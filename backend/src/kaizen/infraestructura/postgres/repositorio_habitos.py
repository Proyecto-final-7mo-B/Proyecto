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
    NuevoHabito,
    Objeto,
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
       h.escalera_activa, h.activo, h.fecha_creacion,
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
        "racha": {
            "actual": fila["racha_actual"] or 0,
            "maxima": fila["racha_maxima"] or 0,
            "ultima_fecha": fila["ultima_fecha"],
            "protegida_esta_semana": bool(fila["protector_usado_semana"]),
        },
        "evaluacion": evaluacion(fila),
        "hoy": {"fecha": fecha, "programado": bool(fila["programado"]), "registro": registro},
    }


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

    def crear(self, usuario: UsuarioActual, zona: str, nuevo: NuevoHabito) -> UUID:
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
