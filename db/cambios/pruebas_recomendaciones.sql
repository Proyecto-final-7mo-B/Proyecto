-- =====================================================================
-- Kaizen · pruebas de 2026-11-27_recomendaciones.sql
-- (fuentes, hábitos recomendados, crear desde una recomendación y días protegidos)
-- Uso: psql -X -v ON_ERROR_STOP=1 -U postgres -d kaizen -f pruebas_recomendaciones.sql
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
CREATE FUNCTION pg_temp.rec(p_clave text) RETURNS uuid LANGUAGE sql AS
    $$ SELECT id FROM kaizen.habito_recomendado WHERE clave = p_clave $$;
CREATE FUNCTION pg_temp.habito(p_usuario uuid, p_dias_antes integer) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE v uuid := gen_random_uuid();
BEGIN
    INSERT INTO kaizen.habito (id, region, usuario_id, subcategoria_id, nombre, frecuencia_tipo, meta, unidad, fecha_creacion)
    VALUES (v, 'MX-NORTE', p_usuario, (SELECT id FROM kaizen.subcategoria WHERE clave = 'pasos'), 'Pasos', 'diaria',
            8000, 'pasos', now() - make_interval(days => p_dias_antes));
    RETURN v;
END $$;
CREATE FUNCTION pg_temp.registrar(p_habito uuid, p_desde integer, p_hasta integer) RETURNS void LANGUAGE sql AS $$
    INSERT INTO kaizen.registro (id, region, habito_id, usuario_id, fecha, cumplido, origen)
    SELECT gen_random_uuid(), 'MX-NORTE', p_habito, h.usuario_id, current_date + d, true, 'manual'
      FROM kaizen.habito h, generate_series(p_desde, p_hasta) d
     WHERE h.region = 'MX-NORTE' AND h.id = p_habito $$;
CREATE FUNCTION pg_temp.protegidos(p_habito uuid, p_desde integer, p_hasta integer) RETURNS integer[] LANGUAGE sql AS $$
    SELECT coalesce(array_agg(f - current_date ORDER BY f), '{}')
      FROM kaizen.fn_dias_protegidos('MX-NORTE', p_habito, current_date + p_desde, current_date + p_hasta) f $$;
GRANT EXECUTE ON FUNCTION pg_temp.ok(boolean, text), pg_temp.espera_error(text, text, text), pg_temp.rec(text)
      TO PUBLIC;

SELECT set_config('t.adm', 'adadadad-0000-4000-8000-0000000000aa', false),
       set_config('t.u',   'abababab-0000-4000-8000-0000000000bb', false) \g /dev/null
SET LOCAL ROLE kaizen_api;
CALL sp_registrar_usuario(current_setting('t.adm')::uuid, repeat('5',64), 'Admin', 'admin2@prueba.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'CMX', false, NULL, NULL);
CALL sp_registrar_usuario(current_setting('t.u')::uuid, repeat('6',64), 'Uriel', 'uriel@prueba.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'SON', false, NULL, NULL);
RESET ROLE;
UPDATE usuario SET rol = 'admin' WHERE id = current_setting('t.adm')::uuid;

\echo '--- 0. Fuentes científicas'
SELECT pg_temp.ok((SELECT count(*) FROM fuente_cientifica) = 53, '53 fuentes (F01–F53), las de fuentes.md');
SELECT pg_temp.ok((SELECT count(DISTINCT tema) FROM fuente_cientifica) = 7, 'agrupadas en los 7 temas del documento');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM fuente_cientifica WHERE referencia ~ '\*' OR dato ~ '\*\*'),
                  'sin formato Markdown');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM referencia_cientifica WHERE NOT fn_fuentes_validas(fuentes)),
                  'toda fuente citada por una referencia existe');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM logro WHERE NOT fn_fuentes_validas(fuentes)),
                  'toda fuente citada por un logro existe');
SELECT pg_temp.ok(fn_fuentes_validas('F11, F14') AND NOT fn_fuentes_validas('F11, F99') AND NOT fn_fuentes_validas('F1'),
                  'fn_fuentes_validas: formato y existencia');

\echo '--- 1. Catálogo de recomendaciones'
SELECT pg_temp.ok((SELECT count(*) FROM habito_recomendado) = 100, '100 recomendaciones');
SELECT pg_temp.ok((SELECT bool_and(n = 20) FROM (SELECT count(*) AS n FROM v_habito_recomendado GROUP BY categoria_clave) x)
                  AND (SELECT count(DISTINCT categoria_clave) FROM v_habito_recomendado) = 5,
                  '20 por cada una de las 5 categorías');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM subcategoria s WHERE s.activa
                               AND (SELECT count(*) FROM habito_recomendado r WHERE r.subcategoria_id = s.id) < 2),
                  'cada subcategoría tiene al menos 2 recomendaciones');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM v_habito_recomendado
                               WHERE zona NOT IN ('optimo', 'sin_referencia') AND subcategoria_clave <> 'dejar_fumar'),
                  'toda meta con referencia está en el óptimo (dejar de fumar: el óptimo es 0)');
SELECT pg_temp.ok((SELECT bool_and(zona = 'alto') FROM v_habito_recomendado WHERE subcategoria_clave = 'dejar_fumar'),
                  'dejar de fumar queda "alto": la Escalera baja poco a poco');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM habito_recomendado r
                               JOIN unidad_subcategoria u ON u.subcategoria_id = r.subcategoria_id AND u.unidad = r.unidad
                              WHERE r.meta NOT BETWEEN u.minimo AND u.maximo
                                 OR mod(r.meta, u.paso) <> 0),
                  'cada meta está en el rango de captura de su unidad y es múltiplo de su paso');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM habito_recomendado WHERE NOT fn_fuentes_validas(fuentes)),
                  'toda recomendación cita fuentes que existen');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM habito_recomendado WHERE porque ~ '\(?[A-Z][a-z]+ (et al\. )?(19|20)[0-9]{2}'),
                  'el "por qué" no lleva la cita (va en fuentes)');
SELECT pg_temp.espera_error($$INSERT INTO habito_recomendado (clave, subcategoria_id, nombre, unidad, meta, frecuencia_tipo,
    momento, porque, fuentes) SELECT 'x_km', id, 'x', 'km', 1, 'diaria', 'x', 'por qué', 'F11'
    FROM subcategoria WHERE clave = 'meditacion'$$, '23503', 'una recomendación no puede usar una unidad no permitida');

\echo '--- 2. Crear un hábito desde una recomendación'
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.u'), true) \g /dev/null
INSERT INTO habito (region, usuario_id, recomendacion_id, prioridad, nombre, meta)   -- nombre y meta se ignoran
VALUES ('MX-NORTE', current_setting('t.u')::uuid, pg_temp.rec('caminar_rapido'), 1, 'Otro nombre', 999);
RESET ROLE;
SELECT pg_temp.ok((SELECT h.nombre = 'Caminar a paso rápido' AND h.meta = 30 AND h.unidad = 'min'
                          AND h.frecuencia_tipo = 'dias_semana' AND h.dias_semana = 31
                          AND h.intencion = 'Después de comer' AND h.prioridad = 1 AND c.clave = 'ejercicio'
                     FROM habito h JOIN categoria c ON c.id = h.categoria_id
                    WHERE h.usuario_id = current_setting('t.u')::uuid
                      AND h.recomendacion_id = pg_temp.rec('caminar_rapido')),
                  'la base copia nombre, meta, unidad, frecuencia e intención; la prioridad la elige el usuario');
SELECT pg_temp.ok((SELECT count(*) FROM nivel_habito n JOIN habito h ON h.id = n.habito_id
                    WHERE h.recomendacion_id = pg_temp.rec('caminar_rapido') AND n.nivel = 1 AND n.meta_valor = 30) = 1,
                  'nace en el nivel 1 con la meta recomendada');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM logro_usuario WHERE usuario_id = current_setting('t.u')::uuid
                               AND logro_clave = 'plan_si_entonces'),
                  'la intención que trae la recomendación no otorga "Plan si-entonces"');
SELECT set_config('t.h', (SELECT id FROM habito WHERE recomendacion_id = pg_temp.rec('caminar_rapido'))::text, false) \g /dev/null
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.u'), true) \g /dev/null
UPDATE habito SET nombre = 'Caminata', prioridad = 2 WHERE region = 'MX-NORTE' AND id = current_setting('t.h')::uuid;
INSERT INTO habito (region, usuario_id, recomendacion_id) VALUES ('MX-NORTE', current_setting('t.u')::uuid, pg_temp.rec('meditar_10'));
RESET ROLE;
SELECT pg_temp.ok((SELECT nombre FROM habito WHERE id = current_setting('t.h')::uuid) = 'Caminata',
                  'después de crearlo es del usuario: puede cambiarle el nombre y la prioridad');
SELECT pg_temp.ok((SELECT prioridad FROM habito WHERE recomendacion_id = pg_temp.rec('meditar_10')
                    AND usuario_id = current_setting('t.u')::uuid) = 2, 'sin prioridad nace en media (2)');
SELECT pg_temp.espera_error(format($$UPDATE habito SET recomendacion_id = %L WHERE region = 'MX-NORTE' AND id = %L$$,
    pg_temp.rec('leer_30'), current_setting('t.h')), 'KZ011', 'la recomendación de origen no se puede cambiar');
UPDATE habito_recomendado SET activo = false WHERE clave = 'nadar';
SELECT pg_temp.espera_error(format($$INSERT INTO habito (region, usuario_id, recomendacion_id) VALUES ('MX-NORTE', %L, %L)$$,
    current_setting('t.u'), pg_temp.rec('nadar')), 'KZ018', 'una recomendación inactiva no se puede usar');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM v_habito_recomendado WHERE clave = 'nadar'), 'la vista solo muestra las activas');
SELECT pg_temp.espera_error(format($$INSERT INTO habito (region, usuario_id, recomendacion_id) VALUES ('MX-NORTE', %L, %L)$$,
    current_setting('t.u'), gen_random_uuid()), 'KZ018', 'una recomendación que no existe');
UPDATE subcategoria SET activa = false WHERE clave = 'estiramiento';
SELECT pg_temp.espera_error(format($$INSERT INTO habito (region, usuario_id, recomendacion_id) VALUES ('MX-NORTE', %L, %L)$$,
    current_setting('t.u'), pg_temp.rec('yoga_suave')), 'KZ018', 'recomendación de una subcategoría desactivada');
UPDATE subcategoria SET activa = true WHERE clave = 'estiramiento';

\echo '--- 3. Días protegidos (misma regla que fn_rachas)'
-- Dos semanas completas que terminan el domingo pasado
SELECT set_config('t.lun', (date_trunc('week', current_date)::date - 14 - current_date)::text, false) \g /dev/null
SELECT set_config('t.ra', pg_temp.habito(current_setting('t.u')::uuid, 40)::text, false),
       set_config('t.rb', pg_temp.habito(current_setting('t.u')::uuid, 40)::text, false),
       set_config('t.rc', pg_temp.habito(current_setting('t.u')::uuid, 40)::text, false),
       set_config('t.rv', pg_temp.habito(current_setting('t.u')::uuid, 40)::text, false) \g /dev/null
SELECT pg_temp.registrar(current_setting('t.ra')::uuid, current_setting('t.lun')::int, current_setting('t.lun')::int + 1),
       pg_temp.registrar(current_setting('t.ra')::uuid, current_setting('t.lun')::int + 3, current_setting('t.lun')::int + 13),
       pg_temp.registrar(current_setting('t.rb')::uuid, current_setting('t.lun')::int, current_setting('t.lun')::int + 1),
       pg_temp.registrar(current_setting('t.rb')::uuid, current_setting('t.lun')::int + 3, current_setting('t.lun')::int + 3),
       pg_temp.registrar(current_setting('t.rb')::uuid, current_setting('t.lun')::int + 5, current_setting('t.lun')::int + 13),
       pg_temp.registrar(current_setting('t.rc')::uuid, current_setting('t.lun')::int, current_setting('t.lun')::int + 1),
       pg_temp.registrar(current_setting('t.rc')::uuid, current_setting('t.lun')::int + 3, current_setting('t.lun')::int + 8),
       pg_temp.registrar(current_setting('t.rc')::uuid, current_setting('t.lun')::int + 10, current_setting('t.lun')::int + 13),
       pg_temp.registrar(current_setting('t.rv')::uuid, -6, -2) \g /dev/null
SELECT set_config('t.l', current_setting('t.lun'), false) \g /dev/null
SELECT pg_temp.ok(pg_temp.protegidos(current_setting('t.ra')::uuid, current_setting('t.l')::int, current_setting('t.l')::int + 13)
                  = ARRAY[current_setting('t.l')::int + 2], 'una falla en la semana: ese día lleva escudo');
SELECT pg_temp.ok(pg_temp.protegidos(current_setting('t.rb')::uuid, current_setting('t.l')::int, current_setting('t.l')::int + 13)
                  = ARRAY[current_setting('t.l')::int + 2], 'la segunda falla de la semana rompe la racha: sin escudo');
SELECT pg_temp.ok(pg_temp.protegidos(current_setting('t.rc')::uuid, current_setting('t.l')::int, current_setting('t.l')::int + 13)
                  = ARRAY[current_setting('t.l')::int + 2, current_setting('t.l')::int + 9], 'una falla en cada semana: dos escudos');
SELECT pg_temp.ok(pg_temp.protegidos(current_setting('t.rc')::uuid, current_setting('t.l')::int + 7, current_setting('t.l')::int + 13)
                  = ARRAY[current_setting('t.l')::int + 9], 'solo devuelve los del rango pedido (la historia sí cuenta)');
SELECT pg_temp.ok((SELECT bool_and(f.ultimo_protegido = (SELECT max(p) FROM fn_dias_protegidos('MX-NORTE', h.id,
                          current_date - 60, current_date + current_setting('t.l')::int + 13) p))
                     FROM habito h CROSS JOIN LATERAL fn_rachas('MX-NORTE', h.id, NULL, current_date + current_setting('t.l')::int + 13) f
                    WHERE h.id IN (current_setting('t.ra')::uuid, current_setting('t.rb')::uuid, current_setting('t.rc')::uuid)),
                  'coincide con el último día protegido de fn_rachas');
SELECT pg_temp.ok(pg_temp.protegidos(current_setting('t.rv')::uuid, -10, 0) = ARRAY[-1],
                  'ayer sin registro cuenta como falla protegida; hoy todavía no');
SELECT pg_temp.ok(pg_temp.protegidos(gen_random_uuid(), -10, 0) = '{}', 'un hábito que no existe no devuelve días');

\echo '--- 4. Administración'
DO $$
DECLARE
    v   uuid;
    lec uuid := (SELECT id FROM subcategoria WHERE clave = 'lectura');
BEGIN
    CALL sp_admin_guardar_recomendacion(current_setting('t.adm')::uuid, 'leer_20_paginas',
         lec, 'Leer 20 páginas', 'páginas', 20, 'diaria', NULL, NULL,
         'Antes de dormir', '20 páginas al día son unos 25 minutos de lectura.', 'F28, F29', true, 8::smallint, NULL, v);
    PERFORM pg_temp.ok(v IS NOT NULL AND EXISTS (SELECT 1 FROM habito_recomendado WHERE id = v AND nombre = 'Leer 20 páginas'),
                       'el admin agrega una recomendación');
    CALL sp_admin_guardar_recomendacion(current_setting('t.adm')::uuid, 'leer_20_paginas',
         lec, 'Leer 20 páginas', 'páginas', 20, 'diaria', NULL, NULL,
         'Antes de dormir', '20 páginas al día son unos 25 minutos de lectura.', 'F28, F29', false, 8::smallint, NULL, v);
    PERFORM pg_temp.ok(NOT (SELECT activo FROM habito_recomendado WHERE clave = 'leer_20_paginas'), 'y la desactiva');
    PERFORM pg_temp.ok(EXISTS (SELECT 1 FROM bitacora_auditoria WHERE accion = 'admin.recomendacion_guardar'),
                       'queda en la bitácora');
END $$;
SELECT pg_temp.espera_error(format($$CALL sp_admin_guardar_recomendacion(%L, 'x_km', %L, 'x', 'km', 1, 'diaria', NULL, NULL,
    'x', 'por qué', 'F11', true, 1::smallint, NULL, NULL)$$, current_setting('t.adm'),
    (SELECT id FROM subcategoria WHERE clave = 'meditacion')), 'KZ016', 'unidad no permitida');
SELECT pg_temp.espera_error(format($$CALL sp_admin_guardar_recomendacion(%L, 'x_mucho', %L, 'x', 'min', 900, 'diaria', NULL, NULL,
    'x', 'por qué', 'F11', true, 1::smallint, NULL, NULL)$$, current_setting('t.adm'),
    (SELECT id FROM subcategoria WHERE clave = 'meditacion')), 'KZ011', 'meta fuera del rango de captura');
SELECT pg_temp.espera_error(format($$CALL sp_admin_guardar_recomendacion(%L, 'x_fuente', %L, 'x', 'min', 10, 'diaria', NULL, NULL,
    'x', 'por qué', 'F99', true, 1::smallint, NULL, NULL)$$, current_setting('t.adm'),
    (SELECT id FROM subcategoria WHERE clave = 'meditacion')), 'KZ011', 'una fuente que no existe');
SELECT pg_temp.espera_error(format($$CALL sp_admin_guardar_recomendacion(%L, 'x_freq', %L, 'x', 'min', 10, 'dias_semana', NULL, NULL,
    'x', 'por qué', 'F32', true, 1::smallint, NULL, NULL)$$, current_setting('t.adm'),
    (SELECT id FROM subcategoria WHERE clave = 'meditacion')), 'KZ011', 'frecuencia incoherente');
SELECT pg_temp.espera_error(format($$CALL sp_admin_guardar_recomendacion(%L, 'x_user', %L, 'x', 'min', 10, 'diaria', NULL, NULL,
    'x', 'por qué', 'F32', true, 1::smallint, NULL, NULL)$$, current_setting('t.u'),
    (SELECT id FROM subcategoria WHERE clave = 'meditacion')), 'KZ010', 'un usuario normal no administra recomendaciones');

\echo '--- 5. Permisos'
SELECT pg_temp.ok(has_table_privilege('kaizen_api', 'kaizen.fuente_cientifica', 'SELECT')
              AND has_table_privilege('kaizen_api', 'kaizen.v_habito_recomendado', 'SELECT')
              AND has_column_privilege('kaizen_api', 'kaizen.habito', 'recomendacion_id', 'INSERT')
              AND NOT has_column_privilege('kaizen_api', 'kaizen.habito', 'recomendacion_id', 'UPDATE')
              AND has_function_privilege('kaizen_api', 'kaizen.fn_dias_protegidos(kaizen.region_t, uuid, date, date)', 'EXECUTE'),
                  'kaizen_api: lee fuentes y recomendaciones, crea desde una recomendación y consulta días protegidos');
SELECT pg_temp.ok(NOT has_table_privilege('kaizen_api', 'kaizen.habito_recomendado', 'INSERT')
              AND NOT has_table_privilege('kaizen_api', 'kaizen.fuente_cientifica', 'UPDATE'),
                  'kaizen_api no escribe el catálogo directo (solo por el procedimiento de admin)');
SELECT pg_temp.ok(has_table_privilege('kaizen_etl', 'kaizen.habito_recomendado', 'SELECT')
              AND has_table_privilege('kaizen_etl', 'kaizen.fuente_cientifica', 'SELECT')
              AND NOT has_table_privilege('kaizen_etl', 'kaizen.habito_recomendado', 'INSERT'),
                  'kaizen_etl solo lee');
SELECT pg_temp.ok(NOT has_function_privilege('public', 'kaizen.fn_dias_protegidos(kaizen.region_t, uuid, date, date)', 'EXECUTE'),
                  'PUBLIC no ejecuta las funciones nuevas');
-- La API con RLS: solo ve los días protegidos de sus propios hábitos
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.adm'), true) \g /dev/null
SELECT pg_temp.ok((SELECT count(*) FROM fn_dias_protegidos('MX-NORTE', current_setting('t.rc')::uuid, current_date - 60, current_date)) = 0,
                  'RLS: otro usuario no ve los días protegidos ajenos');
SELECT set_config('kaizen.usuario_id', current_setting('t.u'), true) \g /dev/null
SELECT pg_temp.ok((SELECT count(*) FROM fn_dias_protegidos('MX-NORTE', current_setting('t.rc')::uuid, current_date - 60, current_date)) >= 2,
                  'RLS: el dueño sí los ve');
RESET ROLE;

ROLLBACK;
