-- =====================================================================
-- Kaizen · 06_roles.sql
-- Usuarios, roles y privilegios (mínimo privilegio).
-- Ejecutar como administrador del clúster DESPUÉS de 01 a 05.
-- Las contraseñas NO van aquí: se asignan con \password o desde el
-- gestor de secretos (Ansible Vault / GitHub Secrets) y se guardan como
-- SCRAM-SHA-256 (password_encryption = scram-sha-256).
-- IA: asistido. Revisión: Jael Contreras.
-- =====================================================================
BEGIN;
SET search_path = kaizen, pg_temp;

-- ---------------------------------------------------------------------
-- Cuentas de servicio (una por componente)
-- ---------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kaizen_api') THEN
        CREATE ROLE kaizen_api LOGIN NOINHERIT CONNECTION LIMIT 40;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kaizen_etl') THEN
        CREATE ROLE kaizen_etl LOGIN NOINHERIT CONNECTION LIMIT 4;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kaizen_monitor') THEN
        -- INHERIT: debe heredar pg_monitor sin SET ROLE (postgres_exporter no lo hace)
        CREATE ROLE kaizen_monitor LOGIN INHERIT CONNECTION LIMIT 3;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'kaizen_admin') THEN
        CREATE ROLE kaizen_admin NOLOGIN;            -- grupo para personas (DBA)
    END IF;
END $$;

-- Las cuentas de servicio no deben poder crear objetos en public
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kaizen FROM PUBLIC;
REVOKE ALL ON ALL PROCEDURES IN SCHEMA kaizen FROM PUBLIC;

GRANT USAGE ON SCHEMA kaizen TO kaizen_api, kaizen_etl, kaizen_monitor;

-- ---------------------------------------------------------------------
-- kaizen_api: lecturas directas; escrituras con reglas solo por
-- procedimiento; sin DDL, sin DELETE (salvo sesion), sin TRUNCATE.
-- ---------------------------------------------------------------------
GRANT SELECT ON categoria, directorio_usuarios, usuario, habito, registro, racha,
                nivel_habito, sugerencia_ajuste, senal_diaria, sesion,
                v_racha_vigente, v_usuario_admin, v_metricas_region TO kaizen_api;

-- capsula: todas las columnas EXCEPTO mensaje_cifrado (solo vía sp_abrir_capsula)
GRANT SELECT (id, region, habito_id, usuario_id, llave_version, tiene_foto,
              racha_objetivo, estado, creada_en, abierta_en) ON capsula TO kaizen_api;
GRANT INSERT (id, region, habito_id, usuario_id, mensaje_cifrado, llave_version,
              tiene_foto, racha_objetivo) ON capsula TO kaizen_api;

GRANT INSERT (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo,
              dias_semana, veces_semana, meta, unidad) ON habito TO kaizen_api;   -- sin fecha_creacion
GRANT INSERT ON senal_diaria, sesion TO kaizen_api;
GRANT UPDATE (nombre, categoria_id, unidad, activo) ON habito TO kaizen_api;   -- sin meta
GRANT UPDATE (animo, energia) ON senal_diaria TO kaizen_api;
GRANT UPDATE (nombre, intentos_fallidos, bloqueado_hasta, consentimiento_senales_en,
              password_hash) ON usuario TO kaizen_api;
GRANT UPDATE (revocada_en, reemplazada_por) ON sesion TO kaizen_api;
GRANT DELETE ON sesion TO kaizen_api;                                          -- limpieza de expiradas
GRANT INSERT ON bitacora_auditoria TO kaizen_api;

GRANT EXECUTE ON PROCEDURE sp_registrar_usuario, sp_registrar_checkin, sp_responder_sugerencia,
                           sp_abrir_capsula, sp_eliminar_cuenta, sp_retirar_consentimiento_senales
      TO kaizen_api;
GRANT EXECUTE ON FUNCTION fn_region, fn_cumplimiento, fn_rachas, fn_dia_programado,
                          fn_dia_programado_anterior TO kaizen_api;

-- ---------------------------------------------------------------------
-- kaizen_etl: solo lectura y SIN columnas personales (minimización).
-- Se conecta a una réplica (target_session_attrs=standby).
-- ---------------------------------------------------------------------
GRANT SELECT (id, region, pais, fecha_registro) ON usuario TO kaizen_etl;
GRANT SELECT ON categoria, habito, registro, racha, nivel_habito,
                sugerencia_ajuste, senal_diaria TO kaizen_etl;
GRANT SELECT (id, region, habito_id, usuario_id, racha_objetivo, estado, creada_en, abierta_en)
      ON capsula TO kaizen_etl;
GRANT EXECUTE ON FUNCTION fn_cumplimiento, fn_rachas, fn_dia_programado TO kaizen_etl;
ALTER ROLE kaizen_etl SET default_transaction_read_only = on;

-- ---------------------------------------------------------------------
-- kaizen_monitor: métricas del servidor sin acceso a datos
-- ---------------------------------------------------------------------
GRANT pg_monitor TO kaizen_monitor WITH INHERIT TRUE;   -- PG16: la herencia se fija en cada GRANT

-- ---------------------------------------------------------------------
-- kaizen_admin (personas): mantenimiento sin ser superusuario.
-- Cada integrante tiene su propio login miembro del grupo, p. ej.:
--   CREATE ROLE jael_dba LOGIN IN ROLE kaizen_admin;
-- ---------------------------------------------------------------------
GRANT USAGE ON SCHEMA kaizen TO kaizen_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA kaizen TO kaizen_admin;
REVOKE SELECT ON capsula FROM kaizen_admin;
GRANT EXECUTE ON PROCEDURE sp_generar_sugerencias, sp_reconstruir_rachas,
                           sp_crear_particion_bitacora TO kaizen_admin;
GRANT EXECUTE ON FUNCTION fn_cumplimiento, fn_rachas, fn_dia_programado,
                          fn_dia_programado_anterior TO kaizen_admin;

-- ---------------------------------------------------------------------
-- Bitácora: nadie la modifica (complemento del trigger T10)
-- ---------------------------------------------------------------------
REVOKE UPDATE, DELETE, TRUNCATE ON bitacora_auditoria FROM PUBLIC, kaizen_api, kaizen_etl, kaizen_admin;

-- Tiempos máximos para que una sesión colgada no retenga bloqueos
ALTER ROLE kaizen_api SET statement_timeout = '5s';
ALTER ROLE kaizen_api SET idle_in_transaction_session_timeout = '15s';
ALTER ROLE kaizen_etl SET statement_timeout = '5min';

COMMIT;
