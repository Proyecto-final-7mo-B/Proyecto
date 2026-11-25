-- =====================================================================
-- Kaizen · 03_triggers.sql
-- Triggers que protegen invariantes del negocio y de seguridad.
-- En PostgreSQL 13+ un trigger definido en la tabla particionada se
-- propaga a todas sus particiones (actuales y futuras).
-- Funciones SECURITY DEFINER: corren como kaizen_owner, con search_path
-- fijo, para que la API no necesite privilegios sobre tablas derivadas.
-- IA: asistido. Revisión: Jael Contreras.
-- =====================================================================
BEGIN;
SET search_path = kaizen, pg_temp;

-- =====================================================================
-- T1. registro -> racha (nivel sentencia, con tablas de transición)
-- Una carga masiva (COPY de 100 mil filas) recalcula cada hábito una
-- sola vez por sentencia, no una vez por fila.
-- =====================================================================
CREATE FUNCTION tg_registro_racha() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    INSERT INTO racha AS ra (region, habito_id, racha_actual, racha_maxima, ultima_fecha, actualizada_en)
    SELECT a.region, a.habito_id, c.racha_actual, c.racha_maxima, c.ultima_fecha, now()
      FROM (SELECT DISTINCT region, habito_id FROM cambios) a
      JOIN habito h ON h.region = a.region AND h.id = a.habito_id   -- ignora hábitos en borrado
      CROSS JOIN LATERAL fn_rachas(a.region, a.habito_id) c
    ON CONFLICT (region, habito_id) DO UPDATE
       SET racha_actual   = EXCLUDED.racha_actual,
           racha_maxima   = EXCLUDED.racha_maxima,
           ultima_fecha   = EXCLUDED.ultima_fecha,
           actualizada_en = EXCLUDED.actualizada_en;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_registro_racha_ins AFTER INSERT ON registro
    REFERENCING NEW TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION tg_registro_racha();
CREATE TRIGGER trg_registro_racha_upd AFTER UPDATE ON registro
    REFERENCING NEW TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION tg_registro_racha();
CREATE TRIGGER trg_registro_racha_del AFTER DELETE ON registro
    REFERENCING OLD TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION tg_registro_racha();

-- =====================================================================
-- T2. registro: validación de fecha y hábito activo (R6), por LOTE.
-- Primera versión: trigger por fila (BEFORE ... FOR EACH ROW) con una
-- consulta a habito por fila. Medido con 71 mil filas: +7.7 s (≈108 µs
-- por fila). Ahora valida todo el lote con un solo JOIN sobre la tabla
-- de transición; si una fila es inválida, la sentencia completa se
-- revierte. Los inmutables (UPDATE) se revisan por fila sin consultas.
-- =====================================================================
CREATE FUNCTION tg_registro_valida_lote() RETURNS trigger
LANGUAGE plpgsql
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    m record;
BEGIN
    SELECT c.fecha, h.activo, h.fecha_creacion::date AS creado INTO m
      FROM cambios c
      JOIN habito h ON h.region = c.region AND h.id = c.habito_id
     WHERE c.fecha > current_date + 1          -- +1 día por zonas horarias (UTC-8 a UTC-3)
        OR c.fecha < h.fecha_creacion::date - 1
        OR NOT h.activo
     LIMIT 1;
    IF FOUND THEN
        IF NOT m.activo THEN
            RAISE EXCEPTION 'El hábito está archivado' USING ERRCODE = 'KZ007';
        ELSIF m.fecha > current_date + 1 THEN
            RAISE EXCEPTION 'No se puede registrar una fecha futura (%)', m.fecha USING ERRCODE = 'KZ003';
        ELSE
            RAISE EXCEPTION 'La fecha % es anterior a la creación del hábito', m.fecha USING ERRCODE = 'KZ003';
        END IF;
    END IF;
    RETURN NULL;
END;
$$;

CREATE FUNCTION tg_registro_inmutables() RETURNS trigger
LANGUAGE plpgsql
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    IF (NEW.id, NEW.region, NEW.habito_id, NEW.usuario_id, NEW.fecha)
       IS DISTINCT FROM (OLD.id, OLD.region, OLD.habito_id, OLD.usuario_id, OLD.fecha) THEN
        RAISE EXCEPTION 'Solo cumplido, valor y origen de un registro pueden cambiar'
              USING ERRCODE = 'KZ006';
    END IF;
    RETURN NEW;
END;
$$;

-- Los triggers AFTER se disparan en orden alfabético: "trg_registro_a_*"
-- valida antes de que "trg_registro_racha_*" recalcule.
CREATE TRIGGER trg_registro_a_valida_ins AFTER INSERT ON registro
    REFERENCING NEW TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION tg_registro_valida_lote();
CREATE TRIGGER trg_registro_a_valida_upd AFTER UPDATE ON registro
    REFERENCING NEW TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION tg_registro_valida_lote();
CREATE TRIGGER trg_registro_inmutables BEFORE UPDATE ON registro
    FOR EACH ROW EXECUTE FUNCTION tg_registro_inmutables();

-- =====================================================================
-- T3. habito nuevo -> nivel 1 de la Escalera y racha en cero
-- =====================================================================
CREATE FUNCTION tg_habito_inicial() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    INSERT INTO nivel_habito (region, habito_id, nivel, meta_valor, vigente_desde)
    VALUES (NEW.region, NEW.id, 1, NEW.meta, NEW.fecha_creacion::date);
    INSERT INTO racha (region, habito_id) VALUES (NEW.region, NEW.id);
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_habito_inicial AFTER INSERT ON habito
    FOR EACH ROW EXECUTE FUNCTION tg_habito_inicial();

-- =====================================================================
-- T4. habito: región y dueño inmutables; la meta solo cambia por la
-- Escalera (un nivel nuevo), nunca con un UPDATE directo.
-- =====================================================================
CREATE FUNCTION tg_habito_guardia() RETURNS trigger
LANGUAGE plpgsql
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    IF (NEW.region, NEW.id, NEW.usuario_id, NEW.fecha_creacion)
       IS DISTINCT FROM (OLD.region, OLD.id, OLD.usuario_id, OLD.fecha_creacion) THEN
        RAISE EXCEPTION 'Región, dueño y fecha de creación del hábito son inmutables'
              USING ERRCODE = 'KZ006';
    END IF;
    IF NEW.meta IS DISTINCT FROM OLD.meta AND pg_trigger_depth() < 2 THEN
        RAISE EXCEPTION 'La meta solo cambia al aceptar una sugerencia de la Escalera'
              USING ERRCODE = 'KZ006';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_habito_guardia BEFORE UPDATE ON habito
    FOR EACH ROW EXECUTE FUNCTION tg_habito_guardia();

-- =====================================================================
-- T5. nivel_habito: al abrir un escalón se cierra el anterior y se
-- sincroniza habito.meta (desnormalización controlada).
-- =====================================================================
CREATE FUNCTION tg_nivel_cierra_anterior() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    UPDATE nivel_habito
       SET vigente_hasta = NEW.vigente_desde
     WHERE region = NEW.region AND habito_id = NEW.habito_id AND vigente_hasta IS NULL;
    RETURN NEW;
END;
$$;

CREATE FUNCTION tg_nivel_sincroniza_meta() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    UPDATE habito SET meta = NEW.meta_valor
     WHERE region = NEW.region AND id = NEW.habito_id AND meta IS DISTINCT FROM NEW.meta_valor;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_nivel_cierra_anterior BEFORE INSERT ON nivel_habito
    FOR EACH ROW EXECUTE FUNCTION tg_nivel_cierra_anterior();
CREATE TRIGGER trg_nivel_sincroniza_meta AFTER INSERT ON nivel_habito
    FOR EACH ROW EXECUTE FUNCTION tg_nivel_sincroniza_meta();

-- =====================================================================
-- T6. usuario: la región (shard key) y el id son inmutables
-- =====================================================================
CREATE FUNCTION tg_usuario_guardia() RETURNS trigger
LANGUAGE plpgsql
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    IF (NEW.region, NEW.id) IS DISTINCT FROM (OLD.region, OLD.id) THEN
        RAISE EXCEPTION 'La región de un usuario no puede cambiar (moverlo de fragmento es una migración)'
              USING ERRCODE = 'KZ006';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_usuario_guardia BEFORE UPDATE ON usuario
    FOR EACH ROW EXECUTE FUNCTION tg_usuario_guardia();

-- =====================================================================
-- T7. capsula: sellado inviolable; se abre solo con la racha objetivo
-- alcanzada DESPUÉS de sellarla (R6 y F3).
-- =====================================================================
CREATE FUNCTION tg_capsula_guardia() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_max integer;
BEGIN
    IF TG_OP = 'INSERT' THEN                  -- toda cápsula nace sellada
        NEW.estado := 'sellada';
        NEW.abierta_en := NULL;
        RETURN NEW;
    END IF;

    IF (NEW.id, NEW.region, NEW.habito_id, NEW.usuario_id, NEW.racha_objetivo, NEW.creada_en, NEW.tiene_foto)
       IS DISTINCT FROM
       (OLD.id, OLD.region, OLD.habito_id, OLD.usuario_id, OLD.racha_objetivo, OLD.creada_en, OLD.tiene_foto) THEN
        RAISE EXCEPTION 'Una cápsula sellada no se puede modificar' USING ERRCODE = 'KZ006';
    END IF;
    -- el mensaje solo cambia al recifrarlo con una versión de llave más nueva (rotación)
    IF NEW.mensaje_cifrado IS DISTINCT FROM OLD.mensaje_cifrado
       AND NEW.llave_version <= OLD.llave_version THEN
        RAISE EXCEPTION 'El mensaje solo cambia al rotar la llave' USING ERRCODE = 'KZ006';
    END IF;

    IF OLD.estado = 'abierta' AND NEW.estado = 'sellada' THEN
        RAISE EXCEPTION 'Una cápsula abierta no se vuelve a sellar' USING ERRCODE = 'KZ006';
    END IF;

    IF OLD.estado = 'sellada' AND NEW.estado = 'abierta' THEN
        SELECT racha_maxima INTO v_max
          FROM fn_rachas(NEW.region, NEW.habito_id, OLD.creada_en::date);
        IF v_max < OLD.racha_objetivo THEN
            RAISE EXCEPTION 'Cápsula sellada: racha % de %', v_max, OLD.racha_objetivo
                  USING ERRCODE = 'KZ005';
        END IF;
        NEW.abierta_en := now();
    ELSIF NEW.estado = 'sellada' THEN
        NEW.abierta_en := NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_capsula_guardia BEFORE INSERT OR UPDATE ON capsula
    FOR EACH ROW EXECUTE FUNCTION tg_capsula_guardia();

-- =====================================================================
-- T8. senal_diaria: sin consentimiento expreso no hay datos de ánimo
-- (LFPDPPP: datos que pueden ser sensibles por relacionarse con salud)
-- =====================================================================
CREATE FUNCTION tg_senal_consentimiento() RETURNS trigger
LANGUAGE plpgsql
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuario
                    WHERE region = NEW.region AND id = NEW.usuario_id
                      AND consentimiento_senales_en IS NOT NULL) THEN
        RAISE EXCEPTION 'El usuario no ha dado su consentimiento para registrar ánimo y energía'
              USING ERRCODE = 'KZ008';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_senal_consentimiento BEFORE INSERT OR UPDATE ON senal_diaria
    FOR EACH ROW EXECUTE FUNCTION tg_senal_consentimiento();

-- =====================================================================
-- T9. sugerencia_ajuste: máquina de estados (pendiente -> final)
-- =====================================================================
CREATE FUNCTION tg_sugerencia_estado() RETURNS trigger
LANGUAGE plpgsql
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    IF OLD.estado <> 'pendiente' THEN
        RAISE EXCEPTION 'La sugerencia ya fue resuelta (%)', OLD.estado USING ERRCODE = 'KZ006';
    END IF;
    IF (NEW.tipo, NEW.meta_actual, NEW.meta_propuesta, NEW.cumplimiento_14d, NEW.habito_id)
       IS DISTINCT FROM (OLD.tipo, OLD.meta_actual, OLD.meta_propuesta, OLD.cumplimiento_14d, OLD.habito_id) THEN
        RAISE EXCEPTION 'Solo el estado de una sugerencia puede cambiar' USING ERRCODE = 'KZ006';
    END IF;
    IF NEW.estado <> 'pendiente' THEN
        NEW.resuelta_en := now();
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sugerencia_estado BEFORE UPDATE ON sugerencia_ajuste
    FOR EACH ROW EXECUTE FUNCTION tg_sugerencia_estado();

-- =====================================================================
-- T10. bitacora_auditoria: solo inserción (R12). Se complementa con
-- REVOKE UPDATE, DELETE, TRUNCATE en 06_roles.sql.
-- =====================================================================
CREATE FUNCTION tg_bitacora_inmutable() RETURNS trigger
LANGUAGE plpgsql
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    RAISE EXCEPTION 'La bitácora de auditoría es de solo inserción (% bloqueado)', TG_OP
          USING ERRCODE = 'KZ009';
END;
$$;

CREATE TRIGGER trg_bitacora_inmutable BEFORE UPDATE OR DELETE ON bitacora_auditoria
    FOR EACH ROW EXECUTE FUNCTION tg_bitacora_inmutable();
CREATE TRIGGER trg_bitacora_sin_truncate BEFORE TRUNCATE ON bitacora_auditoria
    FOR EACH STATEMENT EXECUTE FUNCTION tg_bitacora_inmutable();

COMMIT;
