-- =====================================================================
-- Kaizen · REVERSIÓN de 2026-11-27_recomendaciones.sql
-- Deja la estructura como después de 2026-11-27_evidencia_cientifica.sql: sin
-- fuentes en la base, sin hábitos recomendados y sin fn_dias_protegidos.
-- Los hábitos creados desde una recomendación se conservan como personalizados
-- (solo se pierde de qué recomendación salieron).
-- Como postgres en el PRIMARIO, en una transacción. Antes de revertir en el clúster,
-- conviene un respaldo diferencial con pgBackRest (documento 04).
-- IA: asistido (Claude). Revisión: Jael Contreras.
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE kaizen_owner;
SET LOCAL search_path = kaizen, pg_temp;

DROP PROCEDURE sp_admin_guardar_recomendacion;
DROP FUNCTION fn_dias_protegidos(region_t, uuid, date, date);

DROP TRIGGER trg_habito_logro_intencion_ins ON habito;
CREATE TRIGGER trg_habito_logro_intencion_ins AFTER INSERT ON habito
    FOR EACH ROW WHEN (NEW.intencion IS NOT NULL) EXECUTE FUNCTION tg_habito_logro_intencion();

DROP TRIGGER trg_habito_0_recomendacion ON habito;
DROP FUNCTION tg_habito_recomendacion();
ALTER TABLE habito DROP COLUMN recomendacion_id;

DROP VIEW v_habito_recomendado;
DROP TABLE habito_recomendado;
DROP FUNCTION fn_fuentes_validas(text);
DROP TABLE fuente_cientifica;

COMMIT;
