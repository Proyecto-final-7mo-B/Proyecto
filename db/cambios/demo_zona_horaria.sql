-- Kaizen · demostración del problema de zona horaria (se revierte, no deja datos)
-- Córrela entre las 18:00 y las 23:59 de México: es cuando la fecha UTC ya es "mañana".
\pset footer off
BEGIN;
SET LOCAL search_path = kaizen, pg_temp;
-- Usuaria de CDMX con un hábito diario cumplido 10 días seguidos, hasta AYER (hora de México)
SELECT set_config('d.u', gen_random_uuid()::text, true), set_config('d.h', gen_random_uuid()::text, true) \g /dev/null
INSERT INTO usuario (id, region, nombre, email, password_hash, pais, acepto_aviso_en)
VALUES (current_setting('d.u')::uuid, 'MX-CENTRO-SUR', 'Demo TZ', 'tz@demo.test', '$argon2id$v=19$demo', 'MX', now());
INSERT INTO habito (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo, meta, unidad, fecha_creacion)
SELECT current_setting('d.h')::uuid, 'MX-CENTRO-SUR', current_setting('d.u')::uuid, id, 'Leer', 'diaria', 10, 'pág', now() - interval '20 days'
  FROM categoria WHERE nombre = 'Lectura';
INSERT INTO registro (id, region, habito_id, usuario_id, fecha, cumplido, valor, origen)
SELECT gen_random_uuid(), 'MX-CENTRO-SUR', current_setting('d.h')::uuid, current_setting('d.u')::uuid, d::date, true, 10, 'manual'
  FROM generate_series((now() AT TIME ZONE 'America/Mexico_City')::date - 10,
                       (now() AT TIME ZONE 'America/Mexico_City')::date - 1, interval '1 day') d;

SET LOCAL ROLE kaizen_api;
SELECT set_config('kaizen.usuario_id', current_setting('d.u'), true) \g /dev/null

\echo '=== Como hoy (sesión en UTC, lo que pasa sin arreglo):'
SELECT now() AT TIME ZONE 'America/Mexico_City' AS hora_mexico, current_date AS hoy_segun_la_base,
       ultima_fecha, racha_actual AS racha_que_ve_la_app
  FROM v_racha_vigente WHERE habito_id = current_setting('d.h')::uuid;

\echo '=== Con el arreglo (la API fija la zona del usuario en la transacción):'
SELECT set_config('TimeZone', 'America/Mexico_City', true) \g /dev/null
SELECT now() AT TIME ZONE 'America/Mexico_City' AS hora_mexico, current_date AS hoy_segun_la_base,
       ultima_fecha, racha_actual AS racha_que_ve_la_app
  FROM v_racha_vigente WHERE habito_id = current_setting('d.h')::uuid;
ROLLBACK;
