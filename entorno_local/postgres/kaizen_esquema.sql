--
-- PostgreSQL database dump
--

\restrict eBwfBdU1l3IqW8efDF2vKBD29BS9Wc4dlzPP1Uq4Lp0iuYadKCg1SjEIDJ3IPa0

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: kaizen; Type: SCHEMA; Schema: -; Owner: kaizen_owner
--

CREATE SCHEMA kaizen;


ALTER SCHEMA kaizen OWNER TO kaizen_owner;

--
-- Name: escala_1_5; Type: DOMAIN; Schema: kaizen; Owner: kaizen_owner
--

CREATE DOMAIN kaizen.escala_1_5 AS smallint
	CONSTRAINT escala_1_5_check CHECK (((VALUE >= 1) AND (VALUE <= 5)));


ALTER DOMAIN kaizen.escala_1_5 OWNER TO kaizen_owner;

--
-- Name: hmac_hex; Type: DOMAIN; Schema: kaizen; Owner: kaizen_owner
--

CREATE DOMAIN kaizen.hmac_hex AS text
	CONSTRAINT hmac_hex_check CHECK ((VALUE ~ '^[0-9a-f]{64}$'::text));


ALTER DOMAIN kaizen.hmac_hex OWNER TO kaizen_owner;

--
-- Name: region_t; Type: DOMAIN; Schema: kaizen; Owner: kaizen_owner
--

CREATE DOMAIN kaizen.region_t AS text
	CONSTRAINT region_t_check CHECK ((VALUE = ANY (ARRAY['MX-NORTE'::text, 'MX-CENTRO-SUR'::text, 'LATAM'::text])));


ALTER DOMAIN kaizen.region_t OWNER TO kaizen_owner;

--
-- Name: fn_auditar(uuid, kaizen.region_t, text, text, text, inet); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.fn_auditar(p_usuario uuid, p_region kaizen.region_t, p_accion text, p_recurso text, p_resultado text, p_ip inet DEFAULT NULL::inet) RETURNS void
    LANGUAGE sql
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
    INSERT INTO bitacora_auditoria (usuario_id, region, accion, recurso, resultado, ip)
    VALUES (p_usuario, p_region, p_accion, p_recurso, p_resultado, p_ip);
$$;


ALTER FUNCTION kaizen.fn_auditar(p_usuario uuid, p_region kaizen.region_t, p_accion text, p_recurso text, p_resultado text, p_ip inet) OWNER TO kaizen_owner;

--
-- Name: fn_cumplimiento(kaizen.region_t, uuid, integer, date); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.fn_cumplimiento(p_region kaizen.region_t, p_habito uuid, p_dias integer DEFAULT 14, p_hasta date DEFAULT CURRENT_DATE) RETURNS numeric
    LANGUAGE plpgsql STABLE
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.fn_cumplimiento(p_region kaizen.region_t, p_habito uuid, p_dias integer, p_hasta date) OWNER TO kaizen_owner;

--
-- Name: fn_dia_programado(text, smallint, date); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.fn_dia_programado(p_tipo text, p_dias smallint, p_fecha date) RETURNS boolean
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
    SELECT CASE p_tipo
        WHEN 'diaria'       THEN true
        WHEN 'dias_semana'  THEN (p_dias & (1 << (extract(isodow FROM p_fecha)::int - 1))) <> 0
        ELSE false
    END;
$$;


ALTER FUNCTION kaizen.fn_dia_programado(p_tipo text, p_dias smallint, p_fecha date) OWNER TO kaizen_owner;

--
-- Name: fn_dia_programado_anterior(text, smallint, date); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.fn_dia_programado_anterior(p_tipo text, p_dias smallint, p_fecha date) RETURNS date
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
    SELECT max(p_fecha - k)
      FROM generate_series(1, 7) AS k
     WHERE fn_dia_programado(p_tipo, p_dias, p_fecha - k);
$$;


ALTER FUNCTION kaizen.fn_dia_programado_anterior(p_tipo text, p_dias smallint, p_fecha date) OWNER TO kaizen_owner;

--
-- Name: fn_rachas(kaizen.region_t, uuid, date); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.fn_rachas(p_region kaizen.region_t, p_habito uuid, p_desde date DEFAULT NULL::date, OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date) RETURNS record
    LANGUAGE plpgsql STABLE
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.fn_rachas(p_region kaizen.region_t, p_habito uuid, p_desde date, OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date) OWNER TO kaizen_owner;

--
-- Name: fn_region(character, text); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.fn_region(p_pais character, p_estado text DEFAULT NULL::text) RETURNS kaizen.region_t
    LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.fn_region(p_pais character, p_estado text) OWNER TO kaizen_owner;

--
-- Name: fn_usuario_actual(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.fn_usuario_actual() RETURNS uuid
    LANGUAGE sql STABLE PARALLEL SAFE
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$ SELECT nullif(current_setting('kaizen.usuario_id', true), '')::uuid $$;


ALTER FUNCTION kaizen.fn_usuario_actual() OWNER TO kaizen_owner;

--
-- Name: fn_verificar_admin(uuid); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.fn_verificar_admin(p_admin uuid) RETURNS kaizen.region_t
    LANGUAGE plpgsql STABLE
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
DECLARE
    v_region region_t;
BEGIN
    SELECT u.region INTO v_region
      FROM directorio_usuarios d
      JOIN usuario u ON u.region = d.region AND u.id = d.usuario_id
     WHERE d.usuario_id = p_admin AND u.rol = 'admin' AND u.suspendido_en IS NULL;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Se requiere el rol de administrador' USING ERRCODE = 'KZ010';
    END IF;
    RETURN v_region;
END;
$$;


ALTER FUNCTION kaizen.fn_verificar_admin(p_admin uuid) OWNER TO kaizen_owner;

--
-- Name: sp_abrir_capsula(kaizen.region_t, uuid, uuid, bytea, smallint); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_abrir_capsula(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_capsula uuid, INOUT p_mensaje_cifrado bytea DEFAULT NULL::bytea, INOUT p_llave_version smallint DEFAULT NULL::smallint)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_abrir_capsula(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_capsula uuid, INOUT p_mensaje_cifrado bytea, INOUT p_llave_version smallint) OWNER TO kaizen_owner;

--
-- Name: sp_admin_actualizar_categoria(uuid, uuid, text, boolean, inet); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_admin_actualizar_categoria(IN p_admin uuid, IN p_id uuid, IN p_nombre text DEFAULT NULL::text, IN p_activa boolean DEFAULT NULL::boolean, IN p_ip inet DEFAULT NULL::inet)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
DECLARE
    v_region_admin region_t := fn_verificar_admin(p_admin);
BEGIN
    IF p_nombre IS NOT NULL AND length(btrim(p_nombre)) NOT BETWEEN 2 AND 40 THEN
        RAISE EXCEPTION 'El nombre debe tener de 2 a 40 caracteres' USING ERRCODE = 'KZ011';
    END IF;
    BEGIN
        UPDATE categoria
           SET nombre = coalesce(btrim(p_nombre), nombre),
               activa = coalesce(p_activa, activa)
         WHERE id = p_id;
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una categoría con ese nombre' USING ERRCODE = 'KZ013';
    END;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Categoría no encontrada' USING ERRCODE = 'KZ004';
    END IF;
    PERFORM fn_auditar(p_admin, v_region_admin, 'admin.categoria_editar', 'categoria/' || p_id, 'exito', p_ip);
END;
$$;


ALTER PROCEDURE kaizen.sp_admin_actualizar_categoria(IN p_admin uuid, IN p_id uuid, IN p_nombre text, IN p_activa boolean, IN p_ip inet) OWNER TO kaizen_owner;

--
-- Name: sp_admin_crear_categoria(uuid, text, inet, uuid); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_admin_crear_categoria(IN p_admin uuid, IN p_nombre text, IN p_ip inet DEFAULT NULL::inet, INOUT p_id uuid DEFAULT NULL::uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_admin_crear_categoria(IN p_admin uuid, IN p_nombre text, IN p_ip inet, INOUT p_id uuid) OWNER TO kaizen_owner;

--
-- Name: sp_admin_suspender_usuario(uuid, uuid, boolean, text, inet); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_admin_suspender_usuario(IN p_admin uuid, IN p_usuario uuid, IN p_suspender boolean, IN p_motivo text DEFAULT NULL::text, IN p_ip inet DEFAULT NULL::inet)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
DECLARE
    v_region_admin region_t := fn_verificar_admin(p_admin);
    v_region       region_t;
    v_rol          text;
BEGIN
    IF p_usuario = p_admin THEN
        RAISE EXCEPTION 'Un administrador no puede suspender su propia cuenta' USING ERRCODE = 'KZ010';
    END IF;

    SELECT u.region, u.rol INTO v_region, v_rol
      FROM directorio_usuarios d
      JOIN usuario u ON u.region = d.region AND u.id = d.usuario_id
     WHERE d.usuario_id = p_usuario
       FOR UPDATE OF u;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario no encontrado' USING ERRCODE = 'KZ004';
    END IF;
    IF v_rol = 'admin' THEN
        RAISE EXCEPTION 'A un administrador solo lo suspende el DBA' USING ERRCODE = 'KZ010';
    END IF;

    IF p_suspender THEN
        IF p_motivo IS NULL OR length(btrim(p_motivo)) NOT BETWEEN 3 AND 200 THEN
            RAISE EXCEPTION 'El motivo es obligatorio (3 a 200 caracteres)' USING ERRCODE = 'KZ011';
        END IF;
        UPDATE usuario SET suspendido_en = now(), suspension_motivo = btrim(p_motivo)
         WHERE region = v_region AND id = p_usuario AND suspendido_en IS NULL;
        UPDATE sesion SET revocada_en = now()                       -- cierra todas sus sesiones
         WHERE region = v_region AND usuario_id = p_usuario AND revocada_en IS NULL;
    ELSE
        UPDATE usuario SET suspendido_en = NULL, suspension_motivo = NULL
         WHERE region = v_region AND id = p_usuario;
    END IF;

    PERFORM fn_auditar(p_admin, v_region_admin,
                       CASE WHEN p_suspender THEN 'admin.suspender' ELSE 'admin.reactivar' END,
                       'usuario/' || p_usuario, 'exito', p_ip);
END;
$$;


ALTER PROCEDURE kaizen.sp_admin_suspender_usuario(IN p_admin uuid, IN p_usuario uuid, IN p_suspender boolean, IN p_motivo text, IN p_ip inet) OWNER TO kaizen_owner;

--
-- Name: sp_crear_particion_bitacora(date); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_crear_particion_bitacora(IN p_mes date)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_crear_particion_bitacora(IN p_mes date) OWNER TO kaizen_owner;

--
-- Name: sp_eliminar_cuenta(kaizen.region_t, uuid, inet); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_eliminar_cuenta(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_ip inet DEFAULT NULL::inet)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_eliminar_cuenta(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_ip inet) OWNER TO kaizen_owner;

--
-- Name: sp_generar_sugerencias(kaizen.region_t, date, integer); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_generar_sugerencias(IN p_region kaizen.region_t DEFAULT NULL::text, IN p_hoy date DEFAULT CURRENT_DATE, INOUT p_creadas integer DEFAULT 0)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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
           AND h.escalera_activa
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


ALTER PROCEDURE kaizen.sp_generar_sugerencias(IN p_region kaizen.region_t, IN p_hoy date, INOUT p_creadas integer) OWNER TO kaizen_owner;

--
-- Name: sp_limpiar_expirados(integer, integer); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_limpiar_expirados(INOUT p_sesiones integer DEFAULT 0, INOUT p_tokens integer DEFAULT 0)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    -- Un token de renovación vencido ya no sirve, así que su fila tampoco
    -- hace falta para detectar reuso (la detección solo importa mientras es válido).
    DELETE FROM sesion WHERE expira_en < now();
    GET DIAGNOSTICS p_sesiones = ROW_COUNT;
    -- Se conserva 1 día para el límite de 3 solicitudes por hora
    DELETE FROM recuperacion_contrasena WHERE expira_en < now() - interval '1 day';
    GET DIAGNOSTICS p_tokens = ROW_COUNT;
    PERFORM fn_auditar(NULL, NULL, 'tareas.limpieza', p_sesiones || ' sesiones, ' || p_tokens || ' tokens', 'exito');
END;
$$;


ALTER PROCEDURE kaizen.sp_limpiar_expirados(INOUT p_sesiones integer, INOUT p_tokens integer) OWNER TO kaizen_owner;

--
-- Name: sp_reconstruir_rachas(kaizen.region_t, integer); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_reconstruir_rachas(IN p_region kaizen.region_t DEFAULT NULL::text, INOUT p_corregidas integer DEFAULT 0)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_reconstruir_rachas(IN p_region kaizen.region_t, INOUT p_corregidas integer) OWNER TO kaizen_owner;

--
-- Name: sp_registrar_checkin(kaizen.region_t, uuid, uuid, uuid, date, boolean, numeric, text, integer); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_registrar_checkin(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_id uuid, IN p_habito uuid, IN p_fecha date, IN p_cumplido boolean, IN p_valor numeric, IN p_origen text, INOUT p_racha_actual integer DEFAULT NULL::integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_registrar_checkin(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_id uuid, IN p_habito uuid, IN p_fecha date, IN p_cumplido boolean, IN p_valor numeric, IN p_origen text, INOUT p_racha_actual integer) OWNER TO kaizen_owner;

--
-- Name: sp_registrar_usuario(uuid, text, text, text, text, character, text, boolean, inet, text); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_registrar_usuario(IN p_id uuid, IN p_email_hmac text, IN p_nombre text, IN p_email text, IN p_password_hash text, IN p_pais character, IN p_estado text, IN p_consiente_senales boolean, IN p_ip inet, INOUT p_region text DEFAULT NULL::text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_registrar_usuario(IN p_id uuid, IN p_email_hmac text, IN p_nombre text, IN p_email text, IN p_password_hash text, IN p_pais character, IN p_estado text, IN p_consiente_senales boolean, IN p_ip inet, INOUT p_region text) OWNER TO kaizen_owner;

--
-- Name: sp_responder_sugerencia(kaizen.region_t, uuid, uuid, boolean); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_responder_sugerencia(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_sugerencia uuid, IN p_aceptar boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_responder_sugerencia(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_sugerencia uuid, IN p_aceptar boolean) OWNER TO kaizen_owner;

--
-- Name: sp_restablecer_contrasena(text, text, inet); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_restablecer_contrasena(IN p_token_hash text, IN p_password_hash text, IN p_ip inet DEFAULT NULL::inet)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
DECLARE
    v record;
BEGIN
    SELECT r.region, r.usuario_id INTO v
      FROM recuperacion_contrasena r
      JOIN usuario u ON u.region = r.region AND u.id = r.usuario_id
     WHERE r.token_hash = p_token_hash AND r.usado_en IS NULL AND r.expira_en > now()
       AND u.suspendido_en IS NULL
       FOR UPDATE OF r;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'El enlace no es válido o ya venció' USING ERRCODE = 'KZ015';
    END IF;

    UPDATE usuario SET password_hash = p_password_hash, intentos_fallidos = 0, bloqueado_hasta = NULL
     WHERE region = v.region AND id = v.usuario_id;
    UPDATE recuperacion_contrasena SET usado_en = now() WHERE token_hash = p_token_hash;
    UPDATE sesion SET revocada_en = now()                            -- cierra todas las sesiones
     WHERE region = v.region AND usuario_id = v.usuario_id AND revocada_en IS NULL;
    PERFORM fn_auditar(v.usuario_id, v.region, 'auth.restablecer', NULL, 'exito', p_ip);
END;
$$;


ALTER PROCEDURE kaizen.sp_restablecer_contrasena(IN p_token_hash text, IN p_password_hash text, IN p_ip inet) OWNER TO kaizen_owner;

--
-- Name: sp_retirar_consentimiento_senales(kaizen.region_t, uuid, integer); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_retirar_consentimiento_senales(IN p_region kaizen.region_t, IN p_usuario uuid, INOUT p_borradas integer DEFAULT 0)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER PROCEDURE kaizen.sp_retirar_consentimiento_senales(IN p_region kaizen.region_t, IN p_usuario uuid, INOUT p_borradas integer) OWNER TO kaizen_owner;

--
-- Name: sp_solicitar_recuperacion(text, text, inet, boolean, text); Type: PROCEDURE; Schema: kaizen; Owner: kaizen_owner
--

CREATE PROCEDURE kaizen.sp_solicitar_recuperacion(IN p_email_hmac text, IN p_token_hash text, IN p_ip inet DEFAULT NULL::inet, INOUT p_enviar boolean DEFAULT NULL::boolean, INOUT p_nombre text DEFAULT NULL::text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
DECLARE
    v record;
BEGIN
    p_enviar := false;                 -- la API responde 202 siempre; solo envía el correo si es true
    SELECT u.region, u.id, u.nombre, u.suspendido_en INTO v
      FROM directorio_usuarios d
      JOIN usuario u ON u.region = d.region AND u.id = d.usuario_id
     WHERE d.email_hmac = p_email_hmac;
    IF NOT FOUND OR v.suspendido_en IS NOT NULL THEN
        PERFORM fn_auditar(NULL, NULL, 'auth.recuperar', NULL, 'fallo', p_ip);
        RETURN;
    END IF;

    DELETE FROM recuperacion_contrasena                -- limpieza de tokens viejos de esta cuenta
     WHERE region = v.region AND usuario_id = v.id AND expira_en < now() - interval '1 day';

    IF (SELECT count(*) FROM recuperacion_contrasena
         WHERE region = v.region AND usuario_id = v.id AND creada_en > now() - interval '1 hour') >= 3 THEN
        PERFORM fn_auditar(v.id, v.region, 'auth.recuperar', 'limite', 'denegado', p_ip);
        RETURN;
    END IF;

    UPDATE recuperacion_contrasena SET usado_en = now()          -- solo vale el enlace más reciente
     WHERE region = v.region AND usuario_id = v.id AND usado_en IS NULL;
    INSERT INTO recuperacion_contrasena (token_hash, region, usuario_id, expira_en, ip)
    VALUES (p_token_hash, v.region, v.id, now() + interval '15 minutes', p_ip);

    p_enviar := true;
    p_nombre := v.nombre;
    PERFORM fn_auditar(v.id, v.region, 'auth.recuperar', NULL, 'exito', p_ip);
END;
$$;


ALTER PROCEDURE kaizen.sp_solicitar_recuperacion(IN p_email_hmac text, IN p_token_hash text, IN p_ip inet, INOUT p_enviar boolean, INOUT p_nombre text) OWNER TO kaizen_owner;

--
-- Name: tg_bitacora_inmutable(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_bitacora_inmutable() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    RAISE EXCEPTION 'La bitácora de auditoría es de solo inserción (% bloqueado)', TG_OP
          USING ERRCODE = 'KZ009';
END;
$$;


ALTER FUNCTION kaizen.tg_bitacora_inmutable() OWNER TO kaizen_owner;

--
-- Name: tg_capsula_guardia(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_capsula_guardia() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.tg_capsula_guardia() OWNER TO kaizen_owner;

--
-- Name: tg_habito_categoria_activa(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_habito_categoria_activa() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.categoria_id = OLD.categoria_id THEN
        RETURN NEW;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND activa) THEN
        RAISE EXCEPTION 'La categoría no está disponible' USING ERRCODE = 'KZ014';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION kaizen.tg_habito_categoria_activa() OWNER TO kaizen_owner;

--
-- Name: tg_habito_expira_sugerencias(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_habito_expira_sugerencias() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    UPDATE sugerencia_ajuste SET estado = 'expirada'
     WHERE region = NEW.region AND habito_id = NEW.id AND estado = 'pendiente';
    RETURN NULL;
END;
$$;


ALTER FUNCTION kaizen.tg_habito_expira_sugerencias() OWNER TO kaizen_owner;

--
-- Name: tg_habito_guardia(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_habito_guardia() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.tg_habito_guardia() OWNER TO kaizen_owner;

--
-- Name: tg_habito_inicial(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_habito_inicial() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    INSERT INTO nivel_habito (region, habito_id, nivel, meta_valor, vigente_desde)
    VALUES (NEW.region, NEW.id, 1, NEW.meta, NEW.fecha_creacion::date);
    INSERT INTO racha (region, habito_id) VALUES (NEW.region, NEW.id);
    RETURN NULL;
END;
$$;


ALTER FUNCTION kaizen.tg_habito_inicial() OWNER TO kaizen_owner;

--
-- Name: tg_nivel_cierra_anterior(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_nivel_cierra_anterior() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    UPDATE nivel_habito
       SET vigente_hasta = NEW.vigente_desde
     WHERE region = NEW.region AND habito_id = NEW.habito_id AND vigente_hasta IS NULL;
    RETURN NEW;
END;
$$;


ALTER FUNCTION kaizen.tg_nivel_cierra_anterior() OWNER TO kaizen_owner;

--
-- Name: tg_nivel_sincroniza_meta(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_nivel_sincroniza_meta() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    UPDATE habito SET meta = NEW.meta_valor
     WHERE region = NEW.region AND id = NEW.habito_id AND meta IS DISTINCT FROM NEW.meta_valor;
    RETURN NULL;
END;
$$;


ALTER FUNCTION kaizen.tg_nivel_sincroniza_meta() OWNER TO kaizen_owner;

--
-- Name: tg_registro_inmutables(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_registro_inmutables() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.tg_registro_inmutables() OWNER TO kaizen_owner;

--
-- Name: tg_registro_racha(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_registro_racha() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.tg_registro_racha() OWNER TO kaizen_owner;

--
-- Name: tg_registro_valida_lote(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_registro_valida_lote() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.tg_registro_valida_lote() OWNER TO kaizen_owner;

--
-- Name: tg_senal_consentimiento(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_senal_consentimiento() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.tg_senal_consentimiento() OWNER TO kaizen_owner;

--
-- Name: tg_sesion_cuenta_activa(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_sesion_cuenta_activa() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM usuario
                WHERE region = NEW.region AND id = NEW.usuario_id AND suspendido_en IS NOT NULL) THEN
        RAISE EXCEPTION 'La cuenta está suspendida' USING ERRCODE = 'KZ012';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION kaizen.tg_sesion_cuenta_activa() OWNER TO kaizen_owner;

--
-- Name: tg_sugerencia_estado(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_sugerencia_estado() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'kaizen', 'pg_temp'
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


ALTER FUNCTION kaizen.tg_sugerencia_estado() OWNER TO kaizen_owner;

--
-- Name: tg_usuario_guardia(); Type: FUNCTION; Schema: kaizen; Owner: kaizen_owner
--

CREATE FUNCTION kaizen.tg_usuario_guardia() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'kaizen', 'pg_temp'
    AS $$
BEGIN
    IF (NEW.region, NEW.id) IS DISTINCT FROM (OLD.region, OLD.id) THEN
        RAISE EXCEPTION 'La región de un usuario no puede cambiar (moverlo de fragmento es una migración)'
              USING ERRCODE = 'KZ006';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION kaizen.tg_usuario_guardia() OWNER TO kaizen_owner;

SET default_tablespace = '';

--
-- Name: bitacora_auditoria; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_auditoria (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
)
PARTITION BY RANGE (fecha);


ALTER TABLE kaizen.bitacora_auditoria OWNER TO kaizen_owner;

SET default_table_access_method = heap;

--
-- Name: bitacora_2026_11; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_2026_11 (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_2026_11 OWNER TO kaizen_owner;

--
-- Name: bitacora_2026_12; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_2026_12 (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_2026_12 OWNER TO kaizen_owner;

--
-- Name: bitacora_2027_01; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_2027_01 (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_2027_01 OWNER TO kaizen_owner;

--
-- Name: bitacora_2027_02; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_2027_02 (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_2027_02 OWNER TO kaizen_owner;

--
-- Name: bitacora_2027_03; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_2027_03 (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_2027_03 OWNER TO kaizen_owner;

--
-- Name: bitacora_2027_04; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_2027_04 (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_2027_04 OWNER TO kaizen_owner;

--
-- Name: bitacora_2027_05; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_2027_05 (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_2027_05 OWNER TO kaizen_owner;

--
-- Name: bitacora_2027_06; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_2027_06 (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_2027_06 OWNER TO kaizen_owner;

--
-- Name: bitacora_auditoria_id_seq; Type: SEQUENCE; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.bitacora_auditoria ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME kaizen.bitacora_auditoria_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: bitacora_default; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.bitacora_default (
    id bigint NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    usuario_id uuid,
    region kaizen.region_t,
    accion text NOT NULL,
    recurso text,
    resultado text NOT NULL,
    ip inet,
    CONSTRAINT bitacora_auditoria_accion_check CHECK ((accion ~ '^[a-z_.]{3,40}$'::text)),
    CONSTRAINT bitacora_auditoria_recurso_check CHECK ((length(recurso) <= 120)),
    CONSTRAINT bitacora_auditoria_resultado_check CHECK ((resultado = ANY (ARRAY['exito'::text, 'fallo'::text, 'denegado'::text])))
);


ALTER TABLE kaizen.bitacora_default OWNER TO kaizen_owner;

--
-- Name: capsula; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.capsula (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    mensaje_cifrado bytea NOT NULL,
    llave_version smallint DEFAULT 1 NOT NULL,
    tiene_foto boolean DEFAULT false NOT NULL,
    racha_objetivo integer NOT NULL,
    estado text DEFAULT 'sellada'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    abierta_en timestamp with time zone,
    CONSTRAINT capsula_check CHECK (((estado = 'abierta'::text) = (abierta_en IS NOT NULL))),
    CONSTRAINT capsula_estado_check CHECK ((estado = ANY (ARRAY['sellada'::text, 'abierta'::text]))),
    CONSTRAINT capsula_llave_version_check CHECK ((llave_version >= 1)),
    CONSTRAINT capsula_mensaje_cifrado_check CHECK (((octet_length(mensaje_cifrado) >= 29) AND (octet_length(mensaje_cifrado) <= 4124))),
    CONSTRAINT capsula_racha_objetivo_check CHECK ((racha_objetivo = ANY (ARRAY[7, 21, 66])))
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.capsula OWNER TO kaizen_owner;

--
-- Name: COLUMN capsula.mensaje_cifrado; Type: COMMENT; Schema: kaizen; Owner: kaizen_owner
--

COMMENT ON COLUMN kaizen.capsula.mensaje_cifrado IS 'AES-256-GCM: nonce(12) || cifrado || tag(16). La llave vive fuera de la BD.';


--
-- Name: capsula_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.capsula_latam (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    mensaje_cifrado bytea NOT NULL,
    llave_version smallint DEFAULT 1 NOT NULL,
    tiene_foto boolean DEFAULT false NOT NULL,
    racha_objetivo integer NOT NULL,
    estado text DEFAULT 'sellada'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    abierta_en timestamp with time zone,
    CONSTRAINT capsula_check CHECK (((estado = 'abierta'::text) = (abierta_en IS NOT NULL))),
    CONSTRAINT capsula_estado_check CHECK ((estado = ANY (ARRAY['sellada'::text, 'abierta'::text]))),
    CONSTRAINT capsula_llave_version_check CHECK ((llave_version >= 1)),
    CONSTRAINT capsula_mensaje_cifrado_check CHECK (((octet_length(mensaje_cifrado) >= 29) AND (octet_length(mensaje_cifrado) <= 4124))),
    CONSTRAINT capsula_racha_objetivo_check CHECK ((racha_objetivo = ANY (ARRAY[7, 21, 66])))
);


ALTER TABLE kaizen.capsula_latam OWNER TO kaizen_owner;

--
-- Name: capsula_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.capsula_mx_centro_sur (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    mensaje_cifrado bytea NOT NULL,
    llave_version smallint DEFAULT 1 NOT NULL,
    tiene_foto boolean DEFAULT false NOT NULL,
    racha_objetivo integer NOT NULL,
    estado text DEFAULT 'sellada'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    abierta_en timestamp with time zone,
    CONSTRAINT capsula_check CHECK (((estado = 'abierta'::text) = (abierta_en IS NOT NULL))),
    CONSTRAINT capsula_estado_check CHECK ((estado = ANY (ARRAY['sellada'::text, 'abierta'::text]))),
    CONSTRAINT capsula_llave_version_check CHECK ((llave_version >= 1)),
    CONSTRAINT capsula_mensaje_cifrado_check CHECK (((octet_length(mensaje_cifrado) >= 29) AND (octet_length(mensaje_cifrado) <= 4124))),
    CONSTRAINT capsula_racha_objetivo_check CHECK ((racha_objetivo = ANY (ARRAY[7, 21, 66])))
);


ALTER TABLE kaizen.capsula_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: capsula_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.capsula_mx_norte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    mensaje_cifrado bytea NOT NULL,
    llave_version smallint DEFAULT 1 NOT NULL,
    tiene_foto boolean DEFAULT false NOT NULL,
    racha_objetivo integer NOT NULL,
    estado text DEFAULT 'sellada'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    abierta_en timestamp with time zone,
    CONSTRAINT capsula_check CHECK (((estado = 'abierta'::text) = (abierta_en IS NOT NULL))),
    CONSTRAINT capsula_estado_check CHECK ((estado = ANY (ARRAY['sellada'::text, 'abierta'::text]))),
    CONSTRAINT capsula_llave_version_check CHECK ((llave_version >= 1)),
    CONSTRAINT capsula_mensaje_cifrado_check CHECK (((octet_length(mensaje_cifrado) >= 29) AND (octet_length(mensaje_cifrado) <= 4124))),
    CONSTRAINT capsula_racha_objetivo_check CHECK ((racha_objetivo = ANY (ARRAY[7, 21, 66])))
);


ALTER TABLE kaizen.capsula_mx_norte OWNER TO kaizen_owner;

--
-- Name: categoria; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.categoria (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    activa boolean DEFAULT true NOT NULL,
    CONSTRAINT categoria_nombre_check CHECK (((length(nombre) >= 2) AND (length(nombre) <= 40)))
);


ALTER TABLE kaizen.categoria OWNER TO kaizen_owner;

--
-- Name: directorio_usuarios; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.directorio_usuarios (
    email_hmac kaizen.hmac_hex NOT NULL,
    usuario_id uuid NOT NULL,
    region kaizen.region_t NOT NULL
);


ALTER TABLE kaizen.directorio_usuarios OWNER TO kaizen_owner;

--
-- Name: TABLE directorio_usuarios; Type: COMMENT; Schema: kaizen; Owner: kaizen_owner
--

COMMENT ON TABLE kaizen.directorio_usuarios IS 'Directorio de fragmentos: HMAC del correo -> usuario y región (partición).';


--
-- Name: habito; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.habito (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    categoria_id uuid NOT NULL,
    nombre text NOT NULL,
    frecuencia_tipo text NOT NULL,
    dias_semana smallint,
    veces_semana smallint,
    meta numeric(10,2) NOT NULL,
    unidad text NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    escalera_activa boolean DEFAULT true NOT NULL,
    CONSTRAINT frecuencia_coherente CHECK ((((frecuencia_tipo = 'diaria'::text) AND (dias_semana IS NULL) AND (veces_semana IS NULL)) OR ((frecuencia_tipo = 'dias_semana'::text) AND (dias_semana IS NOT NULL) AND (veces_semana IS NULL)) OR ((frecuencia_tipo = 'n_por_semana'::text) AND (dias_semana IS NULL) AND (veces_semana IS NOT NULL)))),
    CONSTRAINT habito_dias_semana_check CHECK (((dias_semana >= 1) AND (dias_semana <= 127))),
    CONSTRAINT habito_frecuencia_tipo_check CHECK ((frecuencia_tipo = ANY (ARRAY['diaria'::text, 'dias_semana'::text, 'n_por_semana'::text]))),
    CONSTRAINT habito_meta_check CHECK ((meta > (0)::numeric)),
    CONSTRAINT habito_nombre_check CHECK (((length(nombre) >= 1) AND (length(nombre) <= 60))),
    CONSTRAINT habito_unidad_check CHECK (((length(unidad) >= 1) AND (length(unidad) <= 20))),
    CONSTRAINT habito_veces_semana_check CHECK (((veces_semana >= 1) AND (veces_semana <= 7)))
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.habito OWNER TO kaizen_owner;

--
-- Name: COLUMN habito.dias_semana; Type: COMMENT; Schema: kaizen; Owner: kaizen_owner
--

COMMENT ON COLUMN kaizen.habito.dias_semana IS 'Máscara de bits: 1=lun, 2=mar, 4=mié, 8=jue, 16=vie, 32=sáb, 64=dom.';


--
-- Name: COLUMN habito.escalera_activa; Type: COMMENT; Schema: kaizen; Owner: kaizen_owner
--

COMMENT ON COLUMN kaizen.habito.escalera_activa IS 'Si es false, sp_generar_sugerencias no propone ajustes para este hábito (interruptor "Escalera Kaizen").';


--
-- Name: habito_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.habito_latam (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    categoria_id uuid NOT NULL,
    nombre text NOT NULL,
    frecuencia_tipo text NOT NULL,
    dias_semana smallint,
    veces_semana smallint,
    meta numeric(10,2) NOT NULL,
    unidad text NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    escalera_activa boolean DEFAULT true NOT NULL,
    CONSTRAINT frecuencia_coherente CHECK ((((frecuencia_tipo = 'diaria'::text) AND (dias_semana IS NULL) AND (veces_semana IS NULL)) OR ((frecuencia_tipo = 'dias_semana'::text) AND (dias_semana IS NOT NULL) AND (veces_semana IS NULL)) OR ((frecuencia_tipo = 'n_por_semana'::text) AND (dias_semana IS NULL) AND (veces_semana IS NOT NULL)))),
    CONSTRAINT habito_dias_semana_check CHECK (((dias_semana >= 1) AND (dias_semana <= 127))),
    CONSTRAINT habito_frecuencia_tipo_check CHECK ((frecuencia_tipo = ANY (ARRAY['diaria'::text, 'dias_semana'::text, 'n_por_semana'::text]))),
    CONSTRAINT habito_meta_check CHECK ((meta > (0)::numeric)),
    CONSTRAINT habito_nombre_check CHECK (((length(nombre) >= 1) AND (length(nombre) <= 60))),
    CONSTRAINT habito_unidad_check CHECK (((length(unidad) >= 1) AND (length(unidad) <= 20))),
    CONSTRAINT habito_veces_semana_check CHECK (((veces_semana >= 1) AND (veces_semana <= 7)))
);


ALTER TABLE kaizen.habito_latam OWNER TO kaizen_owner;

--
-- Name: habito_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.habito_mx_centro_sur (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    categoria_id uuid NOT NULL,
    nombre text NOT NULL,
    frecuencia_tipo text NOT NULL,
    dias_semana smallint,
    veces_semana smallint,
    meta numeric(10,2) NOT NULL,
    unidad text NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    escalera_activa boolean DEFAULT true NOT NULL,
    CONSTRAINT frecuencia_coherente CHECK ((((frecuencia_tipo = 'diaria'::text) AND (dias_semana IS NULL) AND (veces_semana IS NULL)) OR ((frecuencia_tipo = 'dias_semana'::text) AND (dias_semana IS NOT NULL) AND (veces_semana IS NULL)) OR ((frecuencia_tipo = 'n_por_semana'::text) AND (dias_semana IS NULL) AND (veces_semana IS NOT NULL)))),
    CONSTRAINT habito_dias_semana_check CHECK (((dias_semana >= 1) AND (dias_semana <= 127))),
    CONSTRAINT habito_frecuencia_tipo_check CHECK ((frecuencia_tipo = ANY (ARRAY['diaria'::text, 'dias_semana'::text, 'n_por_semana'::text]))),
    CONSTRAINT habito_meta_check CHECK ((meta > (0)::numeric)),
    CONSTRAINT habito_nombre_check CHECK (((length(nombre) >= 1) AND (length(nombre) <= 60))),
    CONSTRAINT habito_unidad_check CHECK (((length(unidad) >= 1) AND (length(unidad) <= 20))),
    CONSTRAINT habito_veces_semana_check CHECK (((veces_semana >= 1) AND (veces_semana <= 7)))
);


ALTER TABLE kaizen.habito_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: habito_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.habito_mx_norte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    categoria_id uuid NOT NULL,
    nombre text NOT NULL,
    frecuencia_tipo text NOT NULL,
    dias_semana smallint,
    veces_semana smallint,
    meta numeric(10,2) NOT NULL,
    unidad text NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    escalera_activa boolean DEFAULT true NOT NULL,
    CONSTRAINT frecuencia_coherente CHECK ((((frecuencia_tipo = 'diaria'::text) AND (dias_semana IS NULL) AND (veces_semana IS NULL)) OR ((frecuencia_tipo = 'dias_semana'::text) AND (dias_semana IS NOT NULL) AND (veces_semana IS NULL)) OR ((frecuencia_tipo = 'n_por_semana'::text) AND (dias_semana IS NULL) AND (veces_semana IS NOT NULL)))),
    CONSTRAINT habito_dias_semana_check CHECK (((dias_semana >= 1) AND (dias_semana <= 127))),
    CONSTRAINT habito_frecuencia_tipo_check CHECK ((frecuencia_tipo = ANY (ARRAY['diaria'::text, 'dias_semana'::text, 'n_por_semana'::text]))),
    CONSTRAINT habito_meta_check CHECK ((meta > (0)::numeric)),
    CONSTRAINT habito_nombre_check CHECK (((length(nombre) >= 1) AND (length(nombre) <= 60))),
    CONSTRAINT habito_unidad_check CHECK (((length(unidad) >= 1) AND (length(unidad) <= 20))),
    CONSTRAINT habito_veces_semana_check CHECK (((veces_semana >= 1) AND (veces_semana <= 7)))
);


ALTER TABLE kaizen.habito_mx_norte OWNER TO kaizen_owner;

--
-- Name: nivel_habito; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.nivel_habito (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    nivel integer NOT NULL,
    meta_valor numeric(10,2) NOT NULL,
    vigente_desde date DEFAULT CURRENT_DATE NOT NULL,
    vigente_hasta date,
    CONSTRAINT nivel_habito_check CHECK (((vigente_hasta IS NULL) OR (vigente_hasta >= vigente_desde))),
    CONSTRAINT nivel_habito_meta_valor_check CHECK ((meta_valor > (0)::numeric)),
    CONSTRAINT nivel_habito_nivel_check CHECK ((nivel >= 1))
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.nivel_habito OWNER TO kaizen_owner;

--
-- Name: nivel_habito_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.nivel_habito_latam (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    nivel integer NOT NULL,
    meta_valor numeric(10,2) NOT NULL,
    vigente_desde date DEFAULT CURRENT_DATE NOT NULL,
    vigente_hasta date,
    CONSTRAINT nivel_habito_check CHECK (((vigente_hasta IS NULL) OR (vigente_hasta >= vigente_desde))),
    CONSTRAINT nivel_habito_meta_valor_check CHECK ((meta_valor > (0)::numeric)),
    CONSTRAINT nivel_habito_nivel_check CHECK ((nivel >= 1))
);


ALTER TABLE kaizen.nivel_habito_latam OWNER TO kaizen_owner;

--
-- Name: nivel_habito_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.nivel_habito_mx_centro_sur (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    nivel integer NOT NULL,
    meta_valor numeric(10,2) NOT NULL,
    vigente_desde date DEFAULT CURRENT_DATE NOT NULL,
    vigente_hasta date,
    CONSTRAINT nivel_habito_check CHECK (((vigente_hasta IS NULL) OR (vigente_hasta >= vigente_desde))),
    CONSTRAINT nivel_habito_meta_valor_check CHECK ((meta_valor > (0)::numeric)),
    CONSTRAINT nivel_habito_nivel_check CHECK ((nivel >= 1))
);


ALTER TABLE kaizen.nivel_habito_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: nivel_habito_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.nivel_habito_mx_norte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    nivel integer NOT NULL,
    meta_valor numeric(10,2) NOT NULL,
    vigente_desde date DEFAULT CURRENT_DATE NOT NULL,
    vigente_hasta date,
    CONSTRAINT nivel_habito_check CHECK (((vigente_hasta IS NULL) OR (vigente_hasta >= vigente_desde))),
    CONSTRAINT nivel_habito_meta_valor_check CHECK ((meta_valor > (0)::numeric)),
    CONSTRAINT nivel_habito_nivel_check CHECK ((nivel >= 1))
);


ALTER TABLE kaizen.nivel_habito_mx_norte OWNER TO kaizen_owner;

--
-- Name: racha; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.racha (
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    racha_actual integer DEFAULT 0 NOT NULL,
    racha_maxima integer DEFAULT 0 NOT NULL,
    ultima_fecha date,
    actualizada_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT racha_check CHECK ((racha_maxima >= racha_actual)),
    CONSTRAINT racha_racha_actual_check CHECK ((racha_actual >= 0))
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.racha OWNER TO kaizen_owner;

--
-- Name: TABLE racha; Type: COMMENT; Schema: kaizen; Owner: kaizen_owner
--

COMMENT ON TABLE kaizen.racha IS 'Dato derivado de registro. Lo mantiene trg_registro_racha_*; reconstruible con sp_reconstruir_rachas.';


--
-- Name: racha_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.racha_latam (
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    racha_actual integer DEFAULT 0 NOT NULL,
    racha_maxima integer DEFAULT 0 NOT NULL,
    ultima_fecha date,
    actualizada_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT racha_check CHECK ((racha_maxima >= racha_actual)),
    CONSTRAINT racha_racha_actual_check CHECK ((racha_actual >= 0))
);


ALTER TABLE kaizen.racha_latam OWNER TO kaizen_owner;

--
-- Name: racha_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.racha_mx_centro_sur (
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    racha_actual integer DEFAULT 0 NOT NULL,
    racha_maxima integer DEFAULT 0 NOT NULL,
    ultima_fecha date,
    actualizada_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT racha_check CHECK ((racha_maxima >= racha_actual)),
    CONSTRAINT racha_racha_actual_check CHECK ((racha_actual >= 0))
);


ALTER TABLE kaizen.racha_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: racha_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.racha_mx_norte (
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    racha_actual integer DEFAULT 0 NOT NULL,
    racha_maxima integer DEFAULT 0 NOT NULL,
    ultima_fecha date,
    actualizada_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT racha_check CHECK ((racha_maxima >= racha_actual)),
    CONSTRAINT racha_racha_actual_check CHECK ((racha_actual >= 0))
);


ALTER TABLE kaizen.racha_mx_norte OWNER TO kaizen_owner;

--
-- Name: recuperacion_contrasena; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.recuperacion_contrasena (
    token_hash kaizen.hmac_hex NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    usado_en timestamp with time zone,
    ip inet,
    CONSTRAINT recuperacion_contrasena_check CHECK ((expira_en > creada_en))
);


ALTER TABLE kaizen.recuperacion_contrasena OWNER TO kaizen_owner;

--
-- Name: TABLE recuperacion_contrasena; Type: COMMENT; Schema: kaizen; Owner: kaizen_owner
--

COMMENT ON TABLE kaizen.recuperacion_contrasena IS 'Tokens de un solo uso para restablecer la contraseña (B4b). Vigencia 15 min; máximo 3 por hora por cuenta.';


--
-- Name: registro; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.registro (
    id uuid NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date NOT NULL,
    cumplido boolean NOT NULL,
    valor numeric(10,2),
    origen text NOT NULL,
    registrado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT registro_origen_check CHECK ((origen = ANY (ARRAY['manual'::text, 'rapido'::text, 'offline'::text]))),
    CONSTRAINT registro_valor_check CHECK ((valor >= (0)::numeric))
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.registro OWNER TO kaizen_owner;

--
-- Name: registro_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.registro_latam (
    id uuid NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date NOT NULL,
    cumplido boolean NOT NULL,
    valor numeric(10,2),
    origen text NOT NULL,
    registrado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT registro_origen_check CHECK ((origen = ANY (ARRAY['manual'::text, 'rapido'::text, 'offline'::text]))),
    CONSTRAINT registro_valor_check CHECK ((valor >= (0)::numeric))
);


ALTER TABLE kaizen.registro_latam OWNER TO kaizen_owner;

--
-- Name: registro_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.registro_mx_centro_sur (
    id uuid NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date NOT NULL,
    cumplido boolean NOT NULL,
    valor numeric(10,2),
    origen text NOT NULL,
    registrado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT registro_origen_check CHECK ((origen = ANY (ARRAY['manual'::text, 'rapido'::text, 'offline'::text]))),
    CONSTRAINT registro_valor_check CHECK ((valor >= (0)::numeric))
);


ALTER TABLE kaizen.registro_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: registro_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.registro_mx_norte (
    id uuid NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date NOT NULL,
    cumplido boolean NOT NULL,
    valor numeric(10,2),
    origen text NOT NULL,
    registrado_en timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT registro_origen_check CHECK ((origen = ANY (ARRAY['manual'::text, 'rapido'::text, 'offline'::text]))),
    CONSTRAINT registro_valor_check CHECK ((valor >= (0)::numeric))
);


ALTER TABLE kaizen.registro_mx_norte OWNER TO kaizen_owner;

--
-- Name: senal_diaria; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.senal_diaria (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date NOT NULL,
    animo kaizen.escala_1_5 NOT NULL,
    energia kaizen.escala_1_5 NOT NULL
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.senal_diaria OWNER TO kaizen_owner;

--
-- Name: senal_diaria_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.senal_diaria_latam (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date NOT NULL,
    animo kaizen.escala_1_5 NOT NULL,
    energia kaizen.escala_1_5 NOT NULL
);


ALTER TABLE kaizen.senal_diaria_latam OWNER TO kaizen_owner;

--
-- Name: senal_diaria_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.senal_diaria_mx_centro_sur (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date NOT NULL,
    animo kaizen.escala_1_5 NOT NULL,
    energia kaizen.escala_1_5 NOT NULL
);


ALTER TABLE kaizen.senal_diaria_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: senal_diaria_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.senal_diaria_mx_norte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    fecha date NOT NULL,
    animo kaizen.escala_1_5 NOT NULL,
    energia kaizen.escala_1_5 NOT NULL
);


ALTER TABLE kaizen.senal_diaria_mx_norte OWNER TO kaizen_owner;

--
-- Name: sesion; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.sesion (
    jti uuid NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    familia uuid NOT NULL,
    emitida_en timestamp with time zone DEFAULT now() NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    revocada_en timestamp with time zone,
    reemplazada_por uuid,
    CONSTRAINT sesion_check CHECK ((expira_en > emitida_en))
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.sesion OWNER TO kaizen_owner;

--
-- Name: sesion_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.sesion_latam (
    jti uuid NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    familia uuid NOT NULL,
    emitida_en timestamp with time zone DEFAULT now() NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    revocada_en timestamp with time zone,
    reemplazada_por uuid,
    CONSTRAINT sesion_check CHECK ((expira_en > emitida_en))
);


ALTER TABLE kaizen.sesion_latam OWNER TO kaizen_owner;

--
-- Name: sesion_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.sesion_mx_centro_sur (
    jti uuid NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    familia uuid NOT NULL,
    emitida_en timestamp with time zone DEFAULT now() NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    revocada_en timestamp with time zone,
    reemplazada_por uuid,
    CONSTRAINT sesion_check CHECK ((expira_en > emitida_en))
);


ALTER TABLE kaizen.sesion_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: sesion_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.sesion_mx_norte (
    jti uuid NOT NULL,
    region kaizen.region_t NOT NULL,
    usuario_id uuid NOT NULL,
    familia uuid NOT NULL,
    emitida_en timestamp with time zone DEFAULT now() NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    revocada_en timestamp with time zone,
    reemplazada_por uuid,
    CONSTRAINT sesion_check CHECK ((expira_en > emitida_en))
);


ALTER TABLE kaizen.sesion_mx_norte OWNER TO kaizen_owner;

--
-- Name: sugerencia_ajuste; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.sugerencia_ajuste (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    tipo text NOT NULL,
    meta_actual numeric(10,2) NOT NULL,
    meta_propuesta numeric(10,2) NOT NULL,
    cumplimiento_14d numeric(5,2) NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    resuelta_en timestamp with time zone,
    CONSTRAINT sugerencia_ajuste_check CHECK (((estado = 'pendiente'::text) = (resuelta_en IS NULL))),
    CONSTRAINT sugerencia_ajuste_check1 CHECK ((((tipo = 'subir'::text) AND (meta_propuesta > meta_actual)) OR ((tipo = 'bajar'::text) AND (meta_propuesta < meta_actual)))),
    CONSTRAINT sugerencia_ajuste_cumplimiento_14d_check CHECK (((cumplimiento_14d >= (0)::numeric) AND (cumplimiento_14d <= (100)::numeric))),
    CONSTRAINT sugerencia_ajuste_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'expirada'::text]))),
    CONSTRAINT sugerencia_ajuste_meta_actual_check CHECK ((meta_actual > (0)::numeric)),
    CONSTRAINT sugerencia_ajuste_meta_propuesta_check CHECK ((meta_propuesta > (0)::numeric)),
    CONSTRAINT sugerencia_ajuste_tipo_check CHECK ((tipo = ANY (ARRAY['subir'::text, 'bajar'::text])))
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.sugerencia_ajuste OWNER TO kaizen_owner;

--
-- Name: sugerencia_ajuste_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.sugerencia_ajuste_latam (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    tipo text NOT NULL,
    meta_actual numeric(10,2) NOT NULL,
    meta_propuesta numeric(10,2) NOT NULL,
    cumplimiento_14d numeric(5,2) NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    resuelta_en timestamp with time zone,
    CONSTRAINT sugerencia_ajuste_check CHECK (((estado = 'pendiente'::text) = (resuelta_en IS NULL))),
    CONSTRAINT sugerencia_ajuste_check1 CHECK ((((tipo = 'subir'::text) AND (meta_propuesta > meta_actual)) OR ((tipo = 'bajar'::text) AND (meta_propuesta < meta_actual)))),
    CONSTRAINT sugerencia_ajuste_cumplimiento_14d_check CHECK (((cumplimiento_14d >= (0)::numeric) AND (cumplimiento_14d <= (100)::numeric))),
    CONSTRAINT sugerencia_ajuste_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'expirada'::text]))),
    CONSTRAINT sugerencia_ajuste_meta_actual_check CHECK ((meta_actual > (0)::numeric)),
    CONSTRAINT sugerencia_ajuste_meta_propuesta_check CHECK ((meta_propuesta > (0)::numeric)),
    CONSTRAINT sugerencia_ajuste_tipo_check CHECK ((tipo = ANY (ARRAY['subir'::text, 'bajar'::text])))
);


ALTER TABLE kaizen.sugerencia_ajuste_latam OWNER TO kaizen_owner;

--
-- Name: sugerencia_ajuste_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.sugerencia_ajuste_mx_centro_sur (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    tipo text NOT NULL,
    meta_actual numeric(10,2) NOT NULL,
    meta_propuesta numeric(10,2) NOT NULL,
    cumplimiento_14d numeric(5,2) NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    resuelta_en timestamp with time zone,
    CONSTRAINT sugerencia_ajuste_check CHECK (((estado = 'pendiente'::text) = (resuelta_en IS NULL))),
    CONSTRAINT sugerencia_ajuste_check1 CHECK ((((tipo = 'subir'::text) AND (meta_propuesta > meta_actual)) OR ((tipo = 'bajar'::text) AND (meta_propuesta < meta_actual)))),
    CONSTRAINT sugerencia_ajuste_cumplimiento_14d_check CHECK (((cumplimiento_14d >= (0)::numeric) AND (cumplimiento_14d <= (100)::numeric))),
    CONSTRAINT sugerencia_ajuste_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'expirada'::text]))),
    CONSTRAINT sugerencia_ajuste_meta_actual_check CHECK ((meta_actual > (0)::numeric)),
    CONSTRAINT sugerencia_ajuste_meta_propuesta_check CHECK ((meta_propuesta > (0)::numeric)),
    CONSTRAINT sugerencia_ajuste_tipo_check CHECK ((tipo = ANY (ARRAY['subir'::text, 'bajar'::text])))
);


ALTER TABLE kaizen.sugerencia_ajuste_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: sugerencia_ajuste_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.sugerencia_ajuste_mx_norte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    habito_id uuid NOT NULL,
    tipo text NOT NULL,
    meta_actual numeric(10,2) NOT NULL,
    meta_propuesta numeric(10,2) NOT NULL,
    cumplimiento_14d numeric(5,2) NOT NULL,
    estado text DEFAULT 'pendiente'::text NOT NULL,
    creada_en timestamp with time zone DEFAULT now() NOT NULL,
    resuelta_en timestamp with time zone,
    CONSTRAINT sugerencia_ajuste_check CHECK (((estado = 'pendiente'::text) = (resuelta_en IS NULL))),
    CONSTRAINT sugerencia_ajuste_check1 CHECK ((((tipo = 'subir'::text) AND (meta_propuesta > meta_actual)) OR ((tipo = 'bajar'::text) AND (meta_propuesta < meta_actual)))),
    CONSTRAINT sugerencia_ajuste_cumplimiento_14d_check CHECK (((cumplimiento_14d >= (0)::numeric) AND (cumplimiento_14d <= (100)::numeric))),
    CONSTRAINT sugerencia_ajuste_estado_check CHECK ((estado = ANY (ARRAY['pendiente'::text, 'aceptada'::text, 'rechazada'::text, 'expirada'::text]))),
    CONSTRAINT sugerencia_ajuste_meta_actual_check CHECK ((meta_actual > (0)::numeric)),
    CONSTRAINT sugerencia_ajuste_meta_propuesta_check CHECK ((meta_propuesta > (0)::numeric)),
    CONSTRAINT sugerencia_ajuste_tipo_check CHECK ((tipo = ANY (ARRAY['subir'::text, 'bajar'::text])))
);


ALTER TABLE kaizen.sugerencia_ajuste_mx_norte OWNER TO kaizen_owner;

--
-- Name: usuario; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    nombre text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    pais character(2) NOT NULL,
    rol text DEFAULT 'usuario'::text NOT NULL,
    fecha_registro timestamp with time zone DEFAULT now() NOT NULL,
    acepto_aviso_en timestamp with time zone NOT NULL,
    consentimiento_senales_en timestamp with time zone,
    intentos_fallidos smallint DEFAULT 0 NOT NULL,
    bloqueado_hasta timestamp with time zone,
    suspendido_en timestamp with time zone,
    suspension_motivo text,
    CONSTRAINT suspension_coherente CHECK (((suspendido_en IS NULL) = (suspension_motivo IS NULL))),
    CONSTRAINT usuario_email_check CHECK ((email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text)),
    CONSTRAINT usuario_intentos_fallidos_check CHECK ((intentos_fallidos >= 0)),
    CONSTRAINT usuario_nombre_check CHECK (((length(nombre) >= 1) AND (length(nombre) <= 80))),
    CONSTRAINT usuario_pais_check CHECK ((pais ~ '^[A-Z]{2}$'::text)),
    CONSTRAINT usuario_password_hash_check CHECK ((password_hash ~~ '$argon2id$%'::text)),
    CONSTRAINT usuario_rol_check CHECK ((rol = ANY (ARRAY['usuario'::text, 'admin'::text]))),
    CONSTRAINT usuario_suspension_motivo_check CHECK (((length(suspension_motivo) >= 3) AND (length(suspension_motivo) <= 200)))
)
PARTITION BY LIST (region);


ALTER TABLE kaizen.usuario OWNER TO kaizen_owner;

--
-- Name: COLUMN usuario.suspendido_en; Type: COMMENT; Schema: kaizen; Owner: kaizen_owner
--

COMMENT ON COLUMN kaizen.usuario.suspendido_en IS 'Suspensión administrativa (B5). Solo cambia con sp_admin_suspender_usuario.';


--
-- Name: usuario_latam; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.usuario_latam (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    nombre text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    pais character(2) NOT NULL,
    rol text DEFAULT 'usuario'::text NOT NULL,
    fecha_registro timestamp with time zone DEFAULT now() NOT NULL,
    acepto_aviso_en timestamp with time zone NOT NULL,
    consentimiento_senales_en timestamp with time zone,
    intentos_fallidos smallint DEFAULT 0 NOT NULL,
    bloqueado_hasta timestamp with time zone,
    suspendido_en timestamp with time zone,
    suspension_motivo text,
    CONSTRAINT suspension_coherente CHECK (((suspendido_en IS NULL) = (suspension_motivo IS NULL))),
    CONSTRAINT usuario_email_check CHECK ((email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text)),
    CONSTRAINT usuario_intentos_fallidos_check CHECK ((intentos_fallidos >= 0)),
    CONSTRAINT usuario_nombre_check CHECK (((length(nombre) >= 1) AND (length(nombre) <= 80))),
    CONSTRAINT usuario_pais_check CHECK ((pais ~ '^[A-Z]{2}$'::text)),
    CONSTRAINT usuario_password_hash_check CHECK ((password_hash ~~ '$argon2id$%'::text)),
    CONSTRAINT usuario_rol_check CHECK ((rol = ANY (ARRAY['usuario'::text, 'admin'::text]))),
    CONSTRAINT usuario_suspension_motivo_check CHECK (((length(suspension_motivo) >= 3) AND (length(suspension_motivo) <= 200)))
);


ALTER TABLE kaizen.usuario_latam OWNER TO kaizen_owner;

--
-- Name: usuario_mx_centro_sur; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.usuario_mx_centro_sur (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    nombre text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    pais character(2) NOT NULL,
    rol text DEFAULT 'usuario'::text NOT NULL,
    fecha_registro timestamp with time zone DEFAULT now() NOT NULL,
    acepto_aviso_en timestamp with time zone NOT NULL,
    consentimiento_senales_en timestamp with time zone,
    intentos_fallidos smallint DEFAULT 0 NOT NULL,
    bloqueado_hasta timestamp with time zone,
    suspendido_en timestamp with time zone,
    suspension_motivo text,
    CONSTRAINT suspension_coherente CHECK (((suspendido_en IS NULL) = (suspension_motivo IS NULL))),
    CONSTRAINT usuario_email_check CHECK ((email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text)),
    CONSTRAINT usuario_intentos_fallidos_check CHECK ((intentos_fallidos >= 0)),
    CONSTRAINT usuario_nombre_check CHECK (((length(nombre) >= 1) AND (length(nombre) <= 80))),
    CONSTRAINT usuario_pais_check CHECK ((pais ~ '^[A-Z]{2}$'::text)),
    CONSTRAINT usuario_password_hash_check CHECK ((password_hash ~~ '$argon2id$%'::text)),
    CONSTRAINT usuario_rol_check CHECK ((rol = ANY (ARRAY['usuario'::text, 'admin'::text]))),
    CONSTRAINT usuario_suspension_motivo_check CHECK (((length(suspension_motivo) >= 3) AND (length(suspension_motivo) <= 200)))
);


ALTER TABLE kaizen.usuario_mx_centro_sur OWNER TO kaizen_owner;

--
-- Name: usuario_mx_norte; Type: TABLE; Schema: kaizen; Owner: kaizen_owner
--

CREATE TABLE kaizen.usuario_mx_norte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    region kaizen.region_t NOT NULL,
    nombre text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    pais character(2) NOT NULL,
    rol text DEFAULT 'usuario'::text NOT NULL,
    fecha_registro timestamp with time zone DEFAULT now() NOT NULL,
    acepto_aviso_en timestamp with time zone NOT NULL,
    consentimiento_senales_en timestamp with time zone,
    intentos_fallidos smallint DEFAULT 0 NOT NULL,
    bloqueado_hasta timestamp with time zone,
    suspendido_en timestamp with time zone,
    suspension_motivo text,
    CONSTRAINT suspension_coherente CHECK (((suspendido_en IS NULL) = (suspension_motivo IS NULL))),
    CONSTRAINT usuario_email_check CHECK ((email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text)),
    CONSTRAINT usuario_intentos_fallidos_check CHECK ((intentos_fallidos >= 0)),
    CONSTRAINT usuario_nombre_check CHECK (((length(nombre) >= 1) AND (length(nombre) <= 80))),
    CONSTRAINT usuario_pais_check CHECK ((pais ~ '^[A-Z]{2}$'::text)),
    CONSTRAINT usuario_password_hash_check CHECK ((password_hash ~~ '$argon2id$%'::text)),
    CONSTRAINT usuario_rol_check CHECK ((rol = ANY (ARRAY['usuario'::text, 'admin'::text]))),
    CONSTRAINT usuario_suspension_motivo_check CHECK (((length(suspension_motivo) >= 3) AND (length(suspension_motivo) <= 200)))
);


ALTER TABLE kaizen.usuario_mx_norte OWNER TO kaizen_owner;

--
-- Name: v_metricas_region; Type: VIEW; Schema: kaizen; Owner: kaizen_owner
--

CREATE VIEW kaizen.v_metricas_region AS
 SELECT h.region,
    c.nombre AS categoria,
    count(DISTINCT h.usuario_id) AS usuarios,
    count(*) AS habitos,
    round(avg(r.racha_actual), 2) AS racha_promedio
   FROM ((kaizen.habito h
     JOIN kaizen.categoria c ON ((c.id = h.categoria_id)))
     JOIN kaizen.racha r ON ((((r.region)::text = (h.region)::text) AND (r.habito_id = h.id))))
  WHERE h.activo
  GROUP BY h.region, c.nombre
 HAVING (count(DISTINCT h.usuario_id) >= 5);


ALTER VIEW kaizen.v_metricas_region OWNER TO kaizen_owner;

--
-- Name: v_racha_vigente; Type: VIEW; Schema: kaizen; Owner: kaizen_owner
--

CREATE VIEW kaizen.v_racha_vigente WITH (security_invoker='true', security_barrier='true') AS
 SELECT r.region,
    r.habito_id,
    h.usuario_id,
        CASE
            WHEN (h.frecuencia_tipo = 'n_por_semana'::text) THEN r.racha_actual
            WHEN (r.ultima_fecha >= kaizen.fn_dia_programado_anterior(h.frecuencia_tipo, h.dias_semana, CURRENT_DATE)) THEN r.racha_actual
            ELSE 0
        END AS racha_actual,
    r.racha_maxima,
    r.ultima_fecha
   FROM (kaizen.racha r
     JOIN kaizen.habito h ON ((((h.region)::text = (r.region)::text) AND (h.id = r.habito_id))));


ALTER VIEW kaizen.v_racha_vigente OWNER TO kaizen_owner;

--
-- Name: v_usuario_admin; Type: VIEW; Schema: kaizen; Owner: kaizen_owner
--

CREATE VIEW kaizen.v_usuario_admin WITH (security_barrier='true') AS
 SELECT id,
    region,
    pais,
    rol,
    fecha_registro,
    ("left"(nombre, 1) || repeat('*'::text, GREATEST((length(nombre) - 1), 2))) AS nombre_mascara,
    regexp_replace(email, '^(.)[^@]*@.*(\.[^.]+)$'::text, '\1***@***\2'::text) AS email_mascara,
    (bloqueado_hasta > now()) AS bloqueado,
    (consentimiento_senales_en IS NOT NULL) AS consiente_senales,
    (suspendido_en IS NOT NULL) AS suspendido,
    suspendido_en,
    suspension_motivo
   FROM kaizen.usuario;


ALTER VIEW kaizen.v_usuario_admin OWNER TO kaizen_owner;

--
-- Name: bitacora_2026_11; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_2026_11 FOR VALUES FROM ('2026-11-01 00:00:00+00') TO ('2026-12-01 00:00:00+00');


--
-- Name: bitacora_2026_12; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_2026_12 FOR VALUES FROM ('2026-12-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');


--
-- Name: bitacora_2027_01; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_2027_01 FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2027-02-01 00:00:00+00');


--
-- Name: bitacora_2027_02; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_2027_02 FOR VALUES FROM ('2027-02-01 00:00:00+00') TO ('2027-03-01 00:00:00+00');


--
-- Name: bitacora_2027_03; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_2027_03 FOR VALUES FROM ('2027-03-01 00:00:00+00') TO ('2027-04-01 00:00:00+00');


--
-- Name: bitacora_2027_04; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_2027_04 FOR VALUES FROM ('2027-04-01 00:00:00+00') TO ('2027-05-01 00:00:00+00');


--
-- Name: bitacora_2027_05; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_2027_05 FOR VALUES FROM ('2027-05-01 00:00:00+00') TO ('2027-06-01 00:00:00+00');


--
-- Name: bitacora_2027_06; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_2027_06 FOR VALUES FROM ('2027-06-01 00:00:00+00') TO ('2027-07-01 00:00:00+00');


--
-- Name: bitacora_default; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria ATTACH PARTITION kaizen.bitacora_default DEFAULT;


--
-- Name: capsula_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.capsula ATTACH PARTITION kaizen.capsula_latam FOR VALUES IN ('LATAM');


--
-- Name: capsula_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.capsula ATTACH PARTITION kaizen.capsula_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: capsula_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.capsula ATTACH PARTITION kaizen.capsula_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: habito_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito ATTACH PARTITION kaizen.habito_latam FOR VALUES IN ('LATAM');


--
-- Name: habito_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito ATTACH PARTITION kaizen.habito_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: habito_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito ATTACH PARTITION kaizen.habito_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: nivel_habito_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.nivel_habito ATTACH PARTITION kaizen.nivel_habito_latam FOR VALUES IN ('LATAM');


--
-- Name: nivel_habito_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.nivel_habito ATTACH PARTITION kaizen.nivel_habito_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: nivel_habito_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.nivel_habito ATTACH PARTITION kaizen.nivel_habito_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: racha_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.racha ATTACH PARTITION kaizen.racha_latam FOR VALUES IN ('LATAM');


--
-- Name: racha_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.racha ATTACH PARTITION kaizen.racha_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: racha_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.racha ATTACH PARTITION kaizen.racha_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: registro_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro ATTACH PARTITION kaizen.registro_latam FOR VALUES IN ('LATAM');


--
-- Name: registro_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro ATTACH PARTITION kaizen.registro_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: registro_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro ATTACH PARTITION kaizen.registro_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: senal_diaria_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria ATTACH PARTITION kaizen.senal_diaria_latam FOR VALUES IN ('LATAM');


--
-- Name: senal_diaria_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria ATTACH PARTITION kaizen.senal_diaria_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: senal_diaria_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria ATTACH PARTITION kaizen.senal_diaria_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: sesion_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sesion ATTACH PARTITION kaizen.sesion_latam FOR VALUES IN ('LATAM');


--
-- Name: sesion_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sesion ATTACH PARTITION kaizen.sesion_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: sesion_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sesion ATTACH PARTITION kaizen.sesion_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: sugerencia_ajuste_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sugerencia_ajuste ATTACH PARTITION kaizen.sugerencia_ajuste_latam FOR VALUES IN ('LATAM');


--
-- Name: sugerencia_ajuste_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sugerencia_ajuste ATTACH PARTITION kaizen.sugerencia_ajuste_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: sugerencia_ajuste_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sugerencia_ajuste ATTACH PARTITION kaizen.sugerencia_ajuste_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: usuario_latam; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.usuario ATTACH PARTITION kaizen.usuario_latam FOR VALUES IN ('LATAM');


--
-- Name: usuario_mx_centro_sur; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.usuario ATTACH PARTITION kaizen.usuario_mx_centro_sur FOR VALUES IN ('MX-CENTRO-SUR');


--
-- Name: usuario_mx_norte; Type: TABLE ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.usuario ATTACH PARTITION kaizen.usuario_mx_norte FOR VALUES IN ('MX-NORTE');


--
-- Name: bitacora_auditoria bitacora_auditoria_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_auditoria
    ADD CONSTRAINT bitacora_auditoria_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_2026_11 bitacora_2026_11_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_2026_11
    ADD CONSTRAINT bitacora_2026_11_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_2026_12 bitacora_2026_12_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_2026_12
    ADD CONSTRAINT bitacora_2026_12_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_2027_01 bitacora_2027_01_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_2027_01
    ADD CONSTRAINT bitacora_2027_01_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_2027_02 bitacora_2027_02_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_2027_02
    ADD CONSTRAINT bitacora_2027_02_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_2027_03 bitacora_2027_03_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_2027_03
    ADD CONSTRAINT bitacora_2027_03_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_2027_04 bitacora_2027_04_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_2027_04
    ADD CONSTRAINT bitacora_2027_04_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_2027_05 bitacora_2027_05_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_2027_05
    ADD CONSTRAINT bitacora_2027_05_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_2027_06 bitacora_2027_06_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_2027_06
    ADD CONSTRAINT bitacora_2027_06_pkey PRIMARY KEY (fecha, id);


--
-- Name: bitacora_default bitacora_default_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.bitacora_default
    ADD CONSTRAINT bitacora_default_pkey PRIMARY KEY (fecha, id);


--
-- Name: capsula capsula_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.capsula
    ADD CONSTRAINT capsula_pkey PRIMARY KEY (region, id);


--
-- Name: capsula_latam capsula_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.capsula_latam
    ADD CONSTRAINT capsula_latam_pkey PRIMARY KEY (region, id);


--
-- Name: capsula_mx_centro_sur capsula_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.capsula_mx_centro_sur
    ADD CONSTRAINT capsula_mx_centro_sur_pkey PRIMARY KEY (region, id);


--
-- Name: capsula_mx_norte capsula_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.capsula_mx_norte
    ADD CONSTRAINT capsula_mx_norte_pkey PRIMARY KEY (region, id);


--
-- Name: categoria categoria_nombre_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.categoria
    ADD CONSTRAINT categoria_nombre_key UNIQUE (nombre);


--
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id);


--
-- Name: directorio_usuarios directorio_usuarios_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.directorio_usuarios
    ADD CONSTRAINT directorio_usuarios_pkey PRIMARY KEY (email_hmac);


--
-- Name: directorio_usuarios directorio_usuarios_usuario_id_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.directorio_usuarios
    ADD CONSTRAINT directorio_usuarios_usuario_id_key UNIQUE (usuario_id);


--
-- Name: habito habito_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito
    ADD CONSTRAINT habito_pkey PRIMARY KEY (region, id);


--
-- Name: habito_latam habito_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito_latam
    ADD CONSTRAINT habito_latam_pkey PRIMARY KEY (region, id);


--
-- Name: habito habito_region_id_usuario_id_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito
    ADD CONSTRAINT habito_region_id_usuario_id_key UNIQUE (region, id, usuario_id);


--
-- Name: habito_latam habito_latam_region_id_usuario_id_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito_latam
    ADD CONSTRAINT habito_latam_region_id_usuario_id_key UNIQUE (region, id, usuario_id);


--
-- Name: habito_mx_centro_sur habito_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito_mx_centro_sur
    ADD CONSTRAINT habito_mx_centro_sur_pkey PRIMARY KEY (region, id);


--
-- Name: habito_mx_centro_sur habito_mx_centro_sur_region_id_usuario_id_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito_mx_centro_sur
    ADD CONSTRAINT habito_mx_centro_sur_region_id_usuario_id_key UNIQUE (region, id, usuario_id);


--
-- Name: habito_mx_norte habito_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito_mx_norte
    ADD CONSTRAINT habito_mx_norte_pkey PRIMARY KEY (region, id);


--
-- Name: habito_mx_norte habito_mx_norte_region_id_usuario_id_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.habito_mx_norte
    ADD CONSTRAINT habito_mx_norte_region_id_usuario_id_key UNIQUE (region, id, usuario_id);


--
-- Name: nivel_habito nivel_habito_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.nivel_habito
    ADD CONSTRAINT nivel_habito_pkey PRIMARY KEY (region, id);


--
-- Name: nivel_habito_latam nivel_habito_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.nivel_habito_latam
    ADD CONSTRAINT nivel_habito_latam_pkey PRIMARY KEY (region, id);


--
-- Name: nivel_habito_mx_centro_sur nivel_habito_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.nivel_habito_mx_centro_sur
    ADD CONSTRAINT nivel_habito_mx_centro_sur_pkey PRIMARY KEY (region, id);


--
-- Name: nivel_habito_mx_norte nivel_habito_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.nivel_habito_mx_norte
    ADD CONSTRAINT nivel_habito_mx_norte_pkey PRIMARY KEY (region, id);


--
-- Name: racha racha_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.racha
    ADD CONSTRAINT racha_pkey PRIMARY KEY (region, habito_id);


--
-- Name: racha_latam racha_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.racha_latam
    ADD CONSTRAINT racha_latam_pkey PRIMARY KEY (region, habito_id);


--
-- Name: racha_mx_centro_sur racha_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.racha_mx_centro_sur
    ADD CONSTRAINT racha_mx_centro_sur_pkey PRIMARY KEY (region, habito_id);


--
-- Name: racha_mx_norte racha_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.racha_mx_norte
    ADD CONSTRAINT racha_mx_norte_pkey PRIMARY KEY (region, habito_id);


--
-- Name: recuperacion_contrasena recuperacion_contrasena_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.recuperacion_contrasena
    ADD CONSTRAINT recuperacion_contrasena_pkey PRIMARY KEY (token_hash);


--
-- Name: registro registro_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro
    ADD CONSTRAINT registro_pkey PRIMARY KEY (region, id);


--
-- Name: registro_latam registro_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro_latam
    ADD CONSTRAINT registro_latam_pkey PRIMARY KEY (region, id);


--
-- Name: registro registro_region_habito_id_fecha_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro
    ADD CONSTRAINT registro_region_habito_id_fecha_key UNIQUE (region, habito_id, fecha);


--
-- Name: registro_latam registro_latam_region_habito_id_fecha_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro_latam
    ADD CONSTRAINT registro_latam_region_habito_id_fecha_key UNIQUE (region, habito_id, fecha);


--
-- Name: registro_mx_centro_sur registro_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro_mx_centro_sur
    ADD CONSTRAINT registro_mx_centro_sur_pkey PRIMARY KEY (region, id);


--
-- Name: registro_mx_centro_sur registro_mx_centro_sur_region_habito_id_fecha_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro_mx_centro_sur
    ADD CONSTRAINT registro_mx_centro_sur_region_habito_id_fecha_key UNIQUE (region, habito_id, fecha);


--
-- Name: registro_mx_norte registro_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro_mx_norte
    ADD CONSTRAINT registro_mx_norte_pkey PRIMARY KEY (region, id);


--
-- Name: registro_mx_norte registro_mx_norte_region_habito_id_fecha_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.registro_mx_norte
    ADD CONSTRAINT registro_mx_norte_region_habito_id_fecha_key UNIQUE (region, habito_id, fecha);


--
-- Name: senal_diaria senal_diaria_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria
    ADD CONSTRAINT senal_diaria_pkey PRIMARY KEY (region, id);


--
-- Name: senal_diaria_latam senal_diaria_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria_latam
    ADD CONSTRAINT senal_diaria_latam_pkey PRIMARY KEY (region, id);


--
-- Name: senal_diaria senal_diaria_region_usuario_id_fecha_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria
    ADD CONSTRAINT senal_diaria_region_usuario_id_fecha_key UNIQUE (region, usuario_id, fecha);


--
-- Name: senal_diaria_latam senal_diaria_latam_region_usuario_id_fecha_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria_latam
    ADD CONSTRAINT senal_diaria_latam_region_usuario_id_fecha_key UNIQUE (region, usuario_id, fecha);


--
-- Name: senal_diaria_mx_centro_sur senal_diaria_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria_mx_centro_sur
    ADD CONSTRAINT senal_diaria_mx_centro_sur_pkey PRIMARY KEY (region, id);


--
-- Name: senal_diaria_mx_centro_sur senal_diaria_mx_centro_sur_region_usuario_id_fecha_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria_mx_centro_sur
    ADD CONSTRAINT senal_diaria_mx_centro_sur_region_usuario_id_fecha_key UNIQUE (region, usuario_id, fecha);


--
-- Name: senal_diaria_mx_norte senal_diaria_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria_mx_norte
    ADD CONSTRAINT senal_diaria_mx_norte_pkey PRIMARY KEY (region, id);


--
-- Name: senal_diaria_mx_norte senal_diaria_mx_norte_region_usuario_id_fecha_key; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.senal_diaria_mx_norte
    ADD CONSTRAINT senal_diaria_mx_norte_region_usuario_id_fecha_key UNIQUE (region, usuario_id, fecha);


--
-- Name: sesion sesion_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sesion
    ADD CONSTRAINT sesion_pkey PRIMARY KEY (region, jti);


--
-- Name: sesion_latam sesion_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sesion_latam
    ADD CONSTRAINT sesion_latam_pkey PRIMARY KEY (region, jti);


--
-- Name: sesion_mx_centro_sur sesion_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sesion_mx_centro_sur
    ADD CONSTRAINT sesion_mx_centro_sur_pkey PRIMARY KEY (region, jti);


--
-- Name: sesion_mx_norte sesion_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sesion_mx_norte
    ADD CONSTRAINT sesion_mx_norte_pkey PRIMARY KEY (region, jti);


--
-- Name: sugerencia_ajuste sugerencia_ajuste_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sugerencia_ajuste
    ADD CONSTRAINT sugerencia_ajuste_pkey PRIMARY KEY (region, id);


--
-- Name: sugerencia_ajuste_latam sugerencia_ajuste_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sugerencia_ajuste_latam
    ADD CONSTRAINT sugerencia_ajuste_latam_pkey PRIMARY KEY (region, id);


--
-- Name: sugerencia_ajuste_mx_centro_sur sugerencia_ajuste_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sugerencia_ajuste_mx_centro_sur
    ADD CONSTRAINT sugerencia_ajuste_mx_centro_sur_pkey PRIMARY KEY (region, id);


--
-- Name: sugerencia_ajuste_mx_norte sugerencia_ajuste_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.sugerencia_ajuste_mx_norte
    ADD CONSTRAINT sugerencia_ajuste_mx_norte_pkey PRIMARY KEY (region, id);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (region, id);


--
-- Name: usuario_latam usuario_latam_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.usuario_latam
    ADD CONSTRAINT usuario_latam_pkey PRIMARY KEY (region, id);


--
-- Name: usuario_mx_centro_sur usuario_mx_centro_sur_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.usuario_mx_centro_sur
    ADD CONSTRAINT usuario_mx_centro_sur_pkey PRIMARY KEY (region, id);


--
-- Name: usuario_mx_norte usuario_mx_norte_pkey; Type: CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.usuario_mx_norte
    ADD CONSTRAINT usuario_mx_norte_pkey PRIMARY KEY (region, id);


--
-- Name: ix_bitacora_fallos; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_bitacora_fallos ON ONLY kaizen.bitacora_auditoria USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_2026_11_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2026_11_accion_fecha_idx ON kaizen.bitacora_2026_11 USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: ix_bitacora_usuario; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_bitacora_usuario ON ONLY kaizen.bitacora_auditoria USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_2026_11_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2026_11_usuario_id_fecha_idx ON kaizen.bitacora_2026_11 USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_2026_12_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2026_12_accion_fecha_idx ON kaizen.bitacora_2026_12 USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_2026_12_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2026_12_usuario_id_fecha_idx ON kaizen.bitacora_2026_12 USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_2027_01_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_01_accion_fecha_idx ON kaizen.bitacora_2027_01 USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_2027_01_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_01_usuario_id_fecha_idx ON kaizen.bitacora_2027_01 USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_2027_02_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_02_accion_fecha_idx ON kaizen.bitacora_2027_02 USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_2027_02_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_02_usuario_id_fecha_idx ON kaizen.bitacora_2027_02 USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_2027_03_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_03_accion_fecha_idx ON kaizen.bitacora_2027_03 USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_2027_03_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_03_usuario_id_fecha_idx ON kaizen.bitacora_2027_03 USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_2027_04_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_04_accion_fecha_idx ON kaizen.bitacora_2027_04 USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_2027_04_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_04_usuario_id_fecha_idx ON kaizen.bitacora_2027_04 USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_2027_05_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_05_accion_fecha_idx ON kaizen.bitacora_2027_05 USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_2027_05_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_05_usuario_id_fecha_idx ON kaizen.bitacora_2027_05 USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_2027_06_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_06_accion_fecha_idx ON kaizen.bitacora_2027_06 USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_2027_06_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_2027_06_usuario_id_fecha_idx ON kaizen.bitacora_2027_06 USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: bitacora_default_accion_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_default_accion_fecha_idx ON kaizen.bitacora_default USING btree (accion, fecha DESC) WHERE (resultado <> 'exito'::text);


--
-- Name: bitacora_default_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX bitacora_default_usuario_id_fecha_idx ON kaizen.bitacora_default USING btree (usuario_id, fecha DESC) WHERE (usuario_id IS NOT NULL);


--
-- Name: ix_capsula_habito; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_capsula_habito ON ONLY kaizen.capsula USING btree (region, habito_id) WHERE (estado = 'sellada'::text);


--
-- Name: capsula_latam_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX capsula_latam_region_habito_id_idx ON kaizen.capsula_latam USING btree (region, habito_id) WHERE (estado = 'sellada'::text);


--
-- Name: capsula_mx_centro_sur_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX capsula_mx_centro_sur_region_habito_id_idx ON kaizen.capsula_mx_centro_sur USING btree (region, habito_id) WHERE (estado = 'sellada'::text);


--
-- Name: capsula_mx_norte_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX capsula_mx_norte_region_habito_id_idx ON kaizen.capsula_mx_norte USING btree (region, habito_id) WHERE (estado = 'sellada'::text);


--
-- Name: ix_habito_categoria; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_habito_categoria ON ONLY kaizen.habito USING btree (categoria_id);


--
-- Name: habito_latam_categoria_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX habito_latam_categoria_id_idx ON kaizen.habito_latam USING btree (categoria_id);


--
-- Name: ix_habito_usuario; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_habito_usuario ON ONLY kaizen.habito USING btree (region, usuario_id) WHERE activo;


--
-- Name: habito_latam_region_usuario_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX habito_latam_region_usuario_id_idx ON kaizen.habito_latam USING btree (region, usuario_id) WHERE activo;


--
-- Name: habito_mx_centro_sur_categoria_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX habito_mx_centro_sur_categoria_id_idx ON kaizen.habito_mx_centro_sur USING btree (categoria_id);


--
-- Name: habito_mx_centro_sur_region_usuario_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX habito_mx_centro_sur_region_usuario_id_idx ON kaizen.habito_mx_centro_sur USING btree (region, usuario_id) WHERE activo;


--
-- Name: habito_mx_norte_categoria_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX habito_mx_norte_categoria_id_idx ON kaizen.habito_mx_norte USING btree (categoria_id);


--
-- Name: habito_mx_norte_region_usuario_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX habito_mx_norte_region_usuario_id_idx ON kaizen.habito_mx_norte USING btree (region, usuario_id) WHERE activo;


--
-- Name: ix_nivel_habito; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_nivel_habito ON ONLY kaizen.nivel_habito USING btree (region, habito_id, vigente_desde DESC);


--
-- Name: ix_recuperacion_usuario; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_recuperacion_usuario ON kaizen.recuperacion_contrasena USING btree (region, usuario_id, creada_en DESC);


--
-- Name: ix_registro_registrado_brin; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_registro_registrado_brin ON ONLY kaizen.registro USING brin (registrado_en);


--
-- Name: ix_registro_usuario_fecha; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_registro_usuario_fecha ON ONLY kaizen.registro USING btree (region, usuario_id, fecha DESC);


--
-- Name: ix_sesion_familia; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_sesion_familia ON ONLY kaizen.sesion USING btree (region, familia);


--
-- Name: ix_sesion_usuario; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX ix_sesion_usuario ON ONLY kaizen.sesion USING btree (region, usuario_id) WHERE (revocada_en IS NULL);


--
-- Name: ux_nivel_vigente; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX ux_nivel_vigente ON ONLY kaizen.nivel_habito USING btree (region, habito_id) WHERE (vigente_hasta IS NULL);


--
-- Name: nivel_habito_latam_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX nivel_habito_latam_region_habito_id_idx ON kaizen.nivel_habito_latam USING btree (region, habito_id) WHERE (vigente_hasta IS NULL);


--
-- Name: nivel_habito_latam_region_habito_id_vigente_desde_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX nivel_habito_latam_region_habito_id_vigente_desde_idx ON kaizen.nivel_habito_latam USING btree (region, habito_id, vigente_desde DESC);


--
-- Name: nivel_habito_mx_centro_sur_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX nivel_habito_mx_centro_sur_region_habito_id_idx ON kaizen.nivel_habito_mx_centro_sur USING btree (region, habito_id) WHERE (vigente_hasta IS NULL);


--
-- Name: nivel_habito_mx_centro_sur_region_habito_id_vigente_desde_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX nivel_habito_mx_centro_sur_region_habito_id_vigente_desde_idx ON kaizen.nivel_habito_mx_centro_sur USING btree (region, habito_id, vigente_desde DESC);


--
-- Name: nivel_habito_mx_norte_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX nivel_habito_mx_norte_region_habito_id_idx ON kaizen.nivel_habito_mx_norte USING btree (region, habito_id) WHERE (vigente_hasta IS NULL);


--
-- Name: nivel_habito_mx_norte_region_habito_id_vigente_desde_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX nivel_habito_mx_norte_region_habito_id_vigente_desde_idx ON kaizen.nivel_habito_mx_norte USING btree (region, habito_id, vigente_desde DESC);


--
-- Name: registro_latam_region_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX registro_latam_region_usuario_id_fecha_idx ON kaizen.registro_latam USING btree (region, usuario_id, fecha DESC);


--
-- Name: registro_latam_registrado_en_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX registro_latam_registrado_en_idx ON kaizen.registro_latam USING brin (registrado_en);


--
-- Name: registro_mx_centro_sur_region_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX registro_mx_centro_sur_region_usuario_id_fecha_idx ON kaizen.registro_mx_centro_sur USING btree (region, usuario_id, fecha DESC);


--
-- Name: registro_mx_centro_sur_registrado_en_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX registro_mx_centro_sur_registrado_en_idx ON kaizen.registro_mx_centro_sur USING brin (registrado_en);


--
-- Name: registro_mx_norte_region_usuario_id_fecha_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX registro_mx_norte_region_usuario_id_fecha_idx ON kaizen.registro_mx_norte USING btree (region, usuario_id, fecha DESC);


--
-- Name: registro_mx_norte_registrado_en_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX registro_mx_norte_registrado_en_idx ON kaizen.registro_mx_norte USING brin (registrado_en);


--
-- Name: sesion_latam_region_familia_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX sesion_latam_region_familia_idx ON kaizen.sesion_latam USING btree (region, familia);


--
-- Name: sesion_latam_region_usuario_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX sesion_latam_region_usuario_id_idx ON kaizen.sesion_latam USING btree (region, usuario_id) WHERE (revocada_en IS NULL);


--
-- Name: sesion_mx_centro_sur_region_familia_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX sesion_mx_centro_sur_region_familia_idx ON kaizen.sesion_mx_centro_sur USING btree (region, familia);


--
-- Name: sesion_mx_centro_sur_region_usuario_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX sesion_mx_centro_sur_region_usuario_id_idx ON kaizen.sesion_mx_centro_sur USING btree (region, usuario_id) WHERE (revocada_en IS NULL);


--
-- Name: sesion_mx_norte_region_familia_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX sesion_mx_norte_region_familia_idx ON kaizen.sesion_mx_norte USING btree (region, familia);


--
-- Name: sesion_mx_norte_region_usuario_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE INDEX sesion_mx_norte_region_usuario_id_idx ON kaizen.sesion_mx_norte USING btree (region, usuario_id) WHERE (revocada_en IS NULL);


--
-- Name: ux_sugerencia_pendiente; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX ux_sugerencia_pendiente ON ONLY kaizen.sugerencia_ajuste USING btree (region, habito_id) WHERE (estado = 'pendiente'::text);


--
-- Name: sugerencia_ajuste_latam_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX sugerencia_ajuste_latam_region_habito_id_idx ON kaizen.sugerencia_ajuste_latam USING btree (region, habito_id) WHERE (estado = 'pendiente'::text);


--
-- Name: sugerencia_ajuste_mx_centro_sur_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX sugerencia_ajuste_mx_centro_sur_region_habito_id_idx ON kaizen.sugerencia_ajuste_mx_centro_sur USING btree (region, habito_id) WHERE (estado = 'pendiente'::text);


--
-- Name: sugerencia_ajuste_mx_norte_region_habito_id_idx; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX sugerencia_ajuste_mx_norte_region_habito_id_idx ON kaizen.sugerencia_ajuste_mx_norte USING btree (region, habito_id) WHERE (estado = 'pendiente'::text);


--
-- Name: ux_categoria_nombre_ci; Type: INDEX; Schema: kaizen; Owner: kaizen_owner
--

CREATE UNIQUE INDEX ux_categoria_nombre_ci ON kaizen.categoria USING btree (lower(nombre));


--
-- Name: bitacora_2026_11_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_2026_11_accion_fecha_idx;


--
-- Name: bitacora_2026_11_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_2026_11_pkey;


--
-- Name: bitacora_2026_11_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_2026_11_usuario_id_fecha_idx;


--
-- Name: bitacora_2026_12_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_2026_12_accion_fecha_idx;


--
-- Name: bitacora_2026_12_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_2026_12_pkey;


--
-- Name: bitacora_2026_12_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_2026_12_usuario_id_fecha_idx;


--
-- Name: bitacora_2027_01_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_2027_01_accion_fecha_idx;


--
-- Name: bitacora_2027_01_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_2027_01_pkey;


--
-- Name: bitacora_2027_01_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_2027_01_usuario_id_fecha_idx;


--
-- Name: bitacora_2027_02_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_2027_02_accion_fecha_idx;


--
-- Name: bitacora_2027_02_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_2027_02_pkey;


--
-- Name: bitacora_2027_02_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_2027_02_usuario_id_fecha_idx;


--
-- Name: bitacora_2027_03_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_2027_03_accion_fecha_idx;


--
-- Name: bitacora_2027_03_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_2027_03_pkey;


--
-- Name: bitacora_2027_03_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_2027_03_usuario_id_fecha_idx;


--
-- Name: bitacora_2027_04_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_2027_04_accion_fecha_idx;


--
-- Name: bitacora_2027_04_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_2027_04_pkey;


--
-- Name: bitacora_2027_04_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_2027_04_usuario_id_fecha_idx;


--
-- Name: bitacora_2027_05_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_2027_05_accion_fecha_idx;


--
-- Name: bitacora_2027_05_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_2027_05_pkey;


--
-- Name: bitacora_2027_05_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_2027_05_usuario_id_fecha_idx;


--
-- Name: bitacora_2027_06_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_2027_06_accion_fecha_idx;


--
-- Name: bitacora_2027_06_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_2027_06_pkey;


--
-- Name: bitacora_2027_06_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_2027_06_usuario_id_fecha_idx;


--
-- Name: bitacora_default_accion_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_fallos ATTACH PARTITION kaizen.bitacora_default_accion_fecha_idx;


--
-- Name: bitacora_default_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.bitacora_auditoria_pkey ATTACH PARTITION kaizen.bitacora_default_pkey;


--
-- Name: bitacora_default_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_bitacora_usuario ATTACH PARTITION kaizen.bitacora_default_usuario_id_fecha_idx;


--
-- Name: capsula_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.capsula_pkey ATTACH PARTITION kaizen.capsula_latam_pkey;


--
-- Name: capsula_latam_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_capsula_habito ATTACH PARTITION kaizen.capsula_latam_region_habito_id_idx;


--
-- Name: capsula_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.capsula_pkey ATTACH PARTITION kaizen.capsula_mx_centro_sur_pkey;


--
-- Name: capsula_mx_centro_sur_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_capsula_habito ATTACH PARTITION kaizen.capsula_mx_centro_sur_region_habito_id_idx;


--
-- Name: capsula_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.capsula_pkey ATTACH PARTITION kaizen.capsula_mx_norte_pkey;


--
-- Name: capsula_mx_norte_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_capsula_habito ATTACH PARTITION kaizen.capsula_mx_norte_region_habito_id_idx;


--
-- Name: habito_latam_categoria_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_habito_categoria ATTACH PARTITION kaizen.habito_latam_categoria_id_idx;


--
-- Name: habito_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.habito_pkey ATTACH PARTITION kaizen.habito_latam_pkey;


--
-- Name: habito_latam_region_id_usuario_id_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.habito_region_id_usuario_id_key ATTACH PARTITION kaizen.habito_latam_region_id_usuario_id_key;


--
-- Name: habito_latam_region_usuario_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_habito_usuario ATTACH PARTITION kaizen.habito_latam_region_usuario_id_idx;


--
-- Name: habito_mx_centro_sur_categoria_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_habito_categoria ATTACH PARTITION kaizen.habito_mx_centro_sur_categoria_id_idx;


--
-- Name: habito_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.habito_pkey ATTACH PARTITION kaizen.habito_mx_centro_sur_pkey;


--
-- Name: habito_mx_centro_sur_region_id_usuario_id_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.habito_region_id_usuario_id_key ATTACH PARTITION kaizen.habito_mx_centro_sur_region_id_usuario_id_key;


--
-- Name: habito_mx_centro_sur_region_usuario_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_habito_usuario ATTACH PARTITION kaizen.habito_mx_centro_sur_region_usuario_id_idx;


--
-- Name: habito_mx_norte_categoria_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_habito_categoria ATTACH PARTITION kaizen.habito_mx_norte_categoria_id_idx;


--
-- Name: habito_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.habito_pkey ATTACH PARTITION kaizen.habito_mx_norte_pkey;


--
-- Name: habito_mx_norte_region_id_usuario_id_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.habito_region_id_usuario_id_key ATTACH PARTITION kaizen.habito_mx_norte_region_id_usuario_id_key;


--
-- Name: habito_mx_norte_region_usuario_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_habito_usuario ATTACH PARTITION kaizen.habito_mx_norte_region_usuario_id_idx;


--
-- Name: nivel_habito_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.nivel_habito_pkey ATTACH PARTITION kaizen.nivel_habito_latam_pkey;


--
-- Name: nivel_habito_latam_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ux_nivel_vigente ATTACH PARTITION kaizen.nivel_habito_latam_region_habito_id_idx;


--
-- Name: nivel_habito_latam_region_habito_id_vigente_desde_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_nivel_habito ATTACH PARTITION kaizen.nivel_habito_latam_region_habito_id_vigente_desde_idx;


--
-- Name: nivel_habito_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.nivel_habito_pkey ATTACH PARTITION kaizen.nivel_habito_mx_centro_sur_pkey;


--
-- Name: nivel_habito_mx_centro_sur_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ux_nivel_vigente ATTACH PARTITION kaizen.nivel_habito_mx_centro_sur_region_habito_id_idx;


--
-- Name: nivel_habito_mx_centro_sur_region_habito_id_vigente_desde_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_nivel_habito ATTACH PARTITION kaizen.nivel_habito_mx_centro_sur_region_habito_id_vigente_desde_idx;


--
-- Name: nivel_habito_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.nivel_habito_pkey ATTACH PARTITION kaizen.nivel_habito_mx_norte_pkey;


--
-- Name: nivel_habito_mx_norte_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ux_nivel_vigente ATTACH PARTITION kaizen.nivel_habito_mx_norte_region_habito_id_idx;


--
-- Name: nivel_habito_mx_norte_region_habito_id_vigente_desde_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_nivel_habito ATTACH PARTITION kaizen.nivel_habito_mx_norte_region_habito_id_vigente_desde_idx;


--
-- Name: racha_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.racha_pkey ATTACH PARTITION kaizen.racha_latam_pkey;


--
-- Name: racha_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.racha_pkey ATTACH PARTITION kaizen.racha_mx_centro_sur_pkey;


--
-- Name: racha_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.racha_pkey ATTACH PARTITION kaizen.racha_mx_norte_pkey;


--
-- Name: registro_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.registro_pkey ATTACH PARTITION kaizen.registro_latam_pkey;


--
-- Name: registro_latam_region_habito_id_fecha_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.registro_region_habito_id_fecha_key ATTACH PARTITION kaizen.registro_latam_region_habito_id_fecha_key;


--
-- Name: registro_latam_region_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_registro_usuario_fecha ATTACH PARTITION kaizen.registro_latam_region_usuario_id_fecha_idx;


--
-- Name: registro_latam_registrado_en_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_registro_registrado_brin ATTACH PARTITION kaizen.registro_latam_registrado_en_idx;


--
-- Name: registro_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.registro_pkey ATTACH PARTITION kaizen.registro_mx_centro_sur_pkey;


--
-- Name: registro_mx_centro_sur_region_habito_id_fecha_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.registro_region_habito_id_fecha_key ATTACH PARTITION kaizen.registro_mx_centro_sur_region_habito_id_fecha_key;


--
-- Name: registro_mx_centro_sur_region_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_registro_usuario_fecha ATTACH PARTITION kaizen.registro_mx_centro_sur_region_usuario_id_fecha_idx;


--
-- Name: registro_mx_centro_sur_registrado_en_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_registro_registrado_brin ATTACH PARTITION kaizen.registro_mx_centro_sur_registrado_en_idx;


--
-- Name: registro_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.registro_pkey ATTACH PARTITION kaizen.registro_mx_norte_pkey;


--
-- Name: registro_mx_norte_region_habito_id_fecha_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.registro_region_habito_id_fecha_key ATTACH PARTITION kaizen.registro_mx_norte_region_habito_id_fecha_key;


--
-- Name: registro_mx_norte_region_usuario_id_fecha_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_registro_usuario_fecha ATTACH PARTITION kaizen.registro_mx_norte_region_usuario_id_fecha_idx;


--
-- Name: registro_mx_norte_registrado_en_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_registro_registrado_brin ATTACH PARTITION kaizen.registro_mx_norte_registrado_en_idx;


--
-- Name: senal_diaria_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.senal_diaria_pkey ATTACH PARTITION kaizen.senal_diaria_latam_pkey;


--
-- Name: senal_diaria_latam_region_usuario_id_fecha_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.senal_diaria_region_usuario_id_fecha_key ATTACH PARTITION kaizen.senal_diaria_latam_region_usuario_id_fecha_key;


--
-- Name: senal_diaria_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.senal_diaria_pkey ATTACH PARTITION kaizen.senal_diaria_mx_centro_sur_pkey;


--
-- Name: senal_diaria_mx_centro_sur_region_usuario_id_fecha_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.senal_diaria_region_usuario_id_fecha_key ATTACH PARTITION kaizen.senal_diaria_mx_centro_sur_region_usuario_id_fecha_key;


--
-- Name: senal_diaria_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.senal_diaria_pkey ATTACH PARTITION kaizen.senal_diaria_mx_norte_pkey;


--
-- Name: senal_diaria_mx_norte_region_usuario_id_fecha_key; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.senal_diaria_region_usuario_id_fecha_key ATTACH PARTITION kaizen.senal_diaria_mx_norte_region_usuario_id_fecha_key;


--
-- Name: sesion_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.sesion_pkey ATTACH PARTITION kaizen.sesion_latam_pkey;


--
-- Name: sesion_latam_region_familia_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_sesion_familia ATTACH PARTITION kaizen.sesion_latam_region_familia_idx;


--
-- Name: sesion_latam_region_usuario_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_sesion_usuario ATTACH PARTITION kaizen.sesion_latam_region_usuario_id_idx;


--
-- Name: sesion_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.sesion_pkey ATTACH PARTITION kaizen.sesion_mx_centro_sur_pkey;


--
-- Name: sesion_mx_centro_sur_region_familia_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_sesion_familia ATTACH PARTITION kaizen.sesion_mx_centro_sur_region_familia_idx;


--
-- Name: sesion_mx_centro_sur_region_usuario_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_sesion_usuario ATTACH PARTITION kaizen.sesion_mx_centro_sur_region_usuario_id_idx;


--
-- Name: sesion_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.sesion_pkey ATTACH PARTITION kaizen.sesion_mx_norte_pkey;


--
-- Name: sesion_mx_norte_region_familia_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_sesion_familia ATTACH PARTITION kaizen.sesion_mx_norte_region_familia_idx;


--
-- Name: sesion_mx_norte_region_usuario_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ix_sesion_usuario ATTACH PARTITION kaizen.sesion_mx_norte_region_usuario_id_idx;


--
-- Name: sugerencia_ajuste_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.sugerencia_ajuste_pkey ATTACH PARTITION kaizen.sugerencia_ajuste_latam_pkey;


--
-- Name: sugerencia_ajuste_latam_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ux_sugerencia_pendiente ATTACH PARTITION kaizen.sugerencia_ajuste_latam_region_habito_id_idx;


--
-- Name: sugerencia_ajuste_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.sugerencia_ajuste_pkey ATTACH PARTITION kaizen.sugerencia_ajuste_mx_centro_sur_pkey;


--
-- Name: sugerencia_ajuste_mx_centro_sur_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ux_sugerencia_pendiente ATTACH PARTITION kaizen.sugerencia_ajuste_mx_centro_sur_region_habito_id_idx;


--
-- Name: sugerencia_ajuste_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.sugerencia_ajuste_pkey ATTACH PARTITION kaizen.sugerencia_ajuste_mx_norte_pkey;


--
-- Name: sugerencia_ajuste_mx_norte_region_habito_id_idx; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.ux_sugerencia_pendiente ATTACH PARTITION kaizen.sugerencia_ajuste_mx_norte_region_habito_id_idx;


--
-- Name: usuario_latam_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.usuario_pkey ATTACH PARTITION kaizen.usuario_latam_pkey;


--
-- Name: usuario_mx_centro_sur_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.usuario_pkey ATTACH PARTITION kaizen.usuario_mx_centro_sur_pkey;


--
-- Name: usuario_mx_norte_pkey; Type: INDEX ATTACH; Schema: kaizen; Owner: kaizen_owner
--

ALTER INDEX kaizen.usuario_pkey ATTACH PARTITION kaizen.usuario_mx_norte_pkey;


--
-- Name: bitacora_auditoria trg_bitacora_inmutable; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_bitacora_inmutable BEFORE DELETE OR UPDATE ON kaizen.bitacora_auditoria FOR EACH ROW EXECUTE FUNCTION kaizen.tg_bitacora_inmutable();


--
-- Name: bitacora_auditoria trg_bitacora_sin_truncate; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_bitacora_sin_truncate BEFORE TRUNCATE ON kaizen.bitacora_auditoria FOR EACH STATEMENT EXECUTE FUNCTION kaizen.tg_bitacora_inmutable();


--
-- Name: capsula trg_capsula_guardia; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_capsula_guardia BEFORE INSERT OR UPDATE ON kaizen.capsula FOR EACH ROW EXECUTE FUNCTION kaizen.tg_capsula_guardia();


--
-- Name: habito trg_habito_categoria_activa; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_habito_categoria_activa BEFORE INSERT OR UPDATE OF categoria_id ON kaizen.habito FOR EACH ROW EXECUTE FUNCTION kaizen.tg_habito_categoria_activa();


--
-- Name: habito trg_habito_expira_sugerencias; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_habito_expira_sugerencias AFTER UPDATE OF escalera_activa, activo ON kaizen.habito FOR EACH ROW WHEN (((old.escalera_activa AND (NOT new.escalera_activa)) OR (old.activo AND (NOT new.activo)))) EXECUTE FUNCTION kaizen.tg_habito_expira_sugerencias();


--
-- Name: habito trg_habito_guardia; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_habito_guardia BEFORE UPDATE ON kaizen.habito FOR EACH ROW EXECUTE FUNCTION kaizen.tg_habito_guardia();


--
-- Name: habito trg_habito_inicial; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_habito_inicial AFTER INSERT ON kaizen.habito FOR EACH ROW EXECUTE FUNCTION kaizen.tg_habito_inicial();


--
-- Name: nivel_habito trg_nivel_cierra_anterior; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_nivel_cierra_anterior BEFORE INSERT ON kaizen.nivel_habito FOR EACH ROW EXECUTE FUNCTION kaizen.tg_nivel_cierra_anterior();


--
-- Name: nivel_habito trg_nivel_sincroniza_meta; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_nivel_sincroniza_meta AFTER INSERT ON kaizen.nivel_habito FOR EACH ROW EXECUTE FUNCTION kaizen.tg_nivel_sincroniza_meta();


--
-- Name: registro trg_registro_a_valida_ins; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_registro_a_valida_ins AFTER INSERT ON kaizen.registro REFERENCING NEW TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION kaizen.tg_registro_valida_lote();


--
-- Name: registro trg_registro_a_valida_upd; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_registro_a_valida_upd AFTER UPDATE ON kaizen.registro REFERENCING NEW TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION kaizen.tg_registro_valida_lote();


--
-- Name: registro trg_registro_inmutables; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_registro_inmutables BEFORE UPDATE ON kaizen.registro FOR EACH ROW EXECUTE FUNCTION kaizen.tg_registro_inmutables();


--
-- Name: registro trg_registro_racha_del; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_registro_racha_del AFTER DELETE ON kaizen.registro REFERENCING OLD TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION kaizen.tg_registro_racha();


--
-- Name: registro trg_registro_racha_ins; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_registro_racha_ins AFTER INSERT ON kaizen.registro REFERENCING NEW TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION kaizen.tg_registro_racha();


--
-- Name: registro trg_registro_racha_upd; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_registro_racha_upd AFTER UPDATE ON kaizen.registro REFERENCING NEW TABLE AS cambios FOR EACH STATEMENT EXECUTE FUNCTION kaizen.tg_registro_racha();


--
-- Name: senal_diaria trg_senal_consentimiento; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_senal_consentimiento BEFORE INSERT OR UPDATE ON kaizen.senal_diaria FOR EACH ROW EXECUTE FUNCTION kaizen.tg_senal_consentimiento();


--
-- Name: sesion trg_sesion_cuenta_activa; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_sesion_cuenta_activa BEFORE INSERT ON kaizen.sesion FOR EACH ROW EXECUTE FUNCTION kaizen.tg_sesion_cuenta_activa();


--
-- Name: sugerencia_ajuste trg_sugerencia_estado; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_sugerencia_estado BEFORE UPDATE ON kaizen.sugerencia_ajuste FOR EACH ROW EXECUTE FUNCTION kaizen.tg_sugerencia_estado();


--
-- Name: usuario trg_usuario_guardia; Type: TRIGGER; Schema: kaizen; Owner: kaizen_owner
--

CREATE TRIGGER trg_usuario_guardia BEFORE UPDATE ON kaizen.usuario FOR EACH ROW EXECUTE FUNCTION kaizen.tg_usuario_guardia();


--
-- Name: capsula capsula_region_habito_id_usuario_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.capsula
    ADD CONSTRAINT capsula_region_habito_id_usuario_id_fkey FOREIGN KEY (region, habito_id, usuario_id) REFERENCES kaizen.habito(region, id, usuario_id) ON DELETE CASCADE;


--
-- Name: directorio_usuarios directorio_usuarios_region_usuario_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.directorio_usuarios
    ADD CONSTRAINT directorio_usuarios_region_usuario_id_fkey FOREIGN KEY (region, usuario_id) REFERENCES kaizen.usuario(region, id) ON DELETE CASCADE;


--
-- Name: habito habito_categoria_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.habito
    ADD CONSTRAINT habito_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES kaizen.categoria(id);


--
-- Name: habito habito_region_usuario_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.habito
    ADD CONSTRAINT habito_region_usuario_id_fkey FOREIGN KEY (region, usuario_id) REFERENCES kaizen.usuario(region, id) ON DELETE CASCADE;


--
-- Name: nivel_habito nivel_habito_region_habito_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.nivel_habito
    ADD CONSTRAINT nivel_habito_region_habito_id_fkey FOREIGN KEY (region, habito_id) REFERENCES kaizen.habito(region, id) ON DELETE CASCADE;


--
-- Name: racha racha_region_habito_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.racha
    ADD CONSTRAINT racha_region_habito_id_fkey FOREIGN KEY (region, habito_id) REFERENCES kaizen.habito(region, id) ON DELETE CASCADE;


--
-- Name: recuperacion_contrasena recuperacion_contrasena_region_usuario_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE ONLY kaizen.recuperacion_contrasena
    ADD CONSTRAINT recuperacion_contrasena_region_usuario_id_fkey FOREIGN KEY (region, usuario_id) REFERENCES kaizen.usuario(region, id) ON DELETE CASCADE;


--
-- Name: registro registro_region_habito_id_usuario_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.registro
    ADD CONSTRAINT registro_region_habito_id_usuario_id_fkey FOREIGN KEY (region, habito_id, usuario_id) REFERENCES kaizen.habito(region, id, usuario_id) ON DELETE CASCADE;


--
-- Name: senal_diaria senal_diaria_region_usuario_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.senal_diaria
    ADD CONSTRAINT senal_diaria_region_usuario_id_fkey FOREIGN KEY (region, usuario_id) REFERENCES kaizen.usuario(region, id) ON DELETE CASCADE;


--
-- Name: sesion sesion_region_usuario_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.sesion
    ADD CONSTRAINT sesion_region_usuario_id_fkey FOREIGN KEY (region, usuario_id) REFERENCES kaizen.usuario(region, id) ON DELETE CASCADE;


--
-- Name: sugerencia_ajuste sugerencia_ajuste_region_habito_id_fkey; Type: FK CONSTRAINT; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.sugerencia_ajuste
    ADD CONSTRAINT sugerencia_ajuste_region_habito_id_fkey FOREIGN KEY (region, habito_id) REFERENCES kaizen.habito(region, id) ON DELETE CASCADE;


--
-- Name: capsula; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.capsula ENABLE ROW LEVEL SECURITY;

--
-- Name: habito; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.habito ENABLE ROW LEVEL SECURITY;

--
-- Name: nivel_habito; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.nivel_habito ENABLE ROW LEVEL SECURITY;

--
-- Name: capsula pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.capsula TO kaizen_api USING ((usuario_id = kaizen.fn_usuario_actual())) WITH CHECK ((usuario_id = kaizen.fn_usuario_actual()));


--
-- Name: habito pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.habito TO kaizen_api USING ((usuario_id = kaizen.fn_usuario_actual())) WITH CHECK ((usuario_id = kaizen.fn_usuario_actual()));


--
-- Name: nivel_habito pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.nivel_habito TO kaizen_api USING ((EXISTS ( SELECT 1
   FROM kaizen.habito h
  WHERE (((h.region)::text = (nivel_habito.region)::text) AND (h.id = nivel_habito.habito_id)))));


--
-- Name: racha pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.racha TO kaizen_api USING ((EXISTS ( SELECT 1
   FROM kaizen.habito h
  WHERE (((h.region)::text = (racha.region)::text) AND (h.id = racha.habito_id)))));


--
-- Name: registro pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.registro TO kaizen_api USING ((usuario_id = kaizen.fn_usuario_actual())) WITH CHECK ((usuario_id = kaizen.fn_usuario_actual()));


--
-- Name: senal_diaria pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.senal_diaria TO kaizen_api USING ((usuario_id = kaizen.fn_usuario_actual())) WITH CHECK ((usuario_id = kaizen.fn_usuario_actual()));


--
-- Name: sesion pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.sesion TO kaizen_api USING ((usuario_id = kaizen.fn_usuario_actual())) WITH CHECK ((usuario_id = kaizen.fn_usuario_actual()));


--
-- Name: sugerencia_ajuste pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.sugerencia_ajuste TO kaizen_api USING ((EXISTS ( SELECT 1
   FROM kaizen.habito h
  WHERE (((h.region)::text = (sugerencia_ajuste.region)::text) AND (h.id = sugerencia_ajuste.habito_id)))));


--
-- Name: usuario pol_dueno; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_dueno ON kaizen.usuario TO kaizen_api USING ((id = kaizen.fn_usuario_actual())) WITH CHECK ((id = kaizen.fn_usuario_actual()));


--
-- Name: capsula pol_lectura_global; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_lectura_global ON kaizen.capsula FOR SELECT TO kaizen_admin, kaizen_etl USING (true);


--
-- Name: habito pol_lectura_global; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_lectura_global ON kaizen.habito FOR SELECT TO kaizen_admin, kaizen_etl USING (true);


--
-- Name: nivel_habito pol_lectura_global; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_lectura_global ON kaizen.nivel_habito FOR SELECT TO kaizen_admin, kaizen_etl USING (true);


--
-- Name: racha pol_lectura_global; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_lectura_global ON kaizen.racha FOR SELECT TO kaizen_admin, kaizen_etl USING (true);


--
-- Name: registro pol_lectura_global; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_lectura_global ON kaizen.registro FOR SELECT TO kaizen_admin, kaizen_etl USING (true);


--
-- Name: senal_diaria pol_lectura_global; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_lectura_global ON kaizen.senal_diaria FOR SELECT TO kaizen_admin, kaizen_etl USING (true);


--
-- Name: sugerencia_ajuste pol_lectura_global; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_lectura_global ON kaizen.sugerencia_ajuste FOR SELECT TO kaizen_admin, kaizen_etl USING (true);


--
-- Name: usuario pol_lectura_global; Type: POLICY; Schema: kaizen; Owner: kaizen_owner
--

CREATE POLICY pol_lectura_global ON kaizen.usuario FOR SELECT TO kaizen_admin, kaizen_etl USING (true);


--
-- Name: racha; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.racha ENABLE ROW LEVEL SECURITY;

--
-- Name: recuperacion_contrasena; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.recuperacion_contrasena ENABLE ROW LEVEL SECURITY;

--
-- Name: registro; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.registro ENABLE ROW LEVEL SECURITY;

--
-- Name: senal_diaria; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.senal_diaria ENABLE ROW LEVEL SECURITY;

--
-- Name: sesion; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.sesion ENABLE ROW LEVEL SECURITY;

--
-- Name: sugerencia_ajuste; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.sugerencia_ajuste ENABLE ROW LEVEL SECURITY;

--
-- Name: usuario; Type: ROW SECURITY; Schema: kaizen; Owner: kaizen_owner
--

ALTER TABLE kaizen.usuario ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA kaizen; Type: ACL; Schema: -; Owner: kaizen_owner
--

GRANT USAGE ON SCHEMA kaizen TO kaizen_api;
GRANT USAGE ON SCHEMA kaizen TO kaizen_etl;
GRANT USAGE ON SCHEMA kaizen TO kaizen_monitor;
GRANT USAGE ON SCHEMA kaizen TO kaizen_admin;
GRANT USAGE ON SCHEMA kaizen TO kaizen_tareas;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- Name: FUNCTION fn_auditar(p_usuario uuid, p_region kaizen.region_t, p_accion text, p_recurso text, p_resultado text, p_ip inet); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.fn_auditar(p_usuario uuid, p_region kaizen.region_t, p_accion text, p_recurso text, p_resultado text, p_ip inet) FROM PUBLIC;


--
-- Name: FUNCTION fn_cumplimiento(p_region kaizen.region_t, p_habito uuid, p_dias integer, p_hasta date); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.fn_cumplimiento(p_region kaizen.region_t, p_habito uuid, p_dias integer, p_hasta date) FROM PUBLIC;
GRANT ALL ON FUNCTION kaizen.fn_cumplimiento(p_region kaizen.region_t, p_habito uuid, p_dias integer, p_hasta date) TO kaizen_api;
GRANT ALL ON FUNCTION kaizen.fn_cumplimiento(p_region kaizen.region_t, p_habito uuid, p_dias integer, p_hasta date) TO kaizen_etl;
GRANT ALL ON FUNCTION kaizen.fn_cumplimiento(p_region kaizen.region_t, p_habito uuid, p_dias integer, p_hasta date) TO kaizen_admin;


--
-- Name: FUNCTION fn_dia_programado(p_tipo text, p_dias smallint, p_fecha date); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.fn_dia_programado(p_tipo text, p_dias smallint, p_fecha date) FROM PUBLIC;
GRANT ALL ON FUNCTION kaizen.fn_dia_programado(p_tipo text, p_dias smallint, p_fecha date) TO kaizen_api;
GRANT ALL ON FUNCTION kaizen.fn_dia_programado(p_tipo text, p_dias smallint, p_fecha date) TO kaizen_etl;
GRANT ALL ON FUNCTION kaizen.fn_dia_programado(p_tipo text, p_dias smallint, p_fecha date) TO kaizen_admin;


--
-- Name: FUNCTION fn_dia_programado_anterior(p_tipo text, p_dias smallint, p_fecha date); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.fn_dia_programado_anterior(p_tipo text, p_dias smallint, p_fecha date) FROM PUBLIC;
GRANT ALL ON FUNCTION kaizen.fn_dia_programado_anterior(p_tipo text, p_dias smallint, p_fecha date) TO kaizen_api;
GRANT ALL ON FUNCTION kaizen.fn_dia_programado_anterior(p_tipo text, p_dias smallint, p_fecha date) TO kaizen_admin;


--
-- Name: FUNCTION fn_rachas(p_region kaizen.region_t, p_habito uuid, p_desde date, OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.fn_rachas(p_region kaizen.region_t, p_habito uuid, p_desde date, OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date) FROM PUBLIC;
GRANT ALL ON FUNCTION kaizen.fn_rachas(p_region kaizen.region_t, p_habito uuid, p_desde date, OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date) TO kaizen_api;
GRANT ALL ON FUNCTION kaizen.fn_rachas(p_region kaizen.region_t, p_habito uuid, p_desde date, OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date) TO kaizen_etl;
GRANT ALL ON FUNCTION kaizen.fn_rachas(p_region kaizen.region_t, p_habito uuid, p_desde date, OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date) TO kaizen_admin;


--
-- Name: FUNCTION fn_region(p_pais character, p_estado text); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.fn_region(p_pais character, p_estado text) FROM PUBLIC;
GRANT ALL ON FUNCTION kaizen.fn_region(p_pais character, p_estado text) TO kaizen_api;


--
-- Name: FUNCTION fn_usuario_actual(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT ALL ON FUNCTION kaizen.fn_usuario_actual() TO kaizen_api;


--
-- Name: FUNCTION fn_verificar_admin(p_admin uuid); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.fn_verificar_admin(p_admin uuid) FROM PUBLIC;


--
-- Name: PROCEDURE sp_abrir_capsula(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_capsula uuid, INOUT p_mensaje_cifrado bytea, INOUT p_llave_version smallint); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_abrir_capsula(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_capsula uuid, INOUT p_mensaje_cifrado bytea, INOUT p_llave_version smallint) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_abrir_capsula(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_capsula uuid, INOUT p_mensaje_cifrado bytea, INOUT p_llave_version smallint) TO kaizen_api;


--
-- Name: PROCEDURE sp_admin_actualizar_categoria(IN p_admin uuid, IN p_id uuid, IN p_nombre text, IN p_activa boolean, IN p_ip inet); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_admin_actualizar_categoria(IN p_admin uuid, IN p_id uuid, IN p_nombre text, IN p_activa boolean, IN p_ip inet) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_admin_actualizar_categoria(IN p_admin uuid, IN p_id uuid, IN p_nombre text, IN p_activa boolean, IN p_ip inet) TO kaizen_api;


--
-- Name: PROCEDURE sp_admin_crear_categoria(IN p_admin uuid, IN p_nombre text, IN p_ip inet, INOUT p_id uuid); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_admin_crear_categoria(IN p_admin uuid, IN p_nombre text, IN p_ip inet, INOUT p_id uuid) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_admin_crear_categoria(IN p_admin uuid, IN p_nombre text, IN p_ip inet, INOUT p_id uuid) TO kaizen_api;


--
-- Name: PROCEDURE sp_admin_suspender_usuario(IN p_admin uuid, IN p_usuario uuid, IN p_suspender boolean, IN p_motivo text, IN p_ip inet); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_admin_suspender_usuario(IN p_admin uuid, IN p_usuario uuid, IN p_suspender boolean, IN p_motivo text, IN p_ip inet) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_admin_suspender_usuario(IN p_admin uuid, IN p_usuario uuid, IN p_suspender boolean, IN p_motivo text, IN p_ip inet) TO kaizen_api;


--
-- Name: PROCEDURE sp_crear_particion_bitacora(IN p_mes date); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_crear_particion_bitacora(IN p_mes date) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_crear_particion_bitacora(IN p_mes date) TO kaizen_admin;
GRANT ALL ON PROCEDURE kaizen.sp_crear_particion_bitacora(IN p_mes date) TO kaizen_tareas;


--
-- Name: PROCEDURE sp_eliminar_cuenta(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_ip inet); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_eliminar_cuenta(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_ip inet) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_eliminar_cuenta(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_ip inet) TO kaizen_api;


--
-- Name: PROCEDURE sp_generar_sugerencias(IN p_region kaizen.region_t, IN p_hoy date, INOUT p_creadas integer); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_generar_sugerencias(IN p_region kaizen.region_t, IN p_hoy date, INOUT p_creadas integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_generar_sugerencias(IN p_region kaizen.region_t, IN p_hoy date, INOUT p_creadas integer) TO kaizen_admin;
GRANT ALL ON PROCEDURE kaizen.sp_generar_sugerencias(IN p_region kaizen.region_t, IN p_hoy date, INOUT p_creadas integer) TO kaizen_tareas;


--
-- Name: PROCEDURE sp_limpiar_expirados(INOUT p_sesiones integer, INOUT p_tokens integer); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_limpiar_expirados(INOUT p_sesiones integer, INOUT p_tokens integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_limpiar_expirados(INOUT p_sesiones integer, INOUT p_tokens integer) TO kaizen_tareas;
GRANT ALL ON PROCEDURE kaizen.sp_limpiar_expirados(INOUT p_sesiones integer, INOUT p_tokens integer) TO kaizen_admin;


--
-- Name: PROCEDURE sp_reconstruir_rachas(IN p_region kaizen.region_t, INOUT p_corregidas integer); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_reconstruir_rachas(IN p_region kaizen.region_t, INOUT p_corregidas integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_reconstruir_rachas(IN p_region kaizen.region_t, INOUT p_corregidas integer) TO kaizen_admin;
GRANT ALL ON PROCEDURE kaizen.sp_reconstruir_rachas(IN p_region kaizen.region_t, INOUT p_corregidas integer) TO kaizen_tareas;


--
-- Name: PROCEDURE sp_registrar_checkin(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_id uuid, IN p_habito uuid, IN p_fecha date, IN p_cumplido boolean, IN p_valor numeric, IN p_origen text, INOUT p_racha_actual integer); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_registrar_checkin(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_id uuid, IN p_habito uuid, IN p_fecha date, IN p_cumplido boolean, IN p_valor numeric, IN p_origen text, INOUT p_racha_actual integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_registrar_checkin(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_id uuid, IN p_habito uuid, IN p_fecha date, IN p_cumplido boolean, IN p_valor numeric, IN p_origen text, INOUT p_racha_actual integer) TO kaizen_api;


--
-- Name: PROCEDURE sp_registrar_usuario(IN p_id uuid, IN p_email_hmac text, IN p_nombre text, IN p_email text, IN p_password_hash text, IN p_pais character, IN p_estado text, IN p_consiente_senales boolean, IN p_ip inet, INOUT p_region text); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_registrar_usuario(IN p_id uuid, IN p_email_hmac text, IN p_nombre text, IN p_email text, IN p_password_hash text, IN p_pais character, IN p_estado text, IN p_consiente_senales boolean, IN p_ip inet, INOUT p_region text) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_registrar_usuario(IN p_id uuid, IN p_email_hmac text, IN p_nombre text, IN p_email text, IN p_password_hash text, IN p_pais character, IN p_estado text, IN p_consiente_senales boolean, IN p_ip inet, INOUT p_region text) TO kaizen_api;


--
-- Name: PROCEDURE sp_responder_sugerencia(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_sugerencia uuid, IN p_aceptar boolean); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_responder_sugerencia(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_sugerencia uuid, IN p_aceptar boolean) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_responder_sugerencia(IN p_region kaizen.region_t, IN p_usuario uuid, IN p_sugerencia uuid, IN p_aceptar boolean) TO kaizen_api;


--
-- Name: PROCEDURE sp_restablecer_contrasena(IN p_token_hash text, IN p_password_hash text, IN p_ip inet); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_restablecer_contrasena(IN p_token_hash text, IN p_password_hash text, IN p_ip inet) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_restablecer_contrasena(IN p_token_hash text, IN p_password_hash text, IN p_ip inet) TO kaizen_api;


--
-- Name: PROCEDURE sp_retirar_consentimiento_senales(IN p_region kaizen.region_t, IN p_usuario uuid, INOUT p_borradas integer); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_retirar_consentimiento_senales(IN p_region kaizen.region_t, IN p_usuario uuid, INOUT p_borradas integer) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_retirar_consentimiento_senales(IN p_region kaizen.region_t, IN p_usuario uuid, INOUT p_borradas integer) TO kaizen_api;


--
-- Name: PROCEDURE sp_solicitar_recuperacion(IN p_email_hmac text, IN p_token_hash text, IN p_ip inet, INOUT p_enviar boolean, INOUT p_nombre text); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON PROCEDURE kaizen.sp_solicitar_recuperacion(IN p_email_hmac text, IN p_token_hash text, IN p_ip inet, INOUT p_enviar boolean, INOUT p_nombre text) FROM PUBLIC;
GRANT ALL ON PROCEDURE kaizen.sp_solicitar_recuperacion(IN p_email_hmac text, IN p_token_hash text, IN p_ip inet, INOUT p_enviar boolean, INOUT p_nombre text) TO kaizen_api;


--
-- Name: FUNCTION tg_bitacora_inmutable(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_bitacora_inmutable() FROM PUBLIC;


--
-- Name: FUNCTION tg_capsula_guardia(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_capsula_guardia() FROM PUBLIC;


--
-- Name: FUNCTION tg_habito_categoria_activa(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_habito_categoria_activa() FROM PUBLIC;


--
-- Name: FUNCTION tg_habito_expira_sugerencias(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_habito_expira_sugerencias() FROM PUBLIC;


--
-- Name: FUNCTION tg_habito_guardia(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_habito_guardia() FROM PUBLIC;


--
-- Name: FUNCTION tg_habito_inicial(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_habito_inicial() FROM PUBLIC;


--
-- Name: FUNCTION tg_nivel_cierra_anterior(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_nivel_cierra_anterior() FROM PUBLIC;


--
-- Name: FUNCTION tg_nivel_sincroniza_meta(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_nivel_sincroniza_meta() FROM PUBLIC;


--
-- Name: FUNCTION tg_registro_inmutables(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_registro_inmutables() FROM PUBLIC;


--
-- Name: FUNCTION tg_registro_racha(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_registro_racha() FROM PUBLIC;


--
-- Name: FUNCTION tg_registro_valida_lote(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_registro_valida_lote() FROM PUBLIC;


--
-- Name: FUNCTION tg_senal_consentimiento(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_senal_consentimiento() FROM PUBLIC;


--
-- Name: FUNCTION tg_sesion_cuenta_activa(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_sesion_cuenta_activa() FROM PUBLIC;


--
-- Name: FUNCTION tg_sugerencia_estado(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_sugerencia_estado() FROM PUBLIC;


--
-- Name: FUNCTION tg_usuario_guardia(); Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

REVOKE ALL ON FUNCTION kaizen.tg_usuario_guardia() FROM PUBLIC;


--
-- Name: TABLE bitacora_auditoria; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT ON TABLE kaizen.bitacora_auditoria TO kaizen_api;
GRANT SELECT ON TABLE kaizen.bitacora_auditoria TO kaizen_admin;


--
-- Name: TABLE bitacora_2026_11; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_2026_11 TO kaizen_admin;


--
-- Name: TABLE bitacora_2026_12; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_2026_12 TO kaizen_admin;


--
-- Name: TABLE bitacora_2027_01; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_2027_01 TO kaizen_admin;


--
-- Name: TABLE bitacora_2027_02; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_2027_02 TO kaizen_admin;


--
-- Name: TABLE bitacora_2027_03; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_2027_03 TO kaizen_admin;


--
-- Name: TABLE bitacora_2027_04; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_2027_04 TO kaizen_admin;


--
-- Name: TABLE bitacora_2027_05; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_2027_05 TO kaizen_admin;


--
-- Name: TABLE bitacora_2027_06; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_2027_06 TO kaizen_admin;


--
-- Name: TABLE bitacora_default; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.bitacora_default TO kaizen_admin;


--
-- Name: COLUMN capsula.id; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(id),INSERT(id) ON TABLE kaizen.capsula TO kaizen_api;
GRANT SELECT(id) ON TABLE kaizen.capsula TO kaizen_etl;


--
-- Name: COLUMN capsula.region; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(region),INSERT(region) ON TABLE kaizen.capsula TO kaizen_api;
GRANT SELECT(region) ON TABLE kaizen.capsula TO kaizen_etl;


--
-- Name: COLUMN capsula.habito_id; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(habito_id),INSERT(habito_id) ON TABLE kaizen.capsula TO kaizen_api;
GRANT SELECT(habito_id) ON TABLE kaizen.capsula TO kaizen_etl;


--
-- Name: COLUMN capsula.usuario_id; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(usuario_id),INSERT(usuario_id) ON TABLE kaizen.capsula TO kaizen_api;
GRANT SELECT(usuario_id) ON TABLE kaizen.capsula TO kaizen_etl;


--
-- Name: COLUMN capsula.mensaje_cifrado; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(mensaje_cifrado) ON TABLE kaizen.capsula TO kaizen_api;


--
-- Name: COLUMN capsula.llave_version; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(llave_version),INSERT(llave_version) ON TABLE kaizen.capsula TO kaizen_api;


--
-- Name: COLUMN capsula.tiene_foto; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(tiene_foto),INSERT(tiene_foto) ON TABLE kaizen.capsula TO kaizen_api;


--
-- Name: COLUMN capsula.racha_objetivo; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(racha_objetivo),INSERT(racha_objetivo) ON TABLE kaizen.capsula TO kaizen_api;
GRANT SELECT(racha_objetivo) ON TABLE kaizen.capsula TO kaizen_etl;


--
-- Name: COLUMN capsula.estado; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(estado) ON TABLE kaizen.capsula TO kaizen_api;
GRANT SELECT(estado) ON TABLE kaizen.capsula TO kaizen_etl;


--
-- Name: COLUMN capsula.creada_en; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(creada_en) ON TABLE kaizen.capsula TO kaizen_api;
GRANT SELECT(creada_en) ON TABLE kaizen.capsula TO kaizen_etl;


--
-- Name: COLUMN capsula.abierta_en; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(abierta_en) ON TABLE kaizen.capsula TO kaizen_api;
GRANT SELECT(abierta_en) ON TABLE kaizen.capsula TO kaizen_etl;


--
-- Name: TABLE capsula_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.capsula_latam TO kaizen_admin;


--
-- Name: TABLE capsula_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.capsula_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE capsula_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.capsula_mx_norte TO kaizen_admin;


--
-- Name: TABLE categoria; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.categoria TO kaizen_api;
GRANT SELECT ON TABLE kaizen.categoria TO kaizen_etl;
GRANT SELECT ON TABLE kaizen.categoria TO kaizen_admin;


--
-- Name: TABLE directorio_usuarios; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.directorio_usuarios TO kaizen_api;
GRANT SELECT ON TABLE kaizen.directorio_usuarios TO kaizen_admin;


--
-- Name: TABLE habito; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.habito TO kaizen_api;
GRANT SELECT ON TABLE kaizen.habito TO kaizen_etl;
GRANT SELECT ON TABLE kaizen.habito TO kaizen_admin;


--
-- Name: COLUMN habito.id; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(id) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.region; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(region) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.usuario_id; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(usuario_id) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.categoria_id; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(categoria_id),UPDATE(categoria_id) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.nombre; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(nombre),UPDATE(nombre) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.frecuencia_tipo; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(frecuencia_tipo) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.dias_semana; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(dias_semana) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.veces_semana; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(veces_semana) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.meta; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(meta) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.unidad; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(unidad),UPDATE(unidad) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.activo; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(activo) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: COLUMN habito.escalera_activa; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT INSERT(escalera_activa),UPDATE(escalera_activa) ON TABLE kaizen.habito TO kaizen_api;


--
-- Name: TABLE habito_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.habito_latam TO kaizen_admin;


--
-- Name: TABLE habito_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.habito_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE habito_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.habito_mx_norte TO kaizen_admin;


--
-- Name: TABLE nivel_habito; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.nivel_habito TO kaizen_api;
GRANT SELECT ON TABLE kaizen.nivel_habito TO kaizen_etl;
GRANT SELECT ON TABLE kaizen.nivel_habito TO kaizen_admin;


--
-- Name: TABLE nivel_habito_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.nivel_habito_latam TO kaizen_admin;


--
-- Name: TABLE nivel_habito_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.nivel_habito_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE nivel_habito_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.nivel_habito_mx_norte TO kaizen_admin;


--
-- Name: TABLE racha; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.racha TO kaizen_api;
GRANT SELECT ON TABLE kaizen.racha TO kaizen_etl;
GRANT SELECT ON TABLE kaizen.racha TO kaizen_admin;


--
-- Name: TABLE racha_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.racha_latam TO kaizen_admin;


--
-- Name: TABLE racha_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.racha_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE racha_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.racha_mx_norte TO kaizen_admin;


--
-- Name: TABLE registro; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.registro TO kaizen_api;
GRANT SELECT ON TABLE kaizen.registro TO kaizen_etl;
GRANT SELECT ON TABLE kaizen.registro TO kaizen_admin;


--
-- Name: TABLE registro_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.registro_latam TO kaizen_admin;


--
-- Name: TABLE registro_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.registro_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE registro_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.registro_mx_norte TO kaizen_admin;


--
-- Name: TABLE senal_diaria; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT,INSERT ON TABLE kaizen.senal_diaria TO kaizen_api;
GRANT SELECT ON TABLE kaizen.senal_diaria TO kaizen_etl;
GRANT SELECT ON TABLE kaizen.senal_diaria TO kaizen_admin;


--
-- Name: COLUMN senal_diaria.animo; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(animo) ON TABLE kaizen.senal_diaria TO kaizen_api;


--
-- Name: COLUMN senal_diaria.energia; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(energia) ON TABLE kaizen.senal_diaria TO kaizen_api;


--
-- Name: TABLE senal_diaria_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.senal_diaria_latam TO kaizen_admin;


--
-- Name: TABLE senal_diaria_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.senal_diaria_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE senal_diaria_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.senal_diaria_mx_norte TO kaizen_admin;


--
-- Name: TABLE sesion; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT,INSERT,DELETE ON TABLE kaizen.sesion TO kaizen_api;
GRANT SELECT ON TABLE kaizen.sesion TO kaizen_admin;


--
-- Name: COLUMN sesion.revocada_en; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(revocada_en) ON TABLE kaizen.sesion TO kaizen_api;


--
-- Name: COLUMN sesion.reemplazada_por; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(reemplazada_por) ON TABLE kaizen.sesion TO kaizen_api;


--
-- Name: TABLE sesion_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.sesion_latam TO kaizen_admin;


--
-- Name: TABLE sesion_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.sesion_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE sesion_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.sesion_mx_norte TO kaizen_admin;


--
-- Name: TABLE sugerencia_ajuste; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.sugerencia_ajuste TO kaizen_api;
GRANT SELECT ON TABLE kaizen.sugerencia_ajuste TO kaizen_etl;
GRANT SELECT ON TABLE kaizen.sugerencia_ajuste TO kaizen_admin;


--
-- Name: TABLE sugerencia_ajuste_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.sugerencia_ajuste_latam TO kaizen_admin;


--
-- Name: TABLE sugerencia_ajuste_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.sugerencia_ajuste_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE sugerencia_ajuste_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.sugerencia_ajuste_mx_norte TO kaizen_admin;


--
-- Name: TABLE usuario; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.usuario TO kaizen_api;
GRANT SELECT ON TABLE kaizen.usuario TO kaizen_admin;


--
-- Name: COLUMN usuario.id; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(id) ON TABLE kaizen.usuario TO kaizen_etl;


--
-- Name: COLUMN usuario.region; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(region) ON TABLE kaizen.usuario TO kaizen_etl;


--
-- Name: COLUMN usuario.nombre; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(nombre) ON TABLE kaizen.usuario TO kaizen_api;


--
-- Name: COLUMN usuario.password_hash; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(password_hash) ON TABLE kaizen.usuario TO kaizen_api;


--
-- Name: COLUMN usuario.pais; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(pais) ON TABLE kaizen.usuario TO kaizen_etl;


--
-- Name: COLUMN usuario.fecha_registro; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT(fecha_registro) ON TABLE kaizen.usuario TO kaizen_etl;


--
-- Name: COLUMN usuario.consentimiento_senales_en; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(consentimiento_senales_en) ON TABLE kaizen.usuario TO kaizen_api;


--
-- Name: COLUMN usuario.intentos_fallidos; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(intentos_fallidos) ON TABLE kaizen.usuario TO kaizen_api;


--
-- Name: COLUMN usuario.bloqueado_hasta; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT UPDATE(bloqueado_hasta) ON TABLE kaizen.usuario TO kaizen_api;


--
-- Name: TABLE usuario_latam; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.usuario_latam TO kaizen_admin;


--
-- Name: TABLE usuario_mx_centro_sur; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.usuario_mx_centro_sur TO kaizen_admin;


--
-- Name: TABLE usuario_mx_norte; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.usuario_mx_norte TO kaizen_admin;


--
-- Name: TABLE v_metricas_region; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.v_metricas_region TO kaizen_api;
GRANT SELECT ON TABLE kaizen.v_metricas_region TO kaizen_admin;


--
-- Name: TABLE v_racha_vigente; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.v_racha_vigente TO kaizen_api;
GRANT SELECT ON TABLE kaizen.v_racha_vigente TO kaizen_admin;


--
-- Name: TABLE v_usuario_admin; Type: ACL; Schema: kaizen; Owner: kaizen_owner
--

GRANT SELECT ON TABLE kaizen.v_usuario_admin TO kaizen_api;
GRANT SELECT ON TABLE kaizen.v_usuario_admin TO kaizen_admin;


--
-- PostgreSQL database dump complete
--

\unrestrict eBwfBdU1l3IqW8efDF2vKBD29BS9Wc4dlzPP1Uq4Lp0iuYadKCg1SjEIDJ3IPa0

