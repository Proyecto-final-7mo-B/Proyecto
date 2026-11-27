-- =====================================================================
-- Kaizen · pruebas de los cambios del 27-nov-2026 (respaldo científico)
-- Uso: psql -X -v ON_ERROR_STOP=1 -U postgres -d kaizen -f pruebas_evidencia.sql
-- Corre en una transacción que se revierte: no deja datos.
-- Los valores esperados salen de Evidencias_generales/12_investigacion_cientifica/03.
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
CREATE FUNCTION pg_temp.sub(p_clave text) RETURNS uuid LANGUAGE sql AS
    $$ SELECT id FROM kaizen.subcategoria WHERE clave = p_clave $$;
-- Evalúa una meta diaria (o n por semana) y devuelve "zona|meta_sugerida"
CREATE FUNCTION pg_temp.ev(p_sub text, p_unidad text, p_meta numeric, p_tipo text DEFAULT 'diaria',
                           p_veces smallint DEFAULT NULL) RETURNS text LANGUAGE sql AS $$
    SELECT e.zona || '|' || coalesce(e.meta_sugerida::text, '-')
      FROM kaizen.fn_evaluar_meta(pg_temp.sub(p_sub), p_unidad, p_meta, p_tipo, NULL, p_veces) e $$;
-- Crea un hábito como postgres (fecha de creación en el pasado) y devuelve su id
CREATE FUNCTION pg_temp.habito(p_usuario uuid, p_sub text, p_meta numeric, p_unidad text,
                               p_dias_antes integer DEFAULT 30, p_intencion text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v uuid := gen_random_uuid();
BEGIN
    INSERT INTO kaizen.habito (id, region, usuario_id, subcategoria_id, nombre, frecuencia_tipo, meta, unidad,
                               fecha_creacion, intencion)
    VALUES (v, 'MX-NORTE', p_usuario, pg_temp.sub(p_sub), 'H ' || p_sub, 'diaria', p_meta, p_unidad,
            now() - make_interval(days => p_dias_antes), p_intencion);
    RETURN v;
END $$;
-- Registra los días [desde, hasta] (relativos a hoy) con el resultado dado
CREATE FUNCTION pg_temp.registrar(p_habito uuid, p_desde integer, p_hasta integer, p_cumplido boolean,
                                  p_valor numeric DEFAULT NULL) RETURNS void LANGUAGE sql AS $$
    INSERT INTO kaizen.registro (id, region, habito_id, usuario_id, fecha, cumplido, valor, origen)
    SELECT gen_random_uuid(), 'MX-NORTE', p_habito, h.usuario_id, current_date + d, p_cumplido, p_valor, 'manual'
      FROM kaizen.habito h, generate_series(p_desde, p_hasta) d
     WHERE h.region = 'MX-NORTE' AND h.id = p_habito $$;
CREATE FUNCTION pg_temp.pendiente(p_habito uuid) RETURNS text LANGUAGE sql AS $$
    SELECT string_agg(tipo || ' ' || meta_propuesta || ' ' || motivo, ',')
      FROM kaizen.sugerencia_ajuste WHERE habito_id = p_habito AND estado = 'pendiente' $$;
GRANT EXECUTE ON FUNCTION pg_temp.ok(boolean, text), pg_temp.espera_error(text, text, text), pg_temp.sub(text)
      TO PUBLIC;

SELECT set_config('t.adm', 'adadadad-0000-4000-8000-00000000000a', false),
       set_config('t.u',   'abababab-0000-4000-8000-00000000000b', false),
       set_config('t.v',   'acacacac-0000-4000-8000-00000000000c', false),
       set_config('t.w',   'adadadad-0000-4000-8000-00000000000d', false) \g /dev/null

SET LOCAL ROLE kaizen_api;
CALL sp_registrar_usuario(current_setting('t.adm')::uuid, repeat('1',64), 'Admin', 'admin@prueba.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'CMX', false, NULL, NULL);
CALL sp_registrar_usuario(current_setting('t.u')::uuid, repeat('2',64), 'Úrsula', 'u@prueba.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'JAL', true, NULL, NULL);
CALL sp_registrar_usuario(current_setting('t.v')::uuid, repeat('3',64), 'Valeria', 'v@prueba.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'NLE', true, NULL, NULL);
CALL sp_registrar_usuario(current_setting('t.w')::uuid, repeat('4',64), 'Walter', 'w@prueba.mx',
     '$argon2id$v=19$m=65536,t=3,p=4$c2FsdA$aGFzaA', 'MX', 'SON', true, NULL, NULL);
RESET ROLE;
UPDATE usuario SET rol = 'admin' WHERE id = current_setting('t.adm')::uuid;

\echo '--- 0. Catálogo jerárquico y referencias'
SELECT pg_temp.ok((SELECT array_agg(clave ORDER BY orden) FROM categoria)
                  = ARRAY['ejercicio','salud','educacion','bienestar','finanzas'], '5 categorías con clave, en orden');
SELECT pg_temp.ok((SELECT count(*) FROM categoria WHERE color ~ '^#[0-9A-F]{6}$') = 5, 'cada categoría tiene color');
SELECT pg_temp.ok((SELECT count(*) FROM subcategoria) = 22, '22 subcategorías');
SELECT pg_temp.ok((SELECT count(*) FROM referencia_cientifica) = 18, '18 referencias (4 subcategorías sin rango)');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM subcategoria s
                               WHERE NOT EXISTS (SELECT 1 FROM unidad_subcategoria u WHERE u.subcategoria_id = s.id)),
                  'toda subcategoría tiene al menos una unidad');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM referencia_cientifica r
                               WHERE NOT EXISTS (SELECT 1 FROM unidad_subcategoria u
                                                  WHERE u.subcategoria_id = r.subcategoria_id
                                                    AND u.unidad = r.unidad_base AND u.factor_a_base = 1)),
                  'la unidad base de cada referencia es una unidad con factor 1');
SELECT pg_temp.ok((SELECT count(*) FROM referencia_cientifica WHERE fuentes ~ '^F[0-9]{2}') = 18,
                  'toda referencia cita fuentes F## del documento');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM categoria WHERE nombre IN ('Lectura','Hidratación','Sueño','Meditación','Aprendizaje')),
                  'las categorías viejas pasaron a subcategorías');

\echo '--- 1. Guardia del hábito (subcategoría, unidad, meta)'
SELECT pg_temp.espera_error(format($$INSERT INTO habito (region, usuario_id, categoria_id, nombre, frecuencia_tipo, meta, unidad)
    SELECT 'MX-NORTE', %L, id, 'x', 'diaria', 10, 'min' FROM categoria WHERE clave = 'bienestar'$$, current_setting('t.u')),
    'KZ011', 'sin subcategoría no se crea');
SELECT pg_temp.espera_error(format($$SELECT pg_temp.habito(%L, 'meditacion', 3, 'km')$$, current_setting('t.u')),
    'KZ016', 'unidad no permitida (km en meditación)');
SELECT pg_temp.espera_error(format($$SELECT pg_temp.habito(%L, 'meditacion', 700, 'min')$$, current_setting('t.u')),
    'KZ011', 'meta fuera del rango de captura (700 min)');
SELECT pg_temp.espera_error(format($$INSERT INTO habito (region, usuario_id, categoria_id, subcategoria_id, nombre, frecuencia_tipo, meta, unidad)
    SELECT 'MX-NORTE', %L, (SELECT id FROM categoria WHERE clave = 'salud'), pg_temp.sub('meditacion'), 'x', 'diaria', 10, 'min'$$,
    current_setting('t.u')), 'KZ011', 'categoría que no corresponde a la subcategoría');
SELECT set_config('t.h_lec', pg_temp.habito(current_setting('t.u')::uuid, 'lectura', 20, 'páginas', 30)::text, false) \g /dev/null
SELECT pg_temp.ok((SELECT c.clave FROM habito h JOIN categoria c ON c.id = h.categoria_id
                    WHERE h.id = current_setting('t.h_lec')::uuid) = 'educacion', 'la categoría se deriva de la subcategoría');
SELECT pg_temp.ok((SELECT prioridad FROM habito WHERE id = current_setting('t.h_lec')::uuid) = 2, 'prioridad nace en media (2)');
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.u'), true) \g /dev/null
INSERT INTO habito (region, usuario_id, subcategoria_id, nombre, frecuencia_tipo, meta, unidad, prioridad, intencion)
VALUES ('MX-NORTE', current_setting('t.u')::uuid, pg_temp.sub('hidratacion'), 'Tomar agua', 'diaria', 8, 'vasos', 1,
        'Después de lavarme los dientes');
UPDATE habito SET prioridad = 3 WHERE region = 'MX-NORTE' AND id = current_setting('t.h_lec')::uuid;
SELECT pg_temp.espera_error(format($$UPDATE habito SET categoria_id = (SELECT id FROM categoria WHERE clave = 'salud')
    WHERE region = 'MX-NORTE' AND id = %L$$, current_setting('t.h_lec')), 'KZ011', 'kaizen_api no cambia la categoría sin la subcategoría');
SELECT pg_temp.espera_error(format($$UPDATE habito SET meta = 99 WHERE region = 'MX-NORTE' AND id = %L$$, current_setting('t.h_lec')),
    '42501', 'kaizen_api sigue sin poder cambiar la meta');
UPDATE habito SET subcategoria_id = pg_temp.sub('estudio'), unidad = 'min'
 WHERE region = 'MX-NORTE' AND id = current_setting('t.h_lec')::uuid;
RESET ROLE;
SELECT pg_temp.ok((SELECT prioridad = 3 AND subcategoria_id = pg_temp.sub('estudio') FROM habito
                    WHERE id = current_setting('t.h_lec')::uuid), 'kaizen_api cambia prioridad y subcategoría (con unidad válida)');
SELECT pg_temp.ok((SELECT intencion FROM habito WHERE nombre = 'Tomar agua' AND usuario_id = current_setting('t.u')::uuid)
                  = 'Después de lavarme los dientes',
                  'kaizen_api guarda la intención "Después de ___"');

\echo '--- 2. Evaluación con evidencia (zonas)'
SELECT pg_temp.ok(pg_temp.ev('aerobico_moderado', 'min', 30) = 'optimo|-', 'aeróbico 30 min/día (210/sem) = óptimo (OMS 150–300)');
SELECT pg_temp.ok(pg_temp.ev('aerobico_moderado', 'min', 50) = 'alto|-', 'aeróbico 50 min/día (350/sem) = alto, sin pedir bajar');
SELECT pg_temp.ok(pg_temp.ev('aerobico_moderado', 'min', 120) = 'excesivo|85.00', '2 h/día = excesivo, sugiere 85 min (600/sem)');
SELECT pg_temp.ok(pg_temp.ev('aerobico_moderado', 'h', 3) = 'excesivo|1.25', '3 h/día = excesivo, sugiere 1.25 h');
SELECT pg_temp.ok(pg_temp.ev('aerobico_moderado', 'min', 10) = 'bajo|25.00', '10 min/día = bajo, hacia 25 min');
SELECT pg_temp.ok(pg_temp.ev('aerobico_moderado', 'min', 45, 'n_por_semana', 3::smallint) = 'bajo|50.00',
                  '45 min 3 veces/sem (135) = bajo, hacia 50 por sesión');
SELECT pg_temp.ok(pg_temp.ev('vigoroso', 'min', 60) = 'excesivo|40.00', 'vigoroso 60 min/día (420/sem) = excesivo (tope 300)');
SELECT pg_temp.ok(pg_temp.ev('hidratacion', 'vasos', 8) = 'optimo|-', '8 vasos (2 L) = óptimo');
SELECT pg_temp.ok(pg_temp.ev('hidratacion', 'vasos', 20) = 'excesivo|16.00', '20 vasos (5 L) = excesivo, sugiere 16 (4 L)');
SELECT pg_temp.ok(pg_temp.ev('sueno', 'h', 11) = 'excesivo|10.00', 'dormir 11 h = excesivo, sugiere 10');
SELECT pg_temp.ok(pg_temp.ev('sueno', 'h', 6) = 'bajo|7.00', 'dormir 6 h = bajo, hacia 7');
SELECT pg_temp.ok(pg_temp.ev('meditacion', 'min', 60) = 'excesivo|45.00', 'meditar 60 min = excesivo, sugiere 45');
SELECT pg_temp.ok(pg_temp.ev('lectura', 'páginas', 20) = 'bajo|24.00', '20 páginas/día (175 min/sem) = bajo, hacia 24 páginas');
SELECT pg_temp.ok(pg_temp.ev('reducir_alcohol', 'bebidas', 1) = 'excesivo|1.00', 'reducir: 1 bebida diaria (7/sem) = excesivo');
SELECT pg_temp.ok(pg_temp.ev('reducir_alcohol', 'bebidas', 1, 'n_por_semana', 2::smallint) = 'optimo|-', 'reducir: 2 por semana = óptimo');
SELECT pg_temp.ok(pg_temp.ev('reducir_azucar', 'g', 40) = 'alto|25.00', 'reducir: 40 g de azúcar = alto, hacia 25');
SELECT pg_temp.ok(pg_temp.ev('dejar_fumar', 'cigarros', 5) = 'alto|1.00', 'tabaco: todo límite > 0 es alto');
SELECT pg_temp.ok(pg_temp.ev('aerobico_moderado', 'km', 3) LIKE 'sin_referencia%', 'km no se compara con la OMS');
SELECT pg_temp.ok(pg_temp.ev('reducir_pantallas', 'min', 120) LIKE 'sin_referencia%', 'pantallas: sin rango científico');
SELECT pg_temp.ok((SELECT optimo_desde = 21.43 AND optimo_hasta = 42.86 AND cita LIKE 'OMS 2020%'
                     FROM fn_evaluar_meta(pg_temp.sub('aerobico_moderado'), 'min', 30, 'diaria', NULL, NULL)),
                  'el rango se devuelve por sesión, con su cita');

\echo '--- 3. Escalera v2'
SELECT set_config('t.h1', pg_temp.habito(current_setting('t.u')::uuid, 'aerobico_moderado', 20, 'min')::text, false),
       set_config('t.h2', pg_temp.habito(current_setting('t.u')::uuid, 'aerobico_moderado', 40, 'min')::text, false),
       set_config('t.h3', pg_temp.habito(current_setting('t.u')::uuid, 'aerobico_moderado', 120, 'min', 0)::text, false),
       set_config('t.h4', pg_temp.habito(current_setting('t.u')::uuid, 'sueno', 7, 'h')::text, false),
       set_config('t.h5', pg_temp.habito(current_setting('t.u')::uuid, 'meditacion', 10, 'min')::text, false),
       set_config('t.h6', pg_temp.habito(current_setting('t.u')::uuid, 'reducir_azucar', 60, 'g')::text, false),
       set_config('t.h7', pg_temp.habito(current_setting('t.u')::uuid, 'reducir_pantallas', 120, 'min')::text, false),
       set_config('t.h8', pg_temp.habito(current_setting('t.u')::uuid, 'reducir_azucar', 60, 'g', 0)::text, false),
       set_config('t.h9', pg_temp.habito(current_setting('t.u')::uuid, 'hidratacion', 6, 'vasos')::text, false),
       set_config('t.h10', pg_temp.habito(current_setting('t.u')::uuid, 'pasos', 6000, 'pasos')::text, false) \g /dev/null
SELECT pg_temp.registrar(current_setting('t.h1')::uuid, -20, -1, true),
       pg_temp.registrar(current_setting('t.h2')::uuid, -20, -1, true),
       pg_temp.registrar(current_setting('t.h4')::uuid, -20, -1, false),
       pg_temp.registrar(current_setting('t.h5')::uuid, -20, -1, false),
       pg_temp.registrar(current_setting('t.h6')::uuid, -20, -1, true),
       pg_temp.registrar(current_setting('t.h7')::uuid, -20, -1, true),
       pg_temp.registrar(current_setting('t.h9')::uuid, -20, -1, false),
       pg_temp.registrar(current_setting('t.h10')::uuid, -20, -1, true) \g /dev/null
-- Un "Mantener" de hace 3 días bloquea a h10; uno de hace 10 días no bloquea a h1
INSERT INTO sugerencia_ajuste (region, habito_id, tipo, meta_actual, meta_propuesta, cumplimiento_14d, estado, resuelta_en)
VALUES ('MX-NORTE', current_setting('t.h10')::uuid, 'subir', 6000, 6500, 100, 'rechazada', now() - interval '3 days'),
       ('MX-NORTE', current_setting('t.h1')::uuid,  'subir', 20, 22, 100, 'rechazada', now() - interval '10 days');
SET LOCAL ROLE kaizen_tareas;
CALL sp_generar_sugerencias('MX-NORTE', current_date, NULL);
RESET ROLE;
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h1')::uuid) = 'subir 25.00 cumplimiento_alto',
                  'bajo + 100 %: sube +10 % redondeado al paso (20 → 25 min, ≤ +30 %)');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h2')::uuid) IS NULL, 'en el óptimo + 100 %: no sube ("ritmo ideal")');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h3')::uuid) = 'bajar 85.00 excede_maximo',
                  'excesivo: propone bajar al tope desde el primer día (2 h → 85 min)');
SELECT pg_temp.ok((SELECT cumplimiento_14d IS NULL AND referencia_id IS NOT NULL FROM sugerencia_ajuste
                    WHERE habito_id = current_setting('t.h3')::uuid), 'la sugerencia por exceso guarda la referencia, sin % de 14 días');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h4')::uuid) IS NULL, 'sueño 7 h con 0 %: no baja de 7 h (piso)');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h5')::uuid) = 'bajar 9.00 cumplimiento_bajo',
                  '< 50 %: baja −15 % redondeado al paso (10 → 9 min); ruta "bajar" probada');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h6')::uuid) = 'bajar 55.00 cumplimiento_alto',
                  'reducir + 100 %: baja el límite (60 → 55 g)');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h7')::uuid) = 'bajar 110.00 cumplimiento_alto',
                  'reducir sin rango: baja el límite −10 % (120 → 110 min)');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h8')::uuid) IS NULL, 'reducir excesivo sin historia: no se fuerza (baja gradual)');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h9')::uuid) IS NULL, 'agua 1.5 L con 0 %: no baja del piso de 1.5 L');
SELECT pg_temp.ok(pg_temp.pendiente(current_setting('t.h10')::uuid) IS NULL, '"Mantener" hace 3 días: espera 7 días');
SELECT pg_temp.ok((SELECT referencia_id IS NULL FROM sugerencia_ajuste WHERE habito_id = current_setting('t.h7')::uuid
                    AND estado = 'pendiente'), 'sin rango: la sugerencia no tiene referencia');
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.u'), true) \g /dev/null
DO $$ DECLARE v uuid; BEGIN
    SELECT id INTO v FROM sugerencia_ajuste WHERE habito_id = current_setting('t.h1')::uuid AND estado = 'pendiente';
    CALL sp_responder_sugerencia('MX-NORTE', current_setting('t.u')::uuid, v, true);
END $$;
RESET ROLE;
SELECT pg_temp.ok((SELECT meta FROM habito WHERE id = current_setting('t.h1')::uuid) = 25, 'aceptar sube la meta a 25');
SELECT pg_temp.ok(EXISTS (SELECT 1 FROM logro_usuario WHERE usuario_id = current_setting('t.u')::uuid
                           AND logro_clave = 'primer_micro_paso'), 'aceptar una subida otorga "Primer micro-paso"');

\echo '--- 4. Protector de racha (1 falla por semana ISO)'
-- Dos semanas completas que terminan el domingo pasado
SELECT set_config('t.lun', (date_trunc('week', current_date)::date - 14 - current_date)::text, false) \g /dev/null
SELECT set_config('t.ra', pg_temp.habito(current_setting('t.v')::uuid, 'pasos', 8000, 'pasos', 40)::text, false),
       set_config('t.rb', pg_temp.habito(current_setting('t.v')::uuid, 'pasos', 8000, 'pasos', 40)::text, false),
       set_config('t.rc', pg_temp.habito(current_setting('t.v')::uuid, 'pasos', 8000, 'pasos', 40)::text, false) \g /dev/null
-- A: falta solo el miércoles de la semana 1
SELECT pg_temp.registrar(current_setting('t.ra')::uuid, current_setting('t.lun')::int, current_setting('t.lun')::int + 1, true),
       pg_temp.registrar(current_setting('t.ra')::uuid, current_setting('t.lun')::int + 3, current_setting('t.lun')::int + 13, true) \g /dev/null
-- B: faltan miércoles y viernes de la semana 1
SELECT pg_temp.registrar(current_setting('t.rb')::uuid, current_setting('t.lun')::int, current_setting('t.lun')::int + 1, true),
       pg_temp.registrar(current_setting('t.rb')::uuid, current_setting('t.lun')::int + 3, current_setting('t.lun')::int + 3, true),
       pg_temp.registrar(current_setting('t.rb')::uuid, current_setting('t.lun')::int + 5, current_setting('t.lun')::int + 13, true) \g /dev/null
-- C: falta el miércoles de cada semana
SELECT pg_temp.registrar(current_setting('t.rc')::uuid, current_setting('t.lun')::int, current_setting('t.lun')::int + 1, true),
       pg_temp.registrar(current_setting('t.rc')::uuid, current_setting('t.lun')::int + 3, current_setting('t.lun')::int + 8, true),
       pg_temp.registrar(current_setting('t.rc')::uuid, current_setting('t.lun')::int + 10, current_setting('t.lun')::int + 13, true) \g /dev/null
SELECT pg_temp.ok((SELECT racha_actual = 13 AND ultimo_protegido = current_date + current_setting('t.lun')::int + 2
                     FROM racha WHERE habito_id = current_setting('t.ra')::uuid), 'una falla en la semana: la racha sigue (13 de 14)');
SELECT pg_temp.ok((SELECT racha_actual FROM racha WHERE habito_id = current_setting('t.rb')::uuid) = 9,
                  'segunda falla en la misma semana: la racha se rompe (9)');
SELECT pg_temp.ok((SELECT racha_actual FROM racha WHERE habito_id = current_setting('t.rc')::uuid) = 12,
                  'una falla en cada semana: las dos se perdonan (12)');
SELECT pg_temp.ok(EXISTS (SELECT 1 FROM logro_usuario WHERE usuario_id = current_setting('t.v')::uuid
                           AND logro_clave = 'racha_salvada'), 'el protector otorga "Racha salvada"');
SELECT pg_temp.ok((SELECT count(*) FROM logro_usuario WHERE usuario_id = current_setting('t.v')::uuid
                    AND logro_clave = 'racha_7') = 1, '"Primera semana" se otorga una sola vez aunque 3 hábitos lleguen a 7');
-- Racha vigente: el último registro fue anteayer y ayer no hubo (una falla): se protege
SELECT set_config('t.rv', pg_temp.habito(current_setting('t.w')::uuid, 'pasos', 8000, 'pasos', 40)::text, false) \g /dev/null
SELECT pg_temp.registrar(current_setting('t.rv')::uuid, -6, -2, true) \g /dev/null
SELECT pg_temp.ok((SELECT racha_actual FROM v_racha_vigente WHERE habito_id = current_setting('t.rv')::uuid) = 5,
                  'racha vigente: un día sin registro (ayer) no la tira a 0 (antes daba 0)');
SELECT pg_temp.ok((SELECT protector_usado_semana = (date_trunc('week', current_date - 1) = date_trunc('week', current_date))
                     FROM v_racha_vigente WHERE habito_id = current_setting('t.rv')::uuid),
                  'v_racha_vigente informa si el protector ya se usó esta semana');

\echo '--- 5. Cápsulas 7/30/66'
SELECT pg_temp.espera_error(format($$INSERT INTO capsula (region, habito_id, usuario_id, mensaje_cifrado, racha_objetivo)
    VALUES ('MX-NORTE', %L, %L, decode(repeat('00', 40), 'hex'), 21)$$, current_setting('t.ra'), current_setting('t.v')),
    '23514', 'el objetivo 21 ya no existe (mito)');
INSERT INTO capsula (region, habito_id, usuario_id, mensaje_cifrado, racha_objetivo, creada_en)
VALUES ('MX-NORTE', current_setting('t.ra')::uuid, current_setting('t.v')::uuid, decode(repeat('00', 40), 'hex'), 7,
        now() - interval '30 days');
INSERT INTO capsula (region, habito_id, usuario_id, mensaje_cifrado, racha_objetivo)
VALUES ('MX-NORTE', current_setting('t.rb')::uuid, current_setting('t.v')::uuid, decode(repeat('00', 40), 'hex'), 30);
SELECT pg_temp.ok((SELECT count(*) FROM capsula WHERE habito_id = current_setting('t.rb')::uuid AND racha_objetivo = 30) = 1,
                  'el objetivo 30 se acepta');
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.v'), true) \g /dev/null
DO $$ DECLARE c uuid; m bytea; v smallint; BEGIN
    SELECT id INTO c FROM capsula WHERE habito_id = current_setting('t.ra')::uuid;
    CALL sp_abrir_capsula('MX-NORTE', current_setting('t.v')::uuid, c, m, v);
END $$;
RESET ROLE;
SELECT pg_temp.ok(EXISTS (SELECT 1 FROM logro_usuario WHERE usuario_id = current_setting('t.v')::uuid
                           AND logro_clave = 'capsula_abierta'), 'abrir una cápsula (con el protector en la racha) otorga su logro');

\echo '--- 6. Logros'
SELECT pg_temp.ok(EXISTS (SELECT 1 FROM logro_usuario WHERE usuario_id = current_setting('t.u')::uuid
                           AND logro_clave = 'plan_si_entonces'), 'escribir una intención otorga "Plan si-entonces"');
-- Semana OMS: W hizo 30 min diarios toda la semana pasada (210 ≥ 150); V no tiene hábitos aeróbicos
SELECT set_config('t.om', pg_temp.habito(current_setting('t.w')::uuid, 'aerobico_moderado', 30, 'min', 40)::text, false) \g /dev/null
SELECT pg_temp.registrar(current_setting('t.om')::uuid,
                         (date_trunc('week', current_date)::date - 7 - current_date), (date_trunc('week', current_date)::date - 1 - current_date),
                         true, 30) \g /dev/null
-- Ritmo ideal: aeróbico 30 min/día (óptimo), sin cambio de nivel y todo cumplido 5 semanas
SELECT set_config('t.ri', pg_temp.habito(current_setting('t.w')::uuid, 'aerobico_moderado', 35, 'min', 45)::text, false) \g /dev/null
SELECT pg_temp.registrar(current_setting('t.ri')::uuid, -40, -1, true) \g /dev/null
SET LOCAL ROLE kaizen_tareas;
CALL sp_otorgar_logros_semanales(current_date, NULL);
RESET ROLE;
SELECT pg_temp.ok(EXISTS (SELECT 1 FROM logro_usuario WHERE usuario_id = current_setting('t.w')::uuid AND logro_clave = 'semana_oms'),
                  '210 min moderados en la semana: "Semana OMS"');
SELECT pg_temp.ok(NOT EXISTS (SELECT 1 FROM logro_usuario WHERE usuario_id = current_setting('t.v')::uuid AND logro_clave = 'semana_oms'),
                  'sin actividad aeróbica no hay "Semana OMS"');
SELECT pg_temp.ok((SELECT habito_id FROM logro_usuario WHERE usuario_id = current_setting('t.w')::uuid
                    AND logro_clave = 'ritmo_ideal') = current_setting('t.ri')::uuid, '4 semanas en el óptimo: "Ritmo ideal"');
DO $$ DECLARE n integer; BEGIN
    CALL sp_otorgar_logros_semanales(current_date, n);
    PERFORM pg_temp.ok(n = 0, 'correr dos veces los logros semanales no duplica');
END $$;
SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('t.w'), true) \g /dev/null
SELECT pg_temp.ok((SELECT count(*) FROM fn_logros_usuario('MX-NORTE', current_setting('t.w')::uuid)) = 10,
                  'fn_logros_usuario devuelve los 10 logros');
SELECT pg_temp.ok((SELECT progreso FROM fn_logros_usuario('MX-NORTE', current_setting('t.w')::uuid) WHERE clave = 'racha_30') = 30,
                  'progreso de "Un mes" = la mejor racha, hasta 30');
SELECT pg_temp.ok((SELECT count(*) FROM logro_usuario) = (SELECT count(*) FROM logro_usuario WHERE usuario_id = current_setting('t.w')::uuid),
                  'RLS: kaizen_api solo ve los logros del usuario actual');
SELECT pg_temp.ok((SELECT count(*) FROM fn_logros_usuario('MX-NORTE', current_setting('t.u')::uuid) WHERE obtenido) = 0,
                  'RLS: no se ven los logros obtenidos de otra persona');
RESET ROLE;

\echo '--- 7. Administración del catálogo'
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error(format($$CALL sp_admin_crear_subcategoria(%L, %L, 'Música', 'aumentar', ARRAY['min'], NULL, NULL)$$,
    current_setting('t.u'), (SELECT id FROM categoria WHERE clave = 'bienestar')), 'KZ010', 'un usuario normal no crea subcategorías');
DO $$ DECLARE v uuid; c uuid; BEGIN
    SELECT id INTO c FROM categoria WHERE clave = 'bienestar';
    CALL sp_admin_crear_subcategoria(current_setting('t.adm')::uuid, c, 'Tocar música', 'aumentar', ARRAY['min', 'canciones'], NULL, v);
    PERFORM set_config('t.mus', v::text, false);
END $$;
RESET ROLE;
SELECT pg_temp.ok((SELECT clave FROM subcategoria WHERE id = current_setting('t.mus')::uuid) = 'tocar_musica', 'admin crea subcategoría con clave');
UPDATE unidad_subcategoria SET factor_a_base = 1 WHERE subcategoria_id = current_setting('t.mus')::uuid AND unidad = 'min';
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error(format($$CALL sp_admin_guardar_referencia(%L, %L, 'semana', 'min', 60, 120, NULL,
    'Sin fuente', 'X1', 'https://ejemplo.org', 'baja')$$, current_setting('t.adm'), current_setting('t.mus')),
    'KZ011', 'una referencia exige fuentes con formato F##');
CALL sp_admin_guardar_referencia(current_setting('t.adm')::uuid, current_setting('t.mus')::uuid, 'semana', 'min', 60, 120, NULL,
     'Referencia de prueba', 'F11', 'https://ejemplo.org', 'baja');
CALL sp_admin_actualizar_subcategoria(current_setting('t.adm')::uuid, current_setting('t.mus')::uuid, NULL, false);
RESET ROLE;
SELECT pg_temp.ok((SELECT count(*) FROM referencia_cientifica WHERE subcategoria_id = current_setting('t.mus')::uuid) = 1,
                  'admin guarda una referencia válida');
SELECT pg_temp.espera_error(format($$SELECT pg_temp.habito(%L, 'tocar_musica', 20, 'min')$$, current_setting('t.u')),
    'KZ017', 'subcategoría inactiva no se usa en hábitos nuevos');

\echo '--- 8. Permisos'
SET LOCAL ROLE kaizen_etl;
SELECT pg_temp.ok((SELECT count(*) FROM referencia_cientifica) >= 18 AND (SELECT count(*) FROM v_habito_evidencia) > 0,
                  'kaizen_etl lee referencias y la evaluación de los hábitos');
RESET ROLE;
SET LOCAL ROLE kaizen_api;
SELECT pg_temp.espera_error($$INSERT INTO referencia_cientifica (subcategoria_id, periodo, unidad_base, optimo_desde, optimo_hasta,
    cita, fuentes, url, confianza) VALUES (gen_random_uuid(), 'dia', 'min', 1, 2, 'xxx', 'F01', 'https://x', 'baja')$$,
    '42501', 'kaizen_api no escribe referencias directamente');
SELECT pg_temp.espera_error($$CALL sp_otorgar_logros_semanales(current_date, NULL)$$, '42501',
    'kaizen_api no ejecuta los logros semanales');
SELECT pg_temp.espera_error($$INSERT INTO logro_usuario (region, usuario_id, logro_clave) VALUES ('MX-NORTE', gen_random_uuid(), 'racha_7')$$,
    '42501', 'kaizen_api no se otorga logros');
RESET ROLE;
SELECT pg_temp.ok(NOT has_function_privilege('public', 'kaizen.fn_otorgar_logro(kaizen.region_t, uuid, text, uuid)', 'EXECUTE'),
                  'fn_otorgar_logro no la ejecuta PUBLIC');

\echo '--- Fin: todas las pruebas de los cambios del 27-nov pasaron'
ROLLBACK;
