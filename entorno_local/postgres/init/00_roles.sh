#!/usr/bin/env bash
# Kaizen · 00_roles.sh
# Crea los roles que el esquema necesita, con la misma configuración que en el clúster
# (consultada en nodo1 el 23-nov-2026) y la base "kaizen" con dueño kaizen_owner.
# Las contraseñas son las LOCALES de .env, nunca las de producción.
# Docker solo ejecuta este script la primera vez (cuando el volumen está vacío).
set -eo pipefail

psql -X -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
     -v api_pass="$KAIZEN_DB_PASSWORD" -v etl_pass="$KAIZEN_ETL_DB_PASSWORD" \
     -v tareas_pass="$KAIZEN_TAREAS_DB_PASSWORD" <<'SQL'
-- Dueño del esquema: no inicia sesión (igual que en producción)
CREATE ROLE kaizen_owner NOLOGIN;
-- Grupo para personas (DBA); sin login
CREATE ROLE kaizen_admin NOLOGIN;

-- Cuentas de servicio
CREATE ROLE kaizen_api LOGIN NOINHERIT CONNECTION LIMIT 40 PASSWORD :'api_pass';
CREATE ROLE kaizen_etl LOGIN NOINHERIT CONNECTION LIMIT 4  PASSWORD :'etl_pass';
CREATE ROLE kaizen_tareas LOGIN NOINHERIT CONNECTION LIMIT 2 PASSWORD :'tareas_pass';   -- tareas programadas
CREATE ROLE kaizen_monitor LOGIN INHERIT CONNECTION LIMIT 3;          -- sin contraseña: no se usa en local
GRANT pg_monitor TO kaizen_monitor WITH INHERIT TRUE;

-- Mismos límites que en el clúster
ALTER ROLE kaizen_api SET statement_timeout = '5s';
ALTER ROLE kaizen_api SET idle_in_transaction_session_timeout = '15s';
ALTER ROLE kaizen_etl SET default_transaction_read_only = on;
ALTER ROLE kaizen_etl SET statement_timeout = '5min';
ALTER ROLE kaizen_tareas SET statement_timeout = '10min';
ALTER ROLE kaizen_tareas SET idle_in_transaction_session_timeout = '1min';

CREATE DATABASE kaizen OWNER kaizen_owner;
GRANT CONNECT ON DATABASE kaizen TO kaizen_tareas;
SQL

echo "kaizen: roles y base creados"
