#!/usr/bin/env bash
# Kaizen · 10_esquema.sh
# Restaura la estructura del clúster (pg_dump --schema-only de PostgreSQL 16.15, tomado del primario el
# 23-nov-2026 DESPUÉS de los ajustes de frontend y backend): esquema kaizen, 13 tablas (9 con 3 fragmentos por
# región, bitácora con una partición por mes), funciones, triggers, procedimientos, vistas, permisos y RLS.
# El catálogo de 8 categorías se carga aparte (20_catalogo.sh) porque el dump no lleva datos.
# No trae datos: para eso está el poblador (docker compose run --rm poblar).
set -eo pipefail

psql -X -q -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname kaizen -f /kaizen/kaizen_esquema.sql

psql -X -At --username "$POSTGRES_USER" --dbname kaizen -c \
  "SELECT 'kaizen: esquema restaurado · tablas=' || count(*) FILTER (WHERE NOT relispartition)
          || ' · particiones=' || count(*) FILTER (WHERE relispartition)
     FROM pg_class WHERE relnamespace = 'kaizen'::regnamespace AND relkind IN ('r', 'p')"
