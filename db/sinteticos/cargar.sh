#!/usr/bin/env bash
# Carga el SQL generado en el PRIMARIO del clúster, como postgres, en una sola transacción.
# Uso: ./cargar.sh <alias-ssh-del-primario> [archivo.sql]
#   El primario se consulta con: ssh nodo1-proyecto sudo kpatronictl list   (rol "Leader")
#   Si el nodo no es el primario, el propio SQL se detiene sin cambiar nada.
# IA: asistido (Claude). Revisión: Jael Contreras.
set -euo pipefail
cd "$(dirname "$0")"
HOST=${1:?"Uso: ./cargar.sh <alias-ssh-del-primario> [archivo.sql]"}
SQL=${2:-salida/carga_sintetica.sql}
[ -f "$SQL" ] || { echo "No existe $SQL: primero corre generar.py" >&2; exit 1; }
echo "Cargando $SQL ($(du -h "$SQL" | cut -f1)) en $HOST…"
time ssh "$HOST" 'cd /tmp && sudo -u postgres psql -X -v ON_ERROR_STOP=1 -d kaizen' < "$SQL"
