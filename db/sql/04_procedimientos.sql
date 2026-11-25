-- =====================================================================
-- Kaizen · 04_procedimientos.sql
-- Procedimientos almacenados: las operaciones de escritura con más de
-- una tabla o con reglas de negocio entran por aquí. Son SECURITY
-- DEFINER: la API solo tiene EXECUTE, no DML sobre las tablas afectadas.
-- Toda operación recibe la región (viaja en el JWT) para que el
-- planificador lea solo el fragmento del usuario (partition pruning).
-- IA: asistido. Revisión: Jael Contreras.
-- =====================================================================
BEGIN;
SET search_path = kaizen, pg_temp;

-- ---------------------------------------------------------------------
-- P1. Registro de usuario: usuario + directorio en UNA transacción.
-- El correo queda único en todas las regiones sin pasos de compensación.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_registrar_usuario(
    p_id                 uuid,
    p_email_hmac         text,
    p_nombre             text,
    p_email              text,
    p_password_hash      text,
    p_pais               char(2),
    p_estado             text,
    p_consiente_senales  boolean,
    p_ip                 inet,
    INOUT p_region       text DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    p_region := fn_region(p_pais, p_estado);

    INSERT INTO usuario (id, region, nombre, email, password_hash, pais,
                         acepto_aviso_en, consentimiento_senales_en)
    VALUES (p_id, p_region, p_nombre, lower(p_email), p_password_hash, p_pais,
            now(), CASE WHEN p_consiente_senales THEN now() END);

    BEGIN
        INSERT INTO directorio_usuarios (email_hmac, usuario_id, region)
        VALUES (p_email_hmac, p_id, p_region);
    EXCEPTION WHEN unique_violation THEN
        -- mensaje genérico: no confirmar si un correo existe (enumeración)
        RAISE EXCEPTION 'No fue posible completar el registro' USING ERRCODE = 'KZ001';
    END;

    PERFORM fn_auditar(p_id, p_region::region_t, 'usuario.registro', NULL, 'exito', p_ip);
END;
$$;

-- ---------------------------------------------------------------------
-- P2. Check-in idempotente. Reenviar el mismo check-in (cola sin
-- conexión) no duplica: (region, habito_id, fecha) es único y el
-- último envío del día gana. La racha la recalcula el trigger T1.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_registrar_checkin(
    p_region    region_t,
    p_usuario   uuid,
    p_id        uuid,
    p_habito    uuid,
    p_fecha     date,
    p_cumplido  boolean,
    p_valor     numeric,
    p_origen    text,
    INOUT p_racha_actual integer DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    -- autorización por dueño (anti-IDOR): mismo error si no existe o no es suyo
    PERFORM 1 FROM habito
     WHERE region = p_region AND id = p_habito AND usuario_id = p_usuario;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hábito no encontrado' USING ERRCODE = 'KZ004';
    END IF;

    INSERT INTO registro (id, region, habito_id, usuario_id, fecha, cumplido, valor, origen)
    VALUES (p_id, p_region, p_habito, p_usuario, p_fecha, p_cumplido, p_valor, p_origen)
    ON CONFLICT (region, habito_id, fecha) DO UPDATE
       SET cumplido      = EXCLUDED.cumplido,
           valor         = EXCLUDED.valor,
           origen        = EXCLUDED.origen,
           registrado_en = now()
     WHERE (registro.cumplido, registro.valor, registro.origen)
           IS DISTINCT FROM (EXCLUDED.cumplido, EXCLUDED.valor, EXCLUDED.origen);

    SELECT racha_actual INTO p_racha_actual
      FROM racha WHERE region = p_region AND habito_id = p_habito;
END;
$$;

-- ---------------------------------------------------------------------
-- P3. Escalera Kaizen (F1): genera sugerencias para los hábitos con
-- 14 días de historia, sin sugerencia pendiente y sin cambio de nivel
-- en los últimos 14 días. >= 85 % sube 10 %; < 50 % baja 15 %.
-- Pensado para correr una vez al día (cron del Nodo L o de la API).
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_generar_sugerencias(
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
        SELECT h.region, h.id, h.meta,
               fn_cumplimiento(h.region, h.id, 14, p_hoy - 1) AS pct
          FROM habito h
          JOIN nivel_habito n ON n.region = h.region AND n.habito_id = h.id
                             AND n.vigente_hasta IS NULL
         WHERE h.activo
           AND (p_region IS NULL OR h.region = p_region)
           AND n.vigente_desde <= p_hoy - 14
           AND NOT EXISTS (SELECT 1 FROM sugerencia_ajuste s
                            WHERE s.region = h.region AND s.habito_id = h.id
                              AND s.estado = 'pendiente')
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

-- ---------------------------------------------------------------------
-- P4. Responder una sugerencia (F1). Aceptar abre un escalón nuevo; los
-- triggers T5 cierran el anterior y actualizan habito.meta.
-- FOR UPDATE evita que dos dispositivos respondan a la vez.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_responder_sugerencia(
    p_region     region_t,
    p_usuario    uuid,
    p_sugerencia uuid,
    p_aceptar    boolean)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    s       record;
    v_nivel integer;
BEGIN
    SELECT sa.* INTO s
      FROM sugerencia_ajuste sa
      JOIN habito h ON h.region = sa.region AND h.id = sa.habito_id
     WHERE sa.region = p_region AND sa.id = p_sugerencia AND h.usuario_id = p_usuario
       FOR UPDATE OF sa;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sugerencia no encontrada' USING ERRCODE = 'KZ004';
    END IF;
    IF s.estado <> 'pendiente' THEN
        RAISE EXCEPTION 'La sugerencia ya fue resuelta' USING ERRCODE = 'KZ005';
    END IF;

    UPDATE sugerencia_ajuste
       SET estado = CASE WHEN p_aceptar THEN 'aceptada' ELSE 'rechazada' END
     WHERE region = p_region AND id = p_sugerencia;

    IF p_aceptar THEN
        SELECT nivel INTO v_nivel FROM nivel_habito
         WHERE region = p_region AND habito_id = s.habito_id AND vigente_hasta IS NULL;
        INSERT INTO nivel_habito (region, habito_id, nivel, meta_valor, vigente_desde)
        VALUES (p_region, s.habito_id,
                CASE WHEN s.tipo = 'subir' THEN v_nivel + 1 ELSE greatest(v_nivel - 1, 1) END,
                s.meta_propuesta, current_date);
    END IF;

    PERFORM fn_auditar(p_usuario, p_region, 'escalera.' || CASE WHEN p_aceptar THEN 'aceptar' ELSE 'rechazar' END,
                       'sugerencia/' || p_sugerencia, 'exito');
END;
$$;

-- ---------------------------------------------------------------------
-- P5. Abrir una cápsula (F3). Devuelve el texto cifrado; el descifrado
-- ocurre en la API, que es la única que conoce la llave AES.
-- La API NO tiene SELECT sobre capsula.mensaje_cifrado: este
-- procedimiento es el único camino para obtenerlo.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_abrir_capsula(
    p_region   region_t,
    p_usuario  uuid,
    p_capsula  uuid,
    INOUT p_mensaje_cifrado bytea DEFAULT NULL,
    INOUT p_llave_version   smallint DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    UPDATE capsula SET estado = 'abierta'
     WHERE region = p_region AND id = p_capsula AND usuario_id = p_usuario
       AND estado = 'sellada';                  -- T7 valida la racha objetivo

    SELECT mensaje_cifrado, llave_version INTO p_mensaje_cifrado, p_llave_version
      FROM capsula
     WHERE region = p_region AND id = p_capsula AND usuario_id = p_usuario
       AND estado = 'abierta';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cápsula no encontrada' USING ERRCODE = 'KZ004';
    END IF;

    PERFORM fn_auditar(p_usuario, p_region, 'capsula.abrir', 'capsula/' || p_capsula, 'exito');
END;
$$;

-- ---------------------------------------------------------------------
-- P6. Cancelación de la cuenta (derecho ARCO de cancelación).
-- Borra el directorio y el usuario; las FK en cascada eliminan hábitos,
-- registros, rachas, niveles, sugerencias, señales, cápsulas y sesiones.
-- La bitácora conserva el evento sin datos personales.
-- La analítica seudonimizada en MongoDB se purga en el siguiente ciclo
-- del proceso de carga (lista de usuario_sdn a eliminar).
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_eliminar_cuenta(
    p_region  region_t,
    p_usuario uuid,
    p_ip      inet DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    DELETE FROM directorio_usuarios WHERE usuario_id = p_usuario AND region = p_region;
    DELETE FROM usuario WHERE region = p_region AND id = p_usuario;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario no encontrado' USING ERRCODE = 'KZ004';
    END IF;
    PERFORM fn_auditar(p_usuario, p_region, 'usuario.cancelacion', NULL, 'exito', p_ip);
END;
$$;

-- ---------------------------------------------------------------------
-- P7. Reconstrucción de rachas desde registro (verificación del dato
-- derivado y recuperación después de una carga con triggers apagados).
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_reconstruir_rachas(
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
           SET racha_actual = EXCLUDED.racha_actual,
               racha_maxima = EXCLUDED.racha_maxima,
               ultima_fecha = EXCLUDED.ultima_fecha,
               actualizada_en = now()
         WHERE (ra.racha_actual, ra.racha_maxima, ra.ultima_fecha)
               IS DISTINCT FROM (EXCLUDED.racha_actual, EXCLUDED.racha_maxima, EXCLUDED.ultima_fecha)
        RETURNING 1
    )
    SELECT count(*) INTO p_corregidas FROM upd;
END;
$$;

-- ---------------------------------------------------------------------
-- P8. Mantenimiento: crea la partición mensual de la bitácora.
-- Se agenda el día 20 de cada mes para el mes siguiente.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_crear_particion_bitacora(p_mes date)
LANGUAGE plpgsql
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_ini date := date_trunc('month', p_mes)::date;
    v_nom text := 'bitacora_' || to_char(v_ini, 'YYYY_MM');
BEGIN
    IF to_regclass('kaizen.' || v_nom) IS NULL THEN
        EXECUTE format('CREATE TABLE kaizen.%I PARTITION OF kaizen.bitacora_auditoria FOR VALUES FROM (%L) TO (%L)',
                       v_nom, v_ini, (v_ini + interval '1 month')::date);
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- P9. Oposición (ARCO): retirar el consentimiento de ánimo y energía.
-- Borra las señales guardadas; T8 impide registrar nuevas.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_retirar_consentimiento_senales(
    p_region  region_t,
    p_usuario uuid,
    INOUT p_borradas integer DEFAULT 0)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    UPDATE usuario SET consentimiento_senales_en = NULL
     WHERE region = p_region AND id = p_usuario;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario no encontrado' USING ERRCODE = 'KZ004';
    END IF;
    DELETE FROM senal_diaria WHERE region = p_region AND usuario_id = p_usuario;
    GET DIAGNOSTICS p_borradas = ROW_COUNT;
    PERFORM fn_auditar(p_usuario, p_region, 'usuario.oposicion_senales', p_borradas || ' señales', 'exito');
END;
$$;

COMMIT;
