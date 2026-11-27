-- =====================================================================
-- Kaizen · REVERSIÓN de 2026-11-27_evidencia_cientifica.sql
-- Deja la estructura como el 23-nov: 8 categorías sin subcategorías, Escalera sin
-- referencias, rachas sin protector, cápsulas 7/21/66 y sin logros.
-- Los hábitos se reasignan a la categoría vieja equivalente; se pierden la prioridad,
-- la intención y los logros otorgados. Las cápsulas de 30 pasan a 21.
-- Como postgres en el PRIMARIO, en una transacción. Antes de revertir en el clúster,
-- conviene un respaldo diferencial con pgBackRest (documento 04).
-- IA: asistido (Claude). Revisión: Jael Contreras.
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE kaizen_owner;
SET LOCAL search_path = kaizen, pg_temp;

-- ---------------------------------------------------------------------
-- Logros
-- ---------------------------------------------------------------------
DROP TRIGGER trg_racha_logros ON racha;
DROP TRIGGER trg_sugerencia_logro ON sugerencia_ajuste;
DROP TRIGGER trg_capsula_logro ON capsula;
DROP TRIGGER trg_habito_logro_intencion_ins ON habito;
DROP TRIGGER trg_habito_logro_intencion_upd ON habito;
DROP PROCEDURE sp_otorgar_logros_semanales(date, integer);
DROP FUNCTION fn_logros_usuario(region_t, uuid);
DROP FUNCTION tg_racha_logros(), tg_sugerencia_logro(), tg_capsula_logro(), tg_habito_logro_intencion();
DROP FUNCTION fn_otorgar_logro(region_t, uuid, text, uuid);
DROP TABLE logro_usuario;
DROP TABLE logro;

-- ---------------------------------------------------------------------
-- Cápsulas 7/21/66
-- ---------------------------------------------------------------------
ALTER TABLE capsula DROP CONSTRAINT capsula_racha_objetivo_check;
ALTER TABLE capsula DISABLE TRIGGER trg_capsula_guardia;
UPDATE capsula SET racha_objetivo = 21 WHERE racha_objetivo = 30;
ALTER TABLE capsula ENABLE TRIGGER trg_capsula_guardia;
ALTER TABLE capsula ADD CONSTRAINT capsula_racha_objetivo_check CHECK (racha_objetivo IN (7, 21, 66));

-- ---------------------------------------------------------------------
-- Rachas sin protector
-- ---------------------------------------------------------------------
DROP VIEW v_racha_vigente;
DROP FUNCTION fn_rachas(region_t, uuid, date, date);
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
    SELECT frecuencia_tipo, dias_semana INTO h FROM habito WHERE region = p_region AND id = p_habito;
    IF NOT FOUND THEN RETURN; END IF;
    SELECT min(fecha), max(fecha) INTO v_ini, v_fin
      FROM registro WHERE region = p_region AND habito_id = p_habito AND (p_desde IS NULL OR fecha >= p_desde);
    IF v_ini IS NULL THEN RETURN; END IF;
    FOR d IN
        SELECT s.dia::date AS dia, r.cumplido
          FROM generate_series(v_ini, v_fin, interval '1 day') AS s(dia)
          LEFT JOIN registro r ON r.region = p_region AND r.habito_id = p_habito AND r.fecha = s.dia::date
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
REVOKE ALL ON FUNCTION fn_rachas(region_t, uuid, date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION fn_rachas(region_t, uuid, date) TO kaizen_api, kaizen_etl, kaizen_admin;

CREATE OR REPLACE FUNCTION tg_registro_racha() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    INSERT INTO racha AS ra (region, habito_id, racha_actual, racha_maxima, ultima_fecha, actualizada_en)
    SELECT a.region, a.habito_id, c.racha_actual, c.racha_maxima, c.ultima_fecha, now()
      FROM (SELECT DISTINCT region, habito_id FROM cambios) a
      JOIN habito h ON h.region = a.region AND h.id = a.habito_id
      CROSS JOIN LATERAL fn_rachas(a.region, a.habito_id) c
    ON CONFLICT (region, habito_id) DO UPDATE
       SET racha_actual = EXCLUDED.racha_actual, racha_maxima = EXCLUDED.racha_maxima,
           ultima_fecha = EXCLUDED.ultima_fecha, actualizada_en = EXCLUDED.actualizada_en;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_reconstruir_rachas(
    p_region region_t DEFAULT NULL,
    INOUT p_corregidas integer DEFAULT 0)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    WITH calc AS (
        SELECT h.region, h.id AS habito_id, c.*
          FROM habito h CROSS JOIN LATERAL fn_rachas(h.region, h.id) c
         WHERE p_region IS NULL OR h.region = p_region
    ), upd AS (
        INSERT INTO racha AS ra (region, habito_id, racha_actual, racha_maxima, ultima_fecha)
        SELECT region, habito_id, racha_actual, racha_maxima, ultima_fecha FROM calc
        ON CONFLICT (region, habito_id) DO UPDATE
           SET racha_actual = EXCLUDED.racha_actual, racha_maxima = EXCLUDED.racha_maxima,
               ultima_fecha = EXCLUDED.ultima_fecha, actualizada_en = now()
         WHERE (ra.racha_actual, ra.racha_maxima, ra.ultima_fecha)
               IS DISTINCT FROM (EXCLUDED.racha_actual, EXCLUDED.racha_maxima, EXCLUDED.ultima_fecha)
        RETURNING 1
    )
    SELECT count(*) INTO p_corregidas FROM upd;
END;
$$;
ALTER TABLE racha DROP COLUMN ultimo_protegido;

CREATE VIEW v_racha_vigente WITH (security_invoker = true, security_barrier) AS
SELECT r.region, r.habito_id, h.usuario_id,
       CASE
           WHEN h.frecuencia_tipo = 'n_por_semana' THEN r.racha_actual
           WHEN r.ultima_fecha >= fn_dia_programado_anterior(h.frecuencia_tipo, h.dias_semana, current_date)
                THEN r.racha_actual
           ELSE 0
       END AS racha_actual,
       r.racha_maxima,
       r.ultima_fecha
  FROM racha r
  JOIN habito h ON h.region = r.region AND h.id = r.habito_id;
GRANT SELECT ON v_racha_vigente TO kaizen_api;

-- ---------------------------------------------------------------------
-- Escalera del 23-nov
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_generar_sugerencias(
    p_region region_t DEFAULT NULL,
    p_hoy    date     DEFAULT current_date,
    INOUT p_creadas integer DEFAULT 0)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    c_umbral_subir CONSTANT numeric := 85;
    c_umbral_bajar CONSTANT numeric := 50;
    c_paso_subir   CONSTANT numeric := 1.10;
    c_paso_bajar   CONSTANT numeric := 0.85;
BEGIN
    WITH candidatos AS (
        SELECT h.region, h.id, h.meta, fn_cumplimiento(h.region, h.id, 14, p_hoy - 1) AS pct
          FROM habito h
          JOIN nivel_habito n ON n.region = h.region AND n.habito_id = h.id AND n.vigente_hasta IS NULL
         WHERE h.activo AND h.escalera_activa
           AND (p_region IS NULL OR h.region = p_region)
           AND n.vigente_desde <= p_hoy - 14
           AND NOT EXISTS (SELECT 1 FROM sugerencia_ajuste s
                            WHERE s.region = h.region AND s.habito_id = h.id AND s.estado = 'pendiente')
    ), nuevas AS (
        INSERT INTO sugerencia_ajuste (region, habito_id, tipo, meta_actual, meta_propuesta, cumplimiento_14d)
        SELECT region, id,
               CASE WHEN pct >= c_umbral_subir THEN 'subir' ELSE 'bajar' END,
               meta,
               CASE WHEN pct >= c_umbral_subir
                    THEN greatest(round(meta * c_paso_subir, 2), meta + 0.01)
                    ELSE greatest(least(round(meta * c_paso_bajar, 2), meta - 0.01), 0.01) END,
               pct
          FROM candidatos
         WHERE pct IS NOT NULL
           AND (pct >= c_umbral_subir OR pct < c_umbral_bajar)
           AND NOT (pct < c_umbral_bajar AND meta <= 0.01)
        RETURNING 1
    )
    SELECT count(*) INTO p_creadas FROM nuevas;
END;
$$;
UPDATE sugerencia_ajuste SET estado = 'expirada' WHERE estado = 'pendiente' AND cumplimiento_14d IS NULL;
ALTER TABLE sugerencia_ajuste DISABLE TRIGGER trg_sugerencia_estado;
UPDATE sugerencia_ajuste SET cumplimiento_14d = 0 WHERE cumplimiento_14d IS NULL;
ALTER TABLE sugerencia_ajuste ENABLE TRIGGER trg_sugerencia_estado;
ALTER TABLE sugerencia_ajuste DROP COLUMN motivo, DROP COLUMN referencia_id,
                              ALTER COLUMN cumplimiento_14d SET NOT NULL;

-- ---------------------------------------------------------------------
-- Evaluación, administración del catálogo y vistas
-- ---------------------------------------------------------------------
DROP VIEW v_habito_evidencia;
DROP FUNCTION fn_evaluar_meta(uuid, text, numeric, text, smallint, smallint);
DROP FUNCTION fn_redondear_paso(numeric, numeric, text);
DROP FUNCTION fn_sesiones_semana(text, smallint, smallint);
DROP PROCEDURE sp_admin_crear_subcategoria(uuid, uuid, text, text, text[], inet, uuid);
DROP PROCEDURE sp_admin_actualizar_subcategoria(uuid, uuid, text, boolean, inet);
DROP PROCEDURE sp_admin_guardar_referencia(uuid, uuid, text, text, numeric, numeric, numeric, text, text, text,
                                           text, text, inet, numeric);

CREATE OR REPLACE PROCEDURE sp_admin_crear_categoria(
    p_admin   uuid,
    p_nombre  text,
    p_ip      inet DEFAULT NULL,
    INOUT p_id uuid DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_region_admin region_t := fn_verificar_admin(p_admin);
BEGIN
    IF p_nombre IS NULL OR length(btrim(p_nombre)) NOT BETWEEN 2 AND 40 THEN
        RAISE EXCEPTION 'El nombre debe tener de 2 a 40 caracteres' USING ERRCODE = 'KZ011';
    END IF;
    BEGIN
        INSERT INTO categoria (nombre) VALUES (btrim(p_nombre)) RETURNING id INTO p_id;
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una categoría con ese nombre' USING ERRCODE = 'KZ013';
    END;
    PERFORM fn_auditar(p_admin, v_region_admin, 'admin.categoria_crear', 'categoria/' || p_id, 'exito', p_ip);
END;
$$;

DROP VIEW v_metricas_region;
CREATE VIEW v_metricas_region AS
SELECT h.region, c.nombre AS categoria,
       count(DISTINCT h.usuario_id) AS usuarios, count(*) AS habitos, round(avg(r.racha_actual), 2) AS racha_promedio
  FROM habito h
  JOIN categoria c ON c.id = h.categoria_id
  JOIN racha r     ON r.region = h.region AND r.habito_id = h.id
 WHERE h.activo
 GROUP BY h.region, c.nombre
HAVING count(DISTINCT h.usuario_id) >= 5;
GRANT SELECT ON v_metricas_region TO kaizen_api;

-- ---------------------------------------------------------------------
-- Catálogo de 8 categorías: los hábitos vuelven a la categoría equivalente
-- ---------------------------------------------------------------------
DROP TRIGGER trg_habito_a_subcategoria ON habito;
DROP FUNCTION tg_habito_subcategoria();
UPDATE categoria SET nombre = 'Aprendizaje' WHERE clave = 'educacion';
INSERT INTO categoria (nombre, clave) VALUES ('Lectura', 'lectura'), ('Hidratación', 'hidratacion'),
                                             ('Sueño', 'sueno'), ('Meditación', 'meditacion')
ON CONFLICT DO NOTHING;
UPDATE habito h SET categoria_id = c.id
  FROM subcategoria s, categoria c
 WHERE s.id = h.subcategoria_id
   AND c.clave = CASE s.clave WHEN 'lectura' THEN 'lectura' WHEN 'hidratacion' THEN 'hidratacion'
                              WHEN 'sueno' THEN 'sueno' WHEN 'meditacion' THEN 'meditacion'
                              WHEN 'gratitud' THEN 'meditacion' WHEN 'aire_libre' THEN 'salud'
                              WHEN 'convivencia_social' THEN 'salud' WHEN 'reducir_pantallas' THEN 'salud'
                              ELSE (SELECT k.clave FROM categoria k WHERE k.id = s.categoria_id) END;
DROP INDEX ix_habito_subcategoria;
ALTER TABLE habito DROP COLUMN subcategoria_id, DROP COLUMN prioridad, DROP COLUMN intencion;
DROP TABLE referencia_cientifica;
DROP TABLE unidad_subcategoria;
DROP TABLE subcategoria;
DELETE FROM categoria WHERE clave = 'bienestar';
ALTER TABLE categoria DROP COLUMN clave, DROP COLUMN color, DROP COLUMN icono, DROP COLUMN orden;
DROP FUNCTION fn_clave(text);

CALL sp_reconstruir_rachas(NULL, NULL);
COMMIT;
