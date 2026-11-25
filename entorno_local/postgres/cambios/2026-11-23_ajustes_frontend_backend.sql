-- =====================================================================
-- Kaizen · Cambios de estructura del 23-nov-2026
-- Origen: revisión de frontend y backend (Ajustes_Frontend_Y_Backend/Contexto_y_Ajustes.md)
-- y decisiones de Jael del 23-nov-2026.
--
--   1. Escalera por hábito (D12): habito.escalera_activa
--   2. Suspensión de usuarios por un admin (B5)
--   3. Catálogo de categorías administrable (B6) + categoría inactiva no se usa
--   4. Recuperación de contraseña por correo (B4b)
--   5. Catálogo inicial de 8 categorías (D22)
--
-- Se ejecuta UNA vez sobre una base que ya tiene el esquema anterior, como
-- postgres (en el clúster: en el PRIMARIO). Todo en una transacción.
-- Códigos nuevos: KZ010 rol insuficiente · KZ011 dato inválido · KZ012 cuenta
-- suspendida · KZ013 nombre duplicado · KZ014 categoría inactiva ·
-- KZ015 enlace de recuperación inválido o vencido.
-- IA: asistido (Claude). Revisión: Jael Contreras.
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE kaizen_owner;                 -- los objetos nuevos quedan a nombre del dueño del esquema
SET LOCAL search_path = kaizen, pg_temp;

-- ---------------------------------------------------------------------
-- 1. Escalera por hábito (D12)
-- ---------------------------------------------------------------------
ALTER TABLE habito ADD COLUMN escalera_activa boolean NOT NULL DEFAULT true;
COMMENT ON COLUMN habito.escalera_activa IS
    'Si es false, sp_generar_sugerencias no propone ajustes para este hábito (interruptor "Escalera Kaizen").';
GRANT INSERT (escalera_activa), UPDATE (escalera_activa) ON habito TO kaizen_api;

-- Apagar la Escalera o archivar el hábito expira su sugerencia pendiente
CREATE FUNCTION tg_habito_expira_sugerencias() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    UPDATE sugerencia_ajuste SET estado = 'expirada'
     WHERE region = NEW.region AND habito_id = NEW.id AND estado = 'pendiente';
    RETURN NULL;
END;
$$;
CREATE TRIGGER trg_habito_expira_sugerencias AFTER UPDATE OF escalera_activa, activo ON habito
    FOR EACH ROW
    WHEN ((OLD.escalera_activa AND NOT NEW.escalera_activa) OR (OLD.activo AND NOT NEW.activo))
    EXECUTE FUNCTION tg_habito_expira_sugerencias();

-- P3 con el filtro nuevo (el resto queda igual)
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

-- ---------------------------------------------------------------------
-- 2. Suspensión de usuarios (B5)
-- ---------------------------------------------------------------------
ALTER TABLE usuario
    ADD COLUMN suspendido_en     timestamptz,
    ADD COLUMN suspension_motivo text CHECK (length(suspension_motivo) BETWEEN 3 AND 200),
    ADD CONSTRAINT suspension_coherente CHECK ((suspendido_en IS NULL) = (suspension_motivo IS NULL));
COMMENT ON COLUMN usuario.suspendido_en IS 'Suspensión administrativa (B5). Solo cambia con sp_admin_suspender_usuario.';

-- Interno: confirma que quien llama es admin activo y devuelve su región. No se concede a nadie.
CREATE FUNCTION fn_verificar_admin(p_admin uuid) RETURNS region_t
LANGUAGE plpgsql STABLE
SET search_path = kaizen, pg_temp
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

CREATE PROCEDURE sp_admin_suspender_usuario(
    p_admin      uuid,
    p_usuario    uuid,
    p_suspender  boolean,
    p_motivo     text DEFAULT NULL,
    p_ip         inet DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
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

-- Segunda barrera: una cuenta suspendida no puede abrir ni renovar sesiones
CREATE FUNCTION tg_sesion_cuenta_activa() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM usuario
                WHERE region = NEW.region AND id = NEW.usuario_id AND suspendido_en IS NOT NULL) THEN
        RAISE EXCEPTION 'La cuenta está suspendida' USING ERRCODE = 'KZ012';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_sesion_cuenta_activa BEFORE INSERT ON sesion
    FOR EACH ROW EXECUTE FUNCTION tg_sesion_cuenta_activa();

-- La vista del panel expone la suspensión (columnas nuevas al final)
CREATE OR REPLACE VIEW v_usuario_admin WITH (security_barrier) AS
SELECT id, region, pais, rol, fecha_registro,
       left(nombre, 1) || repeat('*', greatest(length(nombre) - 1, 2))          AS nombre_mascara,
       regexp_replace(email, '^(.)[^@]*@.*(\.[^.]+)$', '\1***@***\2')            AS email_mascara,
       (bloqueado_hasta > now())                                                AS bloqueado,
       (consentimiento_senales_en IS NOT NULL)                                  AS consiente_senales,
       (suspendido_en IS NOT NULL)                                              AS suspendido,
       suspendido_en,
       suspension_motivo
  FROM usuario;

-- ---------------------------------------------------------------------
-- 3. Catálogo de categorías (B6)
-- ---------------------------------------------------------------------
-- Sin duplicados que solo difieran en mayúsculas ("Ejercicio" / "ejercicio")
CREATE UNIQUE INDEX ux_categoria_nombre_ci ON categoria (lower(nombre));

CREATE PROCEDURE sp_admin_crear_categoria(
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

CREATE PROCEDURE sp_admin_actualizar_categoria(
    p_admin   uuid,
    p_id      uuid,
    p_nombre  text    DEFAULT NULL,
    p_activa  boolean DEFAULT NULL,
    p_ip      inet    DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
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

-- Un hábito nuevo (o que cambia de categoría) solo usa categorías activas.
-- Los hábitos que ya la tenían la conservan aunque se desactive.
CREATE FUNCTION tg_habito_categoria_activa() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
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
CREATE TRIGGER trg_habito_categoria_activa BEFORE INSERT OR UPDATE OF categoria_id ON habito
    FOR EACH ROW EXECUTE FUNCTION tg_habito_categoria_activa();

-- ---------------------------------------------------------------------
-- 4. Recuperación de contraseña por correo (B4b)
-- Tabla global (como directorio_usuarios): /auth/restablecer solo recibe el
-- token, sin región, así que se busca por su hash. Solo se guarda el
-- SHA-256 del token; el token en claro solo viaja en el correo.
-- ---------------------------------------------------------------------
CREATE TABLE recuperacion_contrasena (
    token_hash  hmac_hex    PRIMARY KEY,                -- SHA-256 en hex del token de 32 bytes
    region      region_t    NOT NULL,
    usuario_id  uuid        NOT NULL,
    creada_en   timestamptz NOT NULL DEFAULT now(),
    expira_en   timestamptz NOT NULL,
    usado_en    timestamptz,                            -- usado o invalidado por una solicitud más nueva
    ip          inet,
    CHECK (expira_en > creada_en),
    FOREIGN KEY (region, usuario_id) REFERENCES usuario (region, id) ON DELETE CASCADE
);
CREATE INDEX ix_recuperacion_usuario ON recuperacion_contrasena (region, usuario_id, creada_en DESC);
ALTER TABLE recuperacion_contrasena ENABLE ROW LEVEL SECURITY;   -- sin políticas: solo por procedimiento
COMMENT ON TABLE recuperacion_contrasena IS
    'Tokens de un solo uso para restablecer la contraseña (B4b). Vigencia 15 min; máximo 3 por hora por cuenta.';

CREATE PROCEDURE sp_solicitar_recuperacion(
    p_email_hmac  text,
    p_token_hash  text,
    p_ip          inet DEFAULT NULL,
    INOUT p_enviar boolean DEFAULT NULL,
    INOUT p_nombre text    DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
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

CREATE PROCEDURE sp_restablecer_contrasena(
    p_token_hash     text,
    p_password_hash  text,
    p_ip             inet DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
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

-- ---------------------------------------------------------------------
-- Permisos de los objetos nuevos (por omisión PUBLIC puede ejecutar funciones)
-- ---------------------------------------------------------------------
REVOKE ALL ON FUNCTION fn_verificar_admin(uuid), tg_habito_expira_sugerencias(), tg_sesion_cuenta_activa(),
                       tg_habito_categoria_activa() FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_admin_suspender_usuario, sp_admin_crear_categoria, sp_admin_actualizar_categoria,
                        sp_solicitar_recuperacion, sp_restablecer_contrasena FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE sp_admin_suspender_usuario, sp_admin_crear_categoria, sp_admin_actualizar_categoria,
                           sp_solicitar_recuperacion, sp_restablecer_contrasena TO kaizen_api;
REVOKE ALL ON recuperacion_contrasena FROM PUBLIC;

-- ---------------------------------------------------------------------
-- 5. Catálogo inicial (D22): bosquejos + carga demo
-- ---------------------------------------------------------------------
INSERT INTO categoria (nombre) VALUES
    ('Aprendizaje'), ('Salud'), ('Ejercicio'), ('Sueño'), ('Finanzas'),
    ('Hidratación'), ('Lectura'), ('Meditación')
ON CONFLICT DO NOTHING;

COMMIT;
