#!/usr/bin/env bash
# Reconstruye la estructura vigente y corre todas las pruebas, en el mismo orden que el clúster:
#   1. ../sql/run_pruebas.sh       → recrea la base, aplica 01-07 y corre las 62 pruebas originales
#   2. cambios del 23-nov          → pruebas_ajustes.sql (40 pruebas)
#   3. cambios del 27-nov          → pruebas_evidencia.sql (respaldo científico)
#   4. recomendaciones del 27-nov  → pruebas_recomendaciones.sql (hábitos recomendados, fuentes, días protegidos)
# Cada archivo de pruebas corre en una transacción que se revierte: no deja datos.
# Uso: PGHOST=... PGPORT=... ./run_pruebas.sh
# IA: asistido (Claude). Revisión: Jael Contreras.
set -euo pipefail
cd "$(dirname "$0")"
aplicar() { echo "--- Aplicando $1"; psql -X -q -v ON_ERROR_STOP=1 -U postgres -d kaizen -f "$1" >/dev/null; }
probar()  { psql -X -v ON_ERROR_STOP=1 -U postgres -d kaizen -f "$1" 2>&1 | grep -E '^---|OK |FALLA|ERROR'; }

../sql/run_pruebas.sh
for f in 2026-11-23_*.sql; do aplicar "$f"; done
probar pruebas_ajustes.sql
for f in 2026-11-27_evidencia_cientifica.sql; do aplicar "$f"; done
probar pruebas_evidencia.sql
aplicar 2026-11-27_recomendaciones.sql
probar pruebas_recomendaciones.sql
