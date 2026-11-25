#!/usr/bin/env bash
# Reconstruye la estructura vigente y corre todas las pruebas:
#   1. ../sql/run_pruebas.sh  → recrea la base, aplica 01-07 y corre las 62 pruebas originales
#   2. aplica los cambios fechados (2026-*.sql) en orden, como en el clúster
#   3. corre pruebas_ajustes.sql (40 pruebas; se revierte, no deja datos)
# Uso: PGHOST=... PGPORT=... ./run_pruebas.sh
# IA: asistido (Claude). Revisión: Jael Contreras.
set -euo pipefail
cd "$(dirname "$0")"
../sql/run_pruebas.sh
for f in 2026-*.sql; do
    echo "--- Aplicando $f"
    psql -X -q -v ON_ERROR_STOP=1 -U postgres -d kaizen -f "$f" >/dev/null
done
psql -X -v ON_ERROR_STOP=1 -U postgres -d kaizen -f pruebas_ajustes.sql 2>&1 | grep -E '^---|OK |FALLA|ERROR'
