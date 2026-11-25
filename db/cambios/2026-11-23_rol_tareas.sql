-- =====================================================================
-- Kaizen · Rol para las tareas programadas (23-nov-2026)
-- Problema: nadie podía ejecutar las tareas de mantenimiento:
--   * sp_generar_sugerencias (Escalera diaria) solo la ejecutaban
--     kaizen_owner y kaizen_admin, que no inician sesión;
--   * kaizen_api no puede limpiar sesiones vencidas de todos los usuarios
--     (la RLS de sesion solo le deja ver las del usuario actual);
--   * sp_crear_particion_bitacora no era SECURITY DEFINER: fallaba para
--     cualquiera que no fuera el dueño de la tabla.
-- Solución: rol kaizen_tareas (LOGIN, solo desde nodo1, como la API) con
-- EXECUTE en 4 procedimientos y nada más (sin SELECT en ninguna tabla).
-- Se ejecuta como postgres en el PRIMARIO. La contraseña NO va aquí.
-- IA: asistido (Claude). Revisión: Jael Contreras.
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kaizen_tareas') THEN
        CREATE ROLE kaizen_tareas LOGIN NOINHERIT CONNECTION LIMIT 2;
    END IF;
END $$;
ALTER ROLE kaizen_tareas SET statement_timeout = '10min';
ALTER ROLE kaizen_tareas SET idle_in_transaction_session_timeout = '1min';
GRANT CONNECT ON DATABASE kaizen TO kaizen_tareas;

SET LOCAL ROLE kaizen_owner;
SET LOCAL search_path = kaizen, pg_temp;
GRANT USAGE ON SCHEMA kaizen TO kaizen_tareas;

-- Crear la partición del mes siguiente de la bitácora (la ejecuta el dueño de la tabla)
ALTER PROCEDURE sp_crear_particion_bitacora(date) SECURITY DEFINER;

-- Limpieza: sesiones vencidas y tokens de recuperación viejos
CREATE PROCEDURE sp_limpiar_expirados(
    INOUT p_sesiones integer DEFAULT 0,
    INOUT p_tokens   integer DEFAULT 0)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
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

REVOKE ALL ON PROCEDURE sp_limpiar_expirados FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE sp_generar_sugerencias, sp_crear_particion_bitacora,
                           sp_limpiar_expirados, sp_reconstruir_rachas TO kaizen_tareas;
GRANT EXECUTE ON PROCEDURE sp_limpiar_expirados TO kaizen_admin;

COMMIT;
