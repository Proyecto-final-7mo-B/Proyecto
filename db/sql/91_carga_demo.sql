-- =====================================================================
-- Kaizen · 91_carga_demo.sql
-- Carga sintética mínima EN SQL (~150 mil check-ins) para medir los
-- triggers y comprobar la poda de particiones. NO sustituye al
-- generador de Python (punto 3.8), que produce datos realistas y sucios
-- a propósito para el proceso de limpieza con pandas.
-- Ejecutar como kaizen_owner sobre una base de prueba.
-- =====================================================================
\timing on
SET search_path = kaizen, pg_temp;
SELECT setseed(0.42);

INSERT INTO categoria (nombre) VALUES
  ('Hidratación'), ('Ejercicio'), ('Sueño'), ('Estudio'), ('Lectura'), ('Meditación')
ON CONFLICT DO NOTHING;

-- 1,000 usuarios: 35 % MX-NORTE, 55 % MX-CENTRO-SUR, 10 % LATAM
CREATE TEMP TABLE u AS
SELECT gen_random_uuid() AS id, g,
       CASE WHEN r < 0.35 THEN 'MX-NORTE' WHEN r < 0.90 THEN 'MX-CENTRO-SUR' ELSE 'LATAM' END AS region,
       random() AS constancia
  FROM (SELECT g, random() AS r FROM generate_series(1, 1000) g) s;

INSERT INTO usuario (id, region, nombre, email, password_hash, pais, acepto_aviso_en, consentimiento_senales_en)
SELECT id, region, 'Usuario ' || g, 'u' || g || '@sintetico.test', '$argon2id$v=19$sintetico',
       CASE region WHEN 'LATAM' THEN 'CO' ELSE 'MX' END, now(),
       CASE WHEN random() < 0.6 THEN now() END
  FROM u;
INSERT INTO directorio_usuarios (email_hmac, usuario_id, region)
SELECT encode(sha256(convert_to('u' || g || '@sintetico.test', 'UTF8')), 'hex'), id, region FROM u;

-- ~2,500 hábitos creados hace 60 a 120 días
CREATE TEMP TABLE h AS
SELECT gen_random_uuid() AS id, u.id AS usuario_id, u.region, u.constancia,
       (SELECT id FROM categoria ORDER BY random() + k * 0 LIMIT 1) AS categoria_id,
       CASE WHEN f < 0.7 THEN 'diaria' WHEN f < 0.9 THEN 'dias_semana' ELSE 'n_por_semana' END AS tipo,
       (now() - (60 + floor(random() * 60 + k * 0)) * interval '1 day') AS creado
  FROM u CROSS JOIN LATERAL generate_series(1, 1 + floor(random() * 4 + u.g * 0)::int) k
  CROSS JOIN LATERAL (SELECT random() + k * 0 AS f) ff;

INSERT INTO habito (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo, dias_semana, veces_semana,
                    meta, unidad, fecha_creacion)
SELECT id, region, usuario_id, categoria_id, 'Hábito', tipo,
       CASE WHEN tipo = 'dias_semana' THEN (1|4|16)::smallint END,
       CASE WHEN tipo = 'n_por_semana' THEN 3::smallint END,
       10, 'unidades', creado
  FROM h;

-- Check-ins: un registro por día con probabilidad 0.8; cumplido según la
-- constancia de cada usuario. UNA sentencia: el trigger T1 recalcula
-- cada hábito una sola vez.
INSERT INTO registro (id, region, habito_id, usuario_id, fecha, cumplido, valor, origen)
SELECT gen_random_uuid(), h.region, h.id, h.usuario_id, d::date,
       random() < 0.35 + 0.6 * h.constancia, round((random() * 12)::numeric, 2),
       (ARRAY['manual', 'rapido', 'offline'])[1 + floor(random() * 3)::int]
  FROM h CROSS JOIN LATERAL generate_series(h.creado::date, current_date - 1, interval '1 day') d
 WHERE random() < 0.8;

ANALYZE usuario, habito, registro, racha, categoria;

\echo '--- Volumen por fragmento'
SELECT tableoid::regclass AS particion, count(*) AS filas
  FROM registro GROUP BY 1 ORDER BY 1;
SELECT relname AS particion, pg_size_pretty(pg_total_relation_size(oid)) AS tamano
  FROM pg_class WHERE relname LIKE 'registro_%' AND relkind = 'r' ORDER BY 1;

\echo '--- Poda de particiones: consulta típica de Inicio (con región del JWT)'
EXPLAIN (COSTS OFF)
SELECT r.fecha, r.cumplido FROM registro r
 WHERE r.region = 'MX-NORTE' AND r.usuario_id = (SELECT id FROM u WHERE region = 'MX-NORTE' LIMIT 1)
   AND r.fecha >= current_date - 7;

\echo '--- Sin la región la misma consulta recorre los 3 fragmentos'
EXPLAIN (COSTS OFF)
SELECT r.fecha, r.cumplido FROM registro r
 WHERE r.usuario_id = (SELECT id FROM u LIMIT 1) AND r.fecha >= current_date - 7;

\echo '--- Escalera para todas las regiones'
CALL sp_generar_sugerencias(NULL, current_date, NULL);
SELECT tipo, count(*) FROM sugerencia_ajuste GROUP BY tipo ORDER BY tipo;

\echo '--- Verificación del dato derivado'
CALL sp_reconstruir_rachas(NULL, NULL);
