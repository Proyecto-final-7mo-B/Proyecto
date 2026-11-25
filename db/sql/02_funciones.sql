-- =====================================================================
-- Kaizen · 02_funciones.sql
-- Funciones de negocio. Todas fijan search_path (evita secuestro de
-- objetos por un esquema malicioso en la ruta de búsqueda).
-- Códigos SQLSTATE propios: clase KZ (ver tabla en el documento, 4.5).
-- IA: asistido. Revisión: Jael Contreras.
-- =====================================================================
BEGIN;
SET search_path = kaizen, pg_temp;

-- ---------------------------------------------------------------------
-- fn_region: deriva la shard key. El estado NO se guarda (minimización).
-- p_estado usa la clave ISO 3166-2:MX sin prefijo (AGU, CMX, NLE, ...).
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_region(p_pais char(2), p_estado text DEFAULT NULL)
RETURNS region_t
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    IF p_pais IS NULL THEN
        RAISE EXCEPTION 'El país es obligatorio' USING ERRCODE = 'KZ002';
    ELSIF p_pais = 'MX' THEN
        IF upper(p_estado) = ANY (ARRAY['BCN','BCS','SON','CHH','COA','NLE','TAM','SIN','DUR',
                                         'ZAC','SLP','NAY','JAL','COL','AGU','GUA','QUE','MIC']) THEN
            RETURN 'MX-NORTE';
        ELSIF upper(p_estado) = ANY (ARRAY['CMX','MEX','HID','MOR','TLA','PUE','VER','GRO',
                                            'OAX','CHP','TAB','CAM','YUC','ROO']) THEN
            RETURN 'MX-CENTRO-SUR';
        END IF;
        RAISE EXCEPTION 'Estado de México no válido: %', p_estado USING ERRCODE = 'KZ002';
    ELSIF p_pais = ANY (ARRAY['AR','BO','BR','CL','CO','CR','CU','DO','EC','SV','GT','HN',
                               'NI','PA','PY','PE','PR','UY','VE']) THEN
        RETURN 'LATAM';
    END IF;
    RAISE EXCEPTION 'País fuera del alcance del servicio: %', p_pais USING ERRCODE = 'KZ002';
END;
$$;

-- ---------------------------------------------------------------------
-- fn_dia_programado: ¿el hábito exige cumplimiento en esa fecha?
-- n_por_semana: ningún día es obligatorio por sí mismo.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_dia_programado(p_tipo text, p_dias smallint, p_fecha date)
RETURNS boolean
LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = kaizen, pg_temp
AS $$
    SELECT CASE p_tipo
        WHEN 'diaria'       THEN true
        WHEN 'dias_semana'  THEN (p_dias & (1 << (extract(isodow FROM p_fecha)::int - 1))) <> 0
        ELSE false
    END;
$$;

-- ---------------------------------------------------------------------
-- fn_rachas: calcula racha actual, máxima y último día cumplido a
-- partir de registro, opcionalmente desde una fecha (usado por F3).
-- Regla: un día programado sin cumplir (o sin registro) rompe la racha;
-- un día no programado no la rompe. En n_por_semana solo un registro
-- explícito con cumplido = false la rompe.
-- Costo: O(días de historia del hábito), acotado a ~365 por año.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_rachas(p_region region_t, p_habito uuid, p_desde date DEFAULT NULL,
                          OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date)
LANGUAGE plpgsql STABLE
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    h       record;
    d       record;
    v_ini   date;
    v_fin   date;
BEGIN
    racha_actual := 0; racha_maxima := 0; ultima_fecha := NULL;

    SELECT frecuencia_tipo, dias_semana INTO h
      FROM habito WHERE region = p_region AND id = p_habito;
    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT min(fecha), max(fecha) INTO v_ini, v_fin
      FROM registro WHERE region = p_region AND habito_id = p_habito
       AND (p_desde IS NULL OR fecha >= p_desde);
    IF v_ini IS NULL THEN
        RETURN;
    END IF;

    FOR d IN
        SELECT s.dia::date AS dia, r.cumplido
          FROM generate_series(v_ini, v_fin, interval '1 day') AS s(dia)
          LEFT JOIN registro r
                 ON r.region = p_region AND r.habito_id = p_habito AND r.fecha = s.dia::date
         ORDER BY s.dia
    LOOP
        IF h.frecuencia_tipo = 'n_por_semana' THEN
            CONTINUE WHEN d.cumplido IS NULL;
        ELSIF NOT fn_dia_programado(h.frecuencia_tipo, h.dias_semana, d.dia) THEN
            CONTINUE;
        END IF;

        IF coalesce(d.cumplido, false) THEN
            racha_actual := racha_actual + 1;
            racha_maxima := greatest(racha_maxima, racha_actual);
            ultima_fecha := d.dia;
        ELSE
            racha_actual := 0;
        END IF;
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------------
-- fn_dia_programado_anterior: último día programado estrictamente antes
-- de p_fecha. Sirve para saber si una racha almacenada sigue vigente.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_dia_programado_anterior(p_tipo text, p_dias smallint, p_fecha date)
RETURNS date
LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = kaizen, pg_temp
AS $$
    SELECT max(p_fecha - k)
      FROM generate_series(1, 7) AS k
     WHERE fn_dia_programado(p_tipo, p_dias, p_fecha - k);
$$;

-- ---------------------------------------------------------------------
-- fn_cumplimiento: % de cumplimiento en una ventana (F1 usa 14 días).
-- Devuelve NULL si el hábito es más joven que la ventana.
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_cumplimiento(p_region region_t, p_habito uuid,
                                p_dias integer DEFAULT 14, p_hasta date DEFAULT current_date)
RETURNS numeric(5,2)
LANGUAGE plpgsql STABLE
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    h            record;
    v_desde      date := p_hasta - (p_dias - 1);
    v_esperados  numeric;
    v_cumplidos  integer;
BEGIN
    SELECT frecuencia_tipo, dias_semana, veces_semana, fecha_creacion::date AS creado INTO h
      FROM habito WHERE region = p_region AND id = p_habito;
    IF NOT FOUND OR h.creado > v_desde THEN
        RETURN NULL;
    END IF;

    SELECT count(*) FILTER (WHERE cumplido) INTO v_cumplidos
      FROM registro
     WHERE region = p_region AND habito_id = p_habito AND fecha BETWEEN v_desde AND p_hasta;

    IF h.frecuencia_tipo = 'n_por_semana' THEN
        v_esperados := h.veces_semana * p_dias / 7.0;
    ELSE
        SELECT count(*) INTO v_esperados
          FROM generate_series(v_desde, p_hasta, interval '1 day') AS s(dia)
         WHERE fn_dia_programado(h.frecuencia_tipo, h.dias_semana, s.dia::date);
    END IF;

    IF v_esperados = 0 THEN
        RETURN NULL;
    END IF;
    RETURN least(100, round(100.0 * v_cumplidos / v_esperados, 2));
END;
$$;

-- ---------------------------------------------------------------------
-- fn_auditar: inserción centralizada en la bitácora (la usan los
-- procedimientos; la API también puede insertar directamente).
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_auditar(p_usuario uuid, p_region region_t, p_accion text,
                           p_recurso text, p_resultado text, p_ip inet DEFAULT NULL)
RETURNS void
LANGUAGE sql VOLATILE
SET search_path = kaizen, pg_temp
AS $$
    INSERT INTO bitacora_auditoria (usuario_id, region, accion, recurso, resultado, ip)
    VALUES (p_usuario, p_region, p_accion, p_recurso, p_resultado, p_ip);
$$;

COMMIT;
