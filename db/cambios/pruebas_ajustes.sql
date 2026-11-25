-- =====================================================================
-- Kaizen · pruebas de los cambios del 23-nov-2026
-- Uso: psql -X -v ON_ERROR_STOP=1 -U postgres -d kaizen -f pruebas_ajustes.sql
-- Corre en una transacción que se revierte: no deja datos.
-- =====================================================================
\set QUIET on
\pset format unaligned
\pset tuples_only on
SET client_min_messages = notice;
BEGIN;
SET LOCAL search_path = kaizen, pg_temp;

CREATE FUNCTION pg_temp.ok(p_cond boolean, p_nombre text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    IF p_cond IS NOT TRUE THEN RAISE EXCEPTION 'FALLA: %', p_nombre; END IF;
    RAISE NOTICE 'OK   %', p_nombre;
END $$;
CREATE FUNCTION pg_temp.espera_error(p_sql text, p_estado text, p_nombre text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = p_estado THEN RAISE NOTICE 'OK   % -> % (%)', p_nombre, p_estado, SQLERRM; RETURN; END IF;
        RAISE EXCEPTION 'FALLA: % -> se esperaba %, llegó % (%)', p_nombre, p_estado, SQLSTATE, SQLERRM;
    END;
    RAISE EXCEPTION 'FALLA: % -> se esperaba el error % y no hubo error', p_nombre, p_estado;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.ok(boolean, text), pg_temp.espera_error(text, text, text) TO PUBLIC;

-- Ids fijos: admin (CDMX), usuaria U (Jalisco), usuario V (Colombia)
SELECT set_config('t.adm', 'adadadad-0000-4000-8000-00000000000a', false),
       set_config('t.u',   'abababab-0000-4000-8000-00000000000b', false),
       set_config('t.v',   'acacacac-0000-4000-8000-00000000000c', false),
       set_config('t.h',   'aeaeaeae-0000-4000-8000-00000000000e', false) \g /dev/null

\echo '--- 0. Catálogo inicial'
SELECT pg_temp.ok((SELECT count(*) FROM categoria WHERE activa) >= 8, 'catálogo: 8 categorías activas');

-- Usuarios de prueba (como la API)
SET LOCAL ROLE kaizen_api;
CALL sp_registrar_usuario(current_setting('t.adm')::uuid, repeat('1',64), 'Admin', 'admin@prueba.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'CMX', false, NULL, NULL);
CALL sp_registrar_usuario(current_setting('t.u')::uuid, repeat('2',64), 'Úrsula', 'u@prueba.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'JAL', true, NULL, NULL);
CALL sp_registrar_usuario(current_setting('t.v')::uuid, repeat('3',64), 'Víctor', 'v@prueba.co',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'CO', NULL, true, NULL, NULL);
RESET ROLE;
UPDATE usuario SET rol = 'admin' WHERE id = current_setting('t.adm')::uuid;      -- lo hace el DBA

\echo '--- 1. Escalera por hábito (escalera_activa)'
INSERT INTO habito (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo, meta, unidad, fecha_creacion)
SELECT current_setting('t.h')::uuid, 'MX-NORTE', current_setting('t.u')::uuid, id, 'Leer', 'diaria', 10, 'páginas',
       now() - interval '30 days' FROM categoria WHERE nombre = 'Lectura';
INSERT INTO registro (id, region, habito_id, usuario_id, fecha, cumplido, valor, origen)
SELECT gen_random_uuid(), 'MX-NORTE', current_setting('t.h')::uuid, current_setting('t.u')::uuid, d::date, true, 12, 'manual'
  FROM generate_series(current_date - 20, current_date - 1, interval '1 day') d;
SELECT pg_temp.ok((SELECT escalera_activa FROM habito WHERE id = current_setting('t.h')::uuid), 'escalera_activa nace en true');
CALL sp_generar_sugerencias('MX-NORTE', current_date, NULL);
SELECT pg_temp.ok((SELECT count(*) FROM sugerencia_ajuste WHERE habito_id = current_setting('t.h')::uuid
                    AND estado = 'pendiente') = 1, 'con la Escalera activa se genera la sugerencia');
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.u'), true) \g /dev/null
UPDATE habito SET escalera_activa = false WHERE region = 'MX-NORTE' AND id = current_setting('t.h')::uuid;
RESET ROLE;
SELECT pg_temp.ok((SELECT estado FROM sugerencia_ajuste WHERE habito_id = current_setting('t.h')::uuid) = 'expirada',
                  'apagar la Escalera (como kaizen_api) expira la sugerencia pendiente');
CALL sp_generar_sugerencias('MX-NORTE', current_date, NULL);
SELECT pg_temp.ok((SELECT count(*) FROM sugerencia_ajuste WHERE habito_id = current_setting('t.h')::uuid
                    AND estado = 'pendiente') = 0, 'con la Escalera apagada no se generan sugerencias');

\echo '--- 2. Categorías administrables'
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error(format($$CALL sp_admin_crear_categoria(%L, 'Música', NULL, NULL)$$, current_setting('t.u')),
                            'KZ010', 'un usuario normal no crea categorías');
DO $$ DECLARE v uuid; BEGIN
    CALL sp_admin_crear_categoria(current_setting('t.adm')::uuid, '  Música ', NULL, v);
    PERFORM set_config('t.cat', v::text, false);
END $$;
RESET ROLE;
SELECT pg_temp.ok((SELECT nombre FROM categoria WHERE id = current_setting('t.cat')::uuid) = 'Música', 'admin crea categoría (sin espacios)');
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error(format($$CALL sp_admin_crear_categoria(%L, 'música', NULL, NULL)$$, current_setting('t.adm')),
                            'KZ013', 'nombre duplicado sin importar mayúsculas');
SELECT pg_temp.espera_error(format($$CALL sp_admin_crear_categoria(%L, 'x', NULL, NULL)$$, current_setting('t.adm')),
                            'KZ011', 'nombre demasiado corto');
CALL sp_admin_actualizar_categoria(current_setting('t.adm')::uuid, current_setting('t.cat')::uuid, NULL, false, NULL);
SELECT pg_temp.espera_error(format($$CALL sp_admin_actualizar_categoria(%L, gen_random_uuid(), 'Otra', NULL, NULL)$$,
                            current_setting('t.adm')), 'KZ004', 'categoría inexistente');
SELECT pg_temp.espera_error($$INSERT INTO categoria (nombre) VALUES ('Directo')$$, '42501',
                            'kaizen_api no inserta categorías directamente');
SELECT set_config('kaizen.usuario_id', current_setting('t.u'), true) \g /dev/null
SELECT pg_temp.espera_error(format($$INSERT INTO habito (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo, meta, unidad)
                            VALUES (gen_random_uuid(), 'MX-NORTE', %L, %L, 'Tocar', 'diaria', 1, 'min')$$,
                            current_setting('t.u'), current_setting('t.cat')), 'KZ014', 'no se crea un hábito con categoría inactiva');
RESET ROLE;
SELECT pg_temp.ok((SELECT count(*) FROM bitacora_auditoria WHERE accion LIKE 'admin.categoria_%') = 2,
                  'la bitácora registra crear y editar categoría');

\echo '--- 3. Suspensión (B5)'
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.v'), true) \g /dev/null
INSERT INTO sesion (jti, region, usuario_id, familia, expira_en)
VALUES (gen_random_uuid(), 'LATAM', current_setting('t.v')::uuid, gen_random_uuid(), now() + interval '7 days');
SELECT pg_temp.espera_error(format($$CALL sp_admin_suspender_usuario(%L, %L, true, 'spam', NULL)$$,
                            current_setting('t.u'), current_setting('t.v')), 'KZ010', 'solo un admin suspende');
SELECT pg_temp.espera_error(format($$CALL sp_admin_suspender_usuario(%L, %L, true, NULL, NULL)$$,
                            current_setting('t.adm'), current_setting('t.v')), 'KZ011', 'el motivo es obligatorio');
SELECT pg_temp.espera_error(format($$CALL sp_admin_suspender_usuario(%L, %L, true, 'prueba', NULL)$$,
                            current_setting('t.adm'), current_setting('t.adm')), 'KZ010', 'un admin no se suspende a sí mismo');
CALL sp_admin_suspender_usuario(current_setting('t.adm')::uuid, current_setting('t.v')::uuid, true, 'Publica spam', '203.0.113.9');
RESET ROLE;
SELECT pg_temp.ok((SELECT suspendido FROM v_usuario_admin WHERE id = current_setting('t.v')::uuid),
                  'v_usuario_admin muestra suspendido');
SELECT pg_temp.ok((SELECT count(*) FROM sesion WHERE usuario_id = current_setting('t.v')::uuid AND revocada_en IS NULL) = 0,
                  'suspender revoca todas sus sesiones');
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.v'), true) \g /dev/null
SELECT pg_temp.espera_error(format($$INSERT INTO sesion (jti, region, usuario_id, familia, expira_en)
                            VALUES (gen_random_uuid(), 'LATAM', %L, gen_random_uuid(), now() + interval '1 day')$$,
                            current_setting('t.v')), 'KZ012', 'una cuenta suspendida no abre sesión');
SELECT pg_temp.espera_error($$UPDATE usuario SET suspendido_en = NULL$$, '42501', 'kaizen_api no cambia la suspensión directo');
CALL sp_admin_suspender_usuario(current_setting('t.adm')::uuid, current_setting('t.v')::uuid, false, NULL, NULL);
RESET ROLE;
SELECT pg_temp.ok((SELECT NOT suspendido AND suspension_motivo IS NULL FROM v_usuario_admin WHERE id = current_setting('t.v')::uuid),
                  'reactivar limpia la suspensión');
SELECT pg_temp.ok((SELECT count(*) FROM bitacora_auditoria WHERE accion IN ('admin.suspender', 'admin.reactivar')) = 2,
                  'la bitácora registra quién suspendió y reactivó');

\echo '--- 4. Recuperación de contraseña (B4b)'
SET LOCAL ROLE kaizen_api;
DO $$ DECLARE e boolean; n text; BEGIN
    CALL sp_solicitar_recuperacion(repeat('f',64), repeat('a',64), NULL, e, n);
    PERFORM pg_temp.ok(e = false, 'correo inexistente: no envía y no da error (sin enumeración)');
    CALL sp_solicitar_recuperacion(repeat('2',64), repeat('b',64), NULL, e, n);
    PERFORM pg_temp.ok(e AND n = 'Úrsula', 'cuenta real: genera el token y devuelve el nombre');
    CALL sp_solicitar_recuperacion(repeat('2',64), repeat('c',64), NULL, e, n);
    CALL sp_solicitar_recuperacion(repeat('2',64), repeat('d',64), NULL, e, n);
    CALL sp_solicitar_recuperacion(repeat('2',64), repeat('e',64), NULL, e, n);
    PERFORM pg_temp.ok(e = false, 'máximo 3 solicitudes por hora por cuenta');
END $$;
SELECT pg_temp.espera_error($$SELECT * FROM recuperacion_contrasena$$, '42501', 'kaizen_api no lee los tokens');
SELECT pg_temp.espera_error(format($$CALL sp_restablecer_contrasena(%L, '$argon2id$v=19$nuevo', NULL)$$, repeat('b',64)),
                            'KZ015', 'un token reemplazado por otro más nuevo ya no sirve');
CALL sp_restablecer_contrasena(repeat('d',64), '$argon2id$v=19$nuevo', NULL);
SELECT pg_temp.espera_error(format($$CALL sp_restablecer_contrasena(%L, '$argon2id$v=19$otro', NULL)$$, repeat('d',64)),
                            'KZ015', 'el token es de un solo uso');
RESET ROLE;
SELECT pg_temp.ok((SELECT password_hash FROM usuario WHERE id = current_setting('t.u')::uuid) = '$argon2id$v=19$nuevo',
                  'restablecer cambia el hash');
UPDATE recuperacion_contrasena SET creada_en = now() - interval '2 hours', expira_en = now() - interval '1 minute';
SET LOCAL ROLE kaizen_api;
DO $$ DECLARE e boolean; n text; BEGIN
    CALL sp_solicitar_recuperacion(repeat('2',64), repeat('9',64), NULL, e, n);
END $$;
RESET ROLE;
UPDATE recuperacion_contrasena SET expira_en = now() - interval '1 second', creada_en = now() - interval '20 minutes'
 WHERE token_hash = repeat('9',64);
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error(format($$CALL sp_restablecer_contrasena(%L, '$argon2id$v=19$x', NULL)$$, repeat('9',64)),
                            'KZ015', 'un token vencido no sirve');
SELECT pg_temp.espera_error(format($$CALL sp_restablecer_contrasena(%L, 'md5', NULL)$$, repeat('9',64)),
                            'KZ015', 'tampoco con un hash inválido');

\echo '--- 5. Permisos: lo nuevo no lo ejecuta PUBLIC'
RESET ROLE;
SELECT pg_temp.ok(NOT has_function_privilege('kaizen_etl', 'kaizen.fn_verificar_admin(uuid)', 'EXECUTE')
              AND NOT has_function_privilege('kaizen_api', 'kaizen.fn_verificar_admin(uuid)', 'EXECUTE'),
                  'fn_verificar_admin es interna');
SELECT pg_temp.ok(NOT has_function_privilege('kaizen_etl',
                  'kaizen.sp_restablecer_contrasena(text, text, inet)', 'EXECUTE'), 'kaizen_etl no restablece contraseñas');
SELECT pg_temp.ok(has_column_privilege('kaizen_api', 'kaizen.habito', 'escalera_activa', 'UPDATE')
              AND NOT has_column_privilege('kaizen_api', 'kaizen.usuario', 'suspendido_en', 'UPDATE'),
                  'kaizen_api: escalera_activa editable, suspendido_en no');
SET LOCAL ROLE kaizen_api;
INSERT INTO bitacora_auditoria (accion, resultado) VALUES ('prueba.api', 'exito');
RESET ROLE;
SELECT pg_temp.ok(true, 'kaizen_api inserta en la bitácora (identidad sin permiso extra)');

\echo '--- 6. Rol de tareas programadas (kaizen_tareas)'
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.u'), true) \g /dev/null
INSERT INTO sesion (jti, region, usuario_id, familia, emitida_en, expira_en)
VALUES (gen_random_uuid(), 'MX-NORTE', current_setting('t.u')::uuid, gen_random_uuid(), now() - interval '8 days', now() - interval '1 day');
SELECT pg_temp.espera_error($$CALL sp_generar_sugerencias(NULL, current_date, NULL)$$, '42501', 'kaizen_api no ejecuta la Escalera diaria');
RESET ROLE;
SET LOCAL ROLE kaizen_tareas;
CALL sp_generar_sugerencias(NULL, current_date, NULL);
CALL sp_crear_particion_bitacora(date '2027-07-01');
DO $$ DECLARE s int; k int; BEGIN
    CALL sp_limpiar_expirados(s, k);
    PERFORM pg_temp.ok(s >= 1, 'kaizen_tareas limpia sesiones vencidas de todos los usuarios');
END $$;
SELECT pg_temp.espera_error($$SELECT count(*) FROM usuario$$, '42501', 'kaizen_tareas no lee datos personales');
SELECT pg_temp.espera_error($$CALL sp_registrar_checkin('MX-NORTE', gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), current_date, true, NULL, 'manual', NULL)$$,
                            '42501', 'kaizen_tareas no ejecuta procedimientos de la API');
RESET ROLE;
SELECT pg_temp.ok(to_regclass('kaizen.bitacora_2027_07') IS NOT NULL, 'kaizen_tareas crea la partición del mes de la bitácora');

\echo '--- Fin: todas las pruebas de los cambios pasaron'
ROLLBACK;
