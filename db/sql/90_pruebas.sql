-- =====================================================================
-- Kaizen · 90_pruebas.sql
-- Pruebas de las reglas de la base. Cada prueba imprime OK o aborta.
-- Uso:  psql -v ON_ERROR_STOP=1 -d kaizen -f 90_pruebas.sql
-- Se ejecuta en una transacción que al final se revierte (ROLLBACK):
-- no deja datos. Puede correr contra un PostgreSQL desechable.
-- =====================================================================
\set QUIET on
\pset format unaligned
\pset tuples_only on
SET client_min_messages = notice;
BEGIN;
SET LOCAL search_path = kaizen, pg_temp;

-- ---------------------------------------------------------------------
-- Utilidades de prueba
-- ---------------------------------------------------------------------
CREATE FUNCTION pg_temp.ok(p_cond boolean, p_nombre text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    IF p_cond IS NOT TRUE THEN
        RAISE EXCEPTION 'FALLA: %', p_nombre;
    END IF;
    RAISE NOTICE 'OK   %', p_nombre;
END $$;

CREATE FUNCTION pg_temp.espera_error(p_sql text, p_estado text, p_nombre text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        IF SQLSTATE = p_estado THEN
            RAISE NOTICE 'OK   % -> % (%)', p_nombre, p_estado, SQLERRM;
            RETURN;
        END IF;
        RAISE EXCEPTION 'FALLA: % -> se esperaba %, llegó % (%)', p_nombre, p_estado, SQLSTATE, SQLERRM;
    END;
    RAISE EXCEPTION 'FALLA: % -> se esperaba el error % y no hubo error', p_nombre, p_estado;
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.ok(boolean, text), pg_temp.espera_error(text, text, text) TO PUBLIC;

-- Ids fijos para leer las pruebas con facilidad
SELECT set_config('t.a', 'aaaaaaaa-0000-4000-8000-000000000001', false),   -- usuaria A, Aguascalientes
       set_config('t.b', 'bbbbbbbb-0000-4000-8000-000000000002', false),   -- usuario B, Argentina
       set_config('t.c', 'cccccccc-0000-4000-8000-000000000003', false),   -- usuario C, CDMX, sin consentimiento
       set_config('t.h1','11111111-0000-4000-8000-000000000001', false),   -- hábito diario de A
       set_config('t.h2','22222222-0000-4000-8000-000000000002', false),   -- hábito L-M-V de A
       set_config('t.cat','99999999-0000-4000-8000-000000000009', false) \g /dev/null

INSERT INTO categoria (id, nombre) VALUES (current_setting('t.cat')::uuid, 'Hidratación');

\echo '--- 1. Funciones de región (shard key)'
SELECT pg_temp.ok(fn_region('MX','AGU') = 'MX-NORTE',      'fn_region: Aguascalientes -> MX-NORTE');
SELECT pg_temp.ok(fn_region('MX','cmx') = 'MX-CENTRO-SUR', 'fn_region: CDMX (minúsculas) -> MX-CENTRO-SUR');
SELECT pg_temp.ok(fn_region('CO', NULL) = 'LATAM',         'fn_region: Colombia -> LATAM');
SELECT pg_temp.espera_error($$SELECT fn_region('MX','XXX')$$, 'KZ002', 'fn_region: estado inexistente');
SELECT pg_temp.espera_error($$SELECT fn_region('US', NULL)$$, 'KZ002', 'fn_region: país fuera de alcance');
SELECT pg_temp.ok((SELECT count(*) FROM unnest(ARRAY['BCN','BCS','SON','CHH','COA','NLE','TAM','SIN','DUR','ZAC','SLP',
       'NAY','JAL','COL','AGU','GUA','QUE','MIC','CMX','MEX','HID','MOR','TLA','PUE','VER','GRO','OAX','CHP',
       'TAB','CAM','YUC','ROO']) e WHERE fn_region('MX', e) IS NOT NULL) = 32, 'fn_region: los 32 estados tienen región');

\echo '--- 2. Registro de usuarios (procedimiento P1, como kaizen_api)'
SET LOCAL ROLE kaizen_api;
CALL sp_registrar_usuario(current_setting('t.a')::uuid, repeat('a',64), 'Ana', 'Ana@Ejemplo.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'AGU', true, '10.0.0.1', NULL);
CALL sp_registrar_usuario(current_setting('t.b')::uuid, repeat('b',64), 'Beto', 'beto@ejemplo.ar',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'AR', NULL, true, '10.0.0.2', NULL);
CALL sp_registrar_usuario(current_setting('t.c')::uuid, repeat('c',64), 'Caro', 'caro@ejemplo.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'CMX', false, '10.0.0.3', NULL);
SELECT pg_temp.espera_error($$CALL sp_registrar_usuario(gen_random_uuid(), repeat('a',64), 'Otra', 'ana@ejemplo.mx',
     '$argon2id$v=19$x', 'MX', 'JAL', true, NULL, NULL)$$, 'KZ001', 'P1: correo duplicado en otra región');
SELECT pg_temp.espera_error($$CALL sp_registrar_usuario(gen_random_uuid(), repeat('d',64), 'Mal', 'mal@ejemplo.mx',
     'md5abc', 'MX', 'JAL', true, NULL, NULL)$$, '23514', 'P1: hash que no es Argon2id');
RESET ROLE;
SELECT pg_temp.ok((SELECT region FROM usuario WHERE id = current_setting('t.a')::uuid) = 'MX-NORTE'
              AND (SELECT count(*) FROM ONLY usuario_mx_norte WHERE id = current_setting('t.a')::uuid) = 1,
                  'P1: A vive físicamente en usuario_mx_norte');
SELECT pg_temp.ok((SELECT count(*) FROM usuario) = 3, 'P1: el registro fallido no dejó usuario huérfano');
SELECT pg_temp.ok((SELECT email FROM usuario WHERE id = current_setting('t.a')::uuid) = 'ana@ejemplo.mx',
                  'P1: correo normalizado a minúsculas');

\echo '--- 3. Hábitos: nivel inicial y racha (trigger T3)'
-- hábito creado hace 20 días (carga histórica, la hace el dueño del esquema)
SET LOCAL ROLE kaizen_owner;
INSERT INTO habito (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo, meta, unidad, fecha_creacion)
VALUES (current_setting('t.h1')::uuid, 'MX-NORTE', current_setting('t.a')::uuid, current_setting('t.cat')::uuid,
        'Tomar agua', 'diaria', 8, 'vasos', now() - interval '20 days');
INSERT INTO habito (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo, dias_semana, meta, unidad, fecha_creacion)
VALUES (current_setting('t.h2')::uuid, 'MX-NORTE', current_setting('t.a')::uuid, current_setting('t.cat')::uuid,
        'Correr', 'dias_semana', 1|4|16, 3, 'km', now() - interval '30 days');
RESET ROLE;
SELECT pg_temp.ok((SELECT count(*) FROM nivel_habito WHERE habito_id = current_setting('t.h1')::uuid
                    AND nivel = 1 AND vigente_hasta IS NULL AND meta_valor = 8) = 1, 'T3: nivel 1 creado');
SELECT pg_temp.ok((SELECT racha_actual FROM racha WHERE habito_id = current_setting('t.h1')::uuid) = 0,
                  'T3: racha inicial en cero');
SELECT pg_temp.espera_error($$INSERT INTO habito (region, usuario_id, categoria_id, nombre, frecuencia_tipo, meta, unidad)
     VALUES ('MX-NORTE', current_setting('t.a')::uuid, current_setting('t.cat')::uuid, 'X', 'dias_semana', 1, 'u')$$,
     '23514', 'CHECK: dias_semana obligatorio en frecuencia por días');

\echo '--- 4. Check-ins (procedimiento P2, trigger T1 y T2)'
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.a'), true) \g /dev/null
-- 20 días: todos cumplidos salvo hace 10 días
DO $$
DECLARE k int; r int;
BEGIN
    FOR k IN 1..20 LOOP
        CALL sp_registrar_checkin('MX-NORTE', current_setting('t.a')::uuid, gen_random_uuid(),
             current_setting('t.h1')::uuid, current_date - k, k <> 10, 8, 'manual', r);
    END LOOP;
END $$;
SELECT pg_temp.ok((SELECT racha_actual = 9 AND racha_maxima = 10 AND ultima_fecha = current_date - 1
                     FROM racha WHERE habito_id = current_setting('t.h1')::uuid),
                  'T1: racha actual 9 y máxima 10 tras una falla');
-- reenvío idempotente desde la cola sin conexión
CALL sp_registrar_checkin('MX-NORTE', current_setting('t.a')::uuid, gen_random_uuid(),
     current_setting('t.h1')::uuid, current_date - 1, true, 8, 'offline', NULL);
SELECT pg_temp.ok((SELECT count(*) FROM registro WHERE habito_id = current_setting('t.h1')::uuid) = 20,
                  'P2: reenvío del mismo día no duplica');
SELECT pg_temp.espera_error($$CALL sp_registrar_checkin('MX-NORTE', current_setting('t.b')::uuid, gen_random_uuid(),
     current_setting('t.h1')::uuid, current_date, true, 1, 'manual', NULL)$$, 'KZ004', 'P2: IDOR, B marca hábito de A');
SELECT pg_temp.espera_error($$CALL sp_registrar_checkin('MX-NORTE', current_setting('t.a')::uuid, gen_random_uuid(),
     current_setting('t.h1')::uuid, current_date + 5, true, 1, 'manual', NULL)$$, 'KZ003', 'T2: fecha futura');
SELECT pg_temp.espera_error($$CALL sp_registrar_checkin('MX-NORTE', current_setting('t.a')::uuid, gen_random_uuid(),
     current_setting('t.h1')::uuid, current_date - 60, true, 1, 'manual', NULL)$$, 'KZ003', 'T2: fecha previa al hábito');
SELECT pg_temp.espera_error($$INSERT INTO registro (id, region, habito_id, usuario_id, fecha, cumplido, origen)
     VALUES (gen_random_uuid(), 'MX-NORTE', current_setting('t.h1')::uuid, current_setting('t.a')::uuid,
             current_date, true, 'manual')$$, '42501', 'Privilegios: la API no inserta registro directo');
-- hábito L-M-V: los días no programados no rompen la racha
DO $$
DECLARE d date; r int;
BEGIN
    FOR d IN SELECT g::date FROM generate_series(current_date - 14, current_date - 1, interval '1 day') g LOOP
        IF fn_dia_programado('dias_semana', (1|4|16)::smallint, d) THEN
            CALL sp_registrar_checkin('MX-NORTE', current_setting('t.a')::uuid, gen_random_uuid(),
                 current_setting('t.h2')::uuid, d, true, 3, 'rapido', r);
        END IF;
    END LOOP;
END $$;
SELECT pg_temp.ok((SELECT racha_actual FROM racha WHERE habito_id = current_setting('t.h2')::uuid) = 6,
                  'T1: hábito L-M-V, 6 días programados seguidos (los demás no rompen)');
RESET ROLE;

\echo '--- 5. Row-Level Security (segunda barrera anti-IDOR)'
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.b'), true) \g /dev/null
SELECT pg_temp.ok((SELECT count(*) FROM registro) = 0 AND (SELECT count(*) FROM habito) = 0
              AND (SELECT count(*) FROM racha) = 0, 'RLS: B no ve hábitos, registros ni rachas de A');
SELECT pg_temp.ok((SELECT count(*) FROM usuario) = 1, 'RLS: B solo ve su propio usuario');
SELECT pg_temp.espera_error($$INSERT INTO habito (region, usuario_id, categoria_id, nombre, frecuencia_tipo, meta, unidad)
     VALUES ('MX-NORTE', current_setting('t.a')::uuid, current_setting('t.cat')::uuid, 'Intruso', 'diaria', 1, 'u')$$,
     '42501', 'RLS: B no crea hábitos a nombre de A');
SELECT set_config('kaizen.usuario_id', current_setting('t.a'), true) \g /dev/null
SELECT pg_temp.ok((SELECT count(*) FROM habito) = 2 AND (SELECT count(*) FROM registro) > 0,
                  'RLS: A ve sus 2 hábitos');
SELECT set_config('kaizen.usuario_id', '', true) \g /dev/null
SELECT pg_temp.ok((SELECT count(*) FROM habito) = 0, 'RLS: sin usuario fijado no se ve nada (falla cerrada)');
RESET ROLE;

\echo '--- 6. Escalera Kaizen (P3, P4, T4, T5, T9)'
SELECT pg_temp.ok(fn_cumplimiento('MX-NORTE', current_setting('t.h1')::uuid, 14, current_date - 1) = 92.86,
                  'fn_cumplimiento: 13 de 14 = 92.86 %');
SELECT pg_temp.ok(fn_cumplimiento('MX-NORTE', current_setting('t.h1')::uuid, 30, current_date - 1) IS NULL,
                  'fn_cumplimiento: NULL si el hábito es más joven que la ventana');
-- el nivel 1 se abrió hace 20 días: ya puede evaluarse
CALL sp_generar_sugerencias('MX-NORTE', current_date, NULL);
SELECT pg_temp.ok((SELECT tipo = 'subir' AND meta_propuesta = 8.80 AND cumplimiento_14d = 92.86
                     FROM sugerencia_ajuste WHERE habito_id = current_setting('t.h1')::uuid),
                  'P3: >= 85 % propone subir 10 % (8 -> 8.80)');
DO $$
DECLARE n int;
BEGIN
    CALL sp_generar_sugerencias('MX-NORTE', current_date, n);
    PERFORM pg_temp.ok(n = 0, 'P3: no duplica si ya hay una sugerencia pendiente');
END $$;
SELECT set_config('t.sug', (SELECT id::text FROM sugerencia_ajuste WHERE habito_id = current_setting('t.h1')::uuid), false) \g /dev/null
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error($$CALL sp_responder_sugerencia('MX-NORTE', current_setting('t.b')::uuid,
     current_setting('t.sug')::uuid, true)$$, 'KZ004', 'P4: B no responde sugerencias de A');
RESET ROLE;
SET LOCAL ROLE kaizen_api;
CALL sp_responder_sugerencia('MX-NORTE', current_setting('t.a')::uuid, current_setting('t.sug')::uuid, true);
SELECT pg_temp.espera_error($$CALL sp_responder_sugerencia('MX-NORTE', current_setting('t.a')::uuid,
     current_setting('t.sug')::uuid, false)$$, 'KZ005', 'P4: una sugerencia se responde una sola vez');
SELECT pg_temp.espera_error($$UPDATE habito SET meta = 100 WHERE id = current_setting('t.h1')::uuid$$,
     '42501', 'Privilegios: la API no puede cambiar la meta (columna sin GRANT)');
RESET ROLE;
SELECT pg_temp.ok((SELECT meta FROM habito WHERE id = current_setting('t.h1')::uuid) = 8.80,
                  'T5: habito.meta sincronizada con el nivel vigente');
SELECT pg_temp.ok((SELECT string_agg(nivel || ':' || coalesce(vigente_hasta::text, 'vigente'), ',' ORDER BY nivel)
                     FROM nivel_habito WHERE habito_id = current_setting('t.h1')::uuid)
                  = '1:' || current_date || ',2:vigente', 'T5: nivel 1 cerrado hoy, nivel 2 vigente');
SET LOCAL ROLE kaizen_owner;
SELECT pg_temp.espera_error($$UPDATE habito SET meta = 100 WHERE id = current_setting('t.h1')::uuid$$,
     'KZ006', 'T4: ni el dueño del esquema cambia la meta sin la Escalera');
SELECT pg_temp.espera_error($$UPDATE sugerencia_ajuste SET estado = 'pendiente'
     WHERE id = current_setting('t.sug')::uuid$$, 'KZ006', 'T9: una sugerencia resuelta no regresa a pendiente');
RESET ROLE;

\echo '--- 7. Cápsula Kaizen (P5, T7)'
SET LOCAL ROLE kaizen_owner;
-- cápsula sellada hace 15 días (objetivo 7): desde entonces la racha máxima es 9
INSERT INTO capsula (id, region, habito_id, usuario_id, mensaje_cifrado, racha_objetivo, creada_en)
VALUES ('c0000000-0000-4000-8000-000000000001', 'MX-NORTE', current_setting('t.h1')::uuid,
        current_setting('t.a')::uuid, decode(repeat('ab', 40), 'hex'), 7, now() - interval '15 days');
-- cápsula sellada hoy con objetivo 21: aún no se puede abrir
INSERT INTO capsula (id, region, habito_id, usuario_id, mensaje_cifrado, racha_objetivo)
VALUES ('c0000000-0000-4000-8000-000000000002', 'MX-NORTE', current_setting('t.h1')::uuid,
        current_setting('t.a')::uuid, decode(repeat('cd', 40), 'hex'), 21);
RESET ROLE;
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error($$CALL sp_abrir_capsula('MX-NORTE', current_setting('t.a')::uuid,
     'c0000000-0000-4000-8000-000000000002', NULL, NULL)$$, 'KZ005', 'T7: no abre antes de la racha objetivo');
SELECT pg_temp.espera_error($$CALL sp_abrir_capsula('MX-NORTE', current_setting('t.b')::uuid,
     'c0000000-0000-4000-8000-000000000001', NULL, NULL)$$, 'KZ004', 'P5: B no abre la cápsula de A');
DO $$
DECLARE m bytea; v smallint;
BEGIN
    CALL sp_abrir_capsula('MX-NORTE', current_setting('t.a')::uuid, 'c0000000-0000-4000-8000-000000000001', m, v);
    PERFORM pg_temp.ok(octet_length(m) = 40 AND v = 1, 'P5: racha 9 >= 7, entrega el mensaje cifrado');
END $$;
SELECT set_config('kaizen.usuario_id', current_setting('t.a'), true) \g /dev/null
SELECT pg_temp.espera_error($$SELECT mensaje_cifrado FROM capsula$$, '42501',
     'Privilegios: la API no lee mensaje_cifrado sin el procedimiento');
SELECT pg_temp.ok((SELECT estado = 'abierta' AND abierta_en IS NOT NULL FROM capsula
                    WHERE id = 'c0000000-0000-4000-8000-000000000001'), 'T7: queda abierta con fecha');
SELECT pg_temp.espera_error($$INSERT INTO capsula (region, habito_id, usuario_id, mensaje_cifrado, racha_objetivo)
     VALUES ('MX-NORTE', current_setting('t.h1')::uuid, current_setting('t.a')::uuid, decode(repeat('ab',40),'hex'), 10)$$,
     '23514', 'CHECK: racha objetivo solo 7, 21 o 66');
RESET ROLE;
SET LOCAL ROLE kaizen_owner;
SELECT pg_temp.espera_error($$UPDATE capsula SET estado = 'sellada'
     WHERE id = 'c0000000-0000-4000-8000-000000000001'$$, 'KZ006', 'T7: una cápsula abierta no se vuelve a sellar');
SELECT pg_temp.espera_error($$UPDATE capsula SET racha_objetivo = 66
     WHERE id = 'c0000000-0000-4000-8000-000000000002'$$, 'KZ006', 'T7: no se cambia el objetivo de una cápsula sellada');
RESET ROLE;

\echo '--- 8. Señales y consentimiento (T8)'
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.c'), true) \g /dev/null
SELECT pg_temp.espera_error($$INSERT INTO senal_diaria (region, usuario_id, fecha, animo, energia)
     VALUES ('MX-CENTRO-SUR', current_setting('t.c')::uuid, current_date, 3, 3)$$, 'KZ008', 'T8: sin consentimiento no hay señales');
SELECT set_config('kaizen.usuario_id', current_setting('t.a'), true) \g /dev/null
INSERT INTO senal_diaria (region, usuario_id, fecha, animo, energia)
VALUES ('MX-NORTE', current_setting('t.a')::uuid, current_date, 4, 5);
SELECT pg_temp.espera_error($$INSERT INTO senal_diaria (region, usuario_id, fecha, animo, energia)
     VALUES ('MX-NORTE', current_setting('t.a')::uuid, current_date - 1, 6, 5)$$, '23514', 'Dominio escala_1_5: ánimo 6 rechazado');
RESET ROLE;
SELECT pg_temp.ok((SELECT count(*) FROM senal_diaria WHERE usuario_id = current_setting('t.a')::uuid) = 1,
                  'T8: con consentimiento se guarda la señal');
SET LOCAL ROLE kaizen_api;
DO $$
DECLARE n int;
BEGIN
    CALL sp_retirar_consentimiento_senales('MX-NORTE', current_setting('t.a')::uuid, n);
    PERFORM pg_temp.ok(n = 1, 'P9: oposición borra las señales guardadas');
END $$;
SELECT pg_temp.espera_error($$INSERT INTO senal_diaria (region, usuario_id, fecha, animo, energia)
     VALUES ('MX-NORTE', current_setting('t.a')::uuid, current_date, 3, 3)$$, 'KZ008', 'P9 + T8: tras oponerse no se registran señales');
RESET ROLE;

\echo '--- 9. Bitácora de solo inserción (T10) e inmutables (T6)'
SELECT pg_temp.ok((SELECT count(*) FROM bitacora_auditoria) >= 5, 'fn_auditar: los procedimientos dejan rastro');
SET LOCAL ROLE kaizen_owner;
SELECT pg_temp.espera_error($$UPDATE bitacora_auditoria SET resultado = 'exito'$$, 'KZ009', 'T10: UPDATE bloqueado');
SELECT pg_temp.espera_error($$DELETE FROM bitacora_auditoria$$, 'KZ009', 'T10: DELETE bloqueado');
SELECT pg_temp.espera_error($$TRUNCATE bitacora_auditoria$$, 'KZ009', 'T10: TRUNCATE bloqueado');
SELECT pg_temp.espera_error($$UPDATE usuario SET region = 'LATAM' WHERE id = current_setting('t.a')::uuid$$,
     'KZ006', 'T6: la región (shard key) es inmutable');
RESET ROLE;
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error($$DELETE FROM bitacora_auditoria$$, '42501', 'Privilegios: la API no borra la bitácora');
RESET ROLE;

\echo '--- 10. Vistas: racha vigente y enmascaramiento'
SET LOCAL ROLE kaizen_owner;
-- un hábito cuyo último check-in fue hace 3 días: su racha vigente es 0
INSERT INTO habito (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo, meta, unidad, fecha_creacion)
VALUES ('33333333-0000-4000-8000-000000000003', 'MX-NORTE', current_setting('t.a')::uuid,
        current_setting('t.cat')::uuid, 'Leer', 'diaria', 10, 'páginas', now() - interval '10 days');
INSERT INTO registro (id, region, habito_id, usuario_id, fecha, cumplido, origen)
SELECT gen_random_uuid(), 'MX-NORTE', '33333333-0000-4000-8000-000000000003', current_setting('t.a')::uuid,
       current_date - k, true, 'manual' FROM generate_series(3, 7) k;
RESET ROLE;
SELECT pg_temp.ok((SELECT racha_actual FROM racha WHERE habito_id = '33333333-0000-4000-8000-000000000003') = 5
              AND (SELECT racha_actual FROM v_racha_vigente WHERE habito_id = '33333333-0000-4000-8000-000000000003') = 0,
                  'v_racha_vigente: racha guardada 5, vigente 0 tras 2 días sin registrar');
SELECT pg_temp.ok((SELECT email_mascara FROM v_usuario_admin WHERE id = current_setting('t.a')::uuid) = 'a***@***.mx',
                  'v_usuario_admin: correo enmascarado');

\echo '--- 11. Dato derivado reconstruible (P7)'
DO $$
DECLARE n int;
BEGIN
    CALL sp_reconstruir_rachas(NULL, n);
    PERFORM pg_temp.ok(n = 0, 'P7: las rachas guardadas coinciden con las recalculadas');
    UPDATE racha SET racha_actual = 50, racha_maxima = 50 WHERE habito_id = current_setting('t.h1')::uuid;
    CALL sp_reconstruir_rachas('MX-NORTE', n);
    PERFORM pg_temp.ok(n = 1 AND (SELECT racha_actual FROM racha WHERE habito_id = current_setting('t.h1')::uuid) = 9,
                       'P7: corrige una racha alterada');
END $$;

\echo '--- 12. Cancelación de cuenta ARCO (P6)'
SET LOCAL ROLE kaizen_api;
CALL sp_eliminar_cuenta('MX-NORTE', current_setting('t.a')::uuid, '10.0.0.1');
RESET ROLE;
SELECT pg_temp.ok((SELECT count(*) FROM usuario WHERE id = current_setting('t.a')::uuid) = 0
              AND (SELECT count(*) FROM directorio_usuarios WHERE usuario_id = current_setting('t.a')::uuid) = 0
              AND (SELECT count(*) FROM habito WHERE usuario_id = current_setting('t.a')::uuid) = 0
              AND (SELECT count(*) FROM registro WHERE usuario_id = current_setting('t.a')::uuid) = 0
              AND (SELECT count(*) FROM capsula WHERE usuario_id = current_setting('t.a')::uuid) = 0
              AND (SELECT count(*) FROM racha) = 0 AND (SELECT count(*) FROM nivel_habito) = 0,
                  'P6: borra en cascada todos los datos de A');
SELECT pg_temp.ok((SELECT count(*) FROM bitacora_auditoria WHERE usuario_id = current_setting('t.a')::uuid
                    AND accion = 'usuario.cancelacion') = 1, 'P6: la bitácora conserva el evento');

\echo '--- Fin: todas las pruebas pasaron'
ROLLBACK;
