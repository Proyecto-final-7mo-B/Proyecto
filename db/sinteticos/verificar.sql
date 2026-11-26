-- =====================================================================
-- Kaizen · evidencia de la carga sintética: fragmentación, directorio y replicación.
-- Uso (en el primario):  ssh nodo2-proyecto 'cd /tmp && sudo -u postgres psql -X -d kaizen' < verificar.sql
-- Solo lee: no cambia nada.
-- IA: asistido (Claude). Revisión: Jael Contreras.
-- =====================================================================
\pset footer off
SET search_path = kaizen, pg_temp;

\echo '=== 1. Filas por fragmento (partición física) de las tablas con más datos'
SELECT tableoid::regclass AS fragmento, count(*) AS filas FROM registro GROUP BY 1
UNION ALL SELECT tableoid::regclass, count(*) FROM usuario GROUP BY 1
UNION ALL SELECT tableoid::regclass, count(*) FROM habito GROUP BY 1
UNION ALL SELECT tableoid::regclass, count(*) FROM senal_diaria GROUP BY 1
ORDER BY 1;

\echo '=== 2. Reparto de check-ins por región (debe ser casi en tercios)'
SELECT region, count(*) AS checkins, round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS porcentaje,
       round(100.0 * avg(cumplido::int), 1) AS pct_cumplidos
  FROM registro GROUP BY region ORDER BY region;

\echo '=== 3. Directorio de fragmentos: usuario → región (global, sin correos en claro)'
SELECT region, count(*) AS usuarios_en_directorio FROM directorio_usuarios GROUP BY region ORDER BY region;
SELECT count(*) FILTER (WHERE d.usuario_id IS NULL) AS usuarios_sin_directorio FROM usuario u
  LEFT JOIN directorio_usuarios d ON d.usuario_id = u.id AND d.region = u.region;

\echo '=== 4. Poda de particiones: una consulta con la región solo lee su fragmento'
EXPLAIN (COSTS OFF)
SELECT count(*) FROM registro WHERE region = 'LATAM' AND fecha >= current_date - 30;

\echo '=== 5. Tamaño en disco por fragmento'
SELECT c.oid::regclass AS fragmento, pg_size_pretty(pg_total_relation_size(c.oid)) AS tamano
  FROM pg_inherits i JOIN pg_class c ON c.oid = i.inhrelid
 WHERE i.inhparent IN ('kaizen.registro'::regclass, 'kaizen.usuario'::regclass, 'kaizen.senal_diaria'::regclass)
 ORDER BY 1;
SELECT pg_size_pretty(pg_database_size('kaizen')) AS base_kaizen;

\echo '=== 6. Replicación: las réplicas recibieron todo (retraso en bytes)'
SELECT application_name AS replica, state, sync_state,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS bytes_por_aplicar, replay_lag
  FROM pg_stat_replication ORDER BY 1;
