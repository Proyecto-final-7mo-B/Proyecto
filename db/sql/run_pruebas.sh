#!/usr/bin/env bash
# Recrea la base de prueba, aplica 01-07 y corre 90_pruebas.sql.
# Uso: PGHOST=... PGPORT=... ./run_pruebas.sh
set -euo pipefail
cd "$(dirname "$0")"
P="psql -X -q -v ON_ERROR_STOP=1"
$P -U postgres -c "DROP DATABASE IF EXISTS kaizen" -c "CREATE DATABASE kaizen OWNER kaizen_owner"
for f in 01 02 03 04 05; do $P -U kaizen_owner -d kaizen -f ${f}_*.sql; done
$P -U postgres -d kaizen -f 06_roles.sql 2>/dev/null
$P -U kaizen_owner -d kaizen -f 07_rls.sql
psql -X -v ON_ERROR_STOP=1 -U postgres -d kaizen -f 90_pruebas.sql 2>&1 | grep -E '^---|OK |FALLA|ERROR'
