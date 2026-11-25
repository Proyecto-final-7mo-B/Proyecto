#!/usr/bin/env bash
# Prueba en vivo de failover del clúster (guion: prueba_en_vivo.md).
# Se corre desde la laptop, con la VPN encendida y los alias SSH nodo1-proyecto, nodo2-proyecto y nodo3-proyecto.
#
#   ./prueba_en_vivo.sh estado                         roles, timeline y retraso
#   ./prueba_en_vivo.sh observador [nodo]               quién es líder cada 3 s (por omisión en nodo1)
#   ./prueba_en_vivo.sh contador <etiqueta> [s]         escribe en nodo1 como la API durante s segundos (240)
#   ./prueba_en_vivo.sh particion <nodo>                aísla el nodo 90 s (todo su tráfico WireGuard)
#   ./prueba_en_vivo.sh congelar <nodo>                 congela Patroni y PostgreSQL (el watchdog reinicia la VM)
#   ./prueba_en_vivo.sh verificar <etiqueta>            filas de la prueba en el primario y estado del clúster
#   ./prueba_en_vivo.sh limpiar <nodo>                  quita reglas o congelamientos que hayan quedado
set -euo pipefail

NODOS=(nodo1 nodo2 nodo3)

uso() { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

en() {   # en <nodo> <comando…>: corre el comando en el nodo por SSH
  local nodo=$1; shift
  ssh -t -o ConnectTimeout=8 "${nodo}-proyecto" "$@"
}

valida_nodo() {
  case "${1:-}" in nodo1 | nodo2 | nodo3) ;; *) echo "Nodo inválido: '${1:-}' (usa nodo1, nodo2 o nodo3)" >&2; exit 2 ;; esac
}

valida_etiqueta() {
  [[ "${1:-}" =~ ^[A-Za-z0-9_]{1,20}$ ]] || { echo "Etiqueta inválida: usa letras, números o _ (p. ej. demo1)" >&2; exit 2; }
}

primario() {   # imprime el nodo que hoy es primario
  local n
  for n in "${NODOS[@]}"; do
    if ssh -o ConnectTimeout=5 "${n}-proyecto" 'sudo kpatronictl list -f json' 2>/dev/null |
      python3 -c 'import json,sys; print(next(m["Member"] for m in json.load(sys.stdin) if m["Role"]=="Leader"))' 2>/dev/null; then
      return 0
    fi
  done
  echo "No se encontró un primario (¿VPN encendida? ¿clúster en elección?)" >&2
  return 1
}

avisa_si_no_es_primario() {
  local actual
  actual=$(primario || true)
  if [[ -n "$actual" && "$actual" != "$1" ]]; then
    echo "Ojo: el primario es $actual, no $1."
    read -r -p "¿Seguir de todos modos con $1? [s/N] " r
    [[ "$r" == "s" ]] || exit 1
  fi
}

accion=${1:-}
case "$accion" in
  estado)
    for n in "${NODOS[@]}"; do
      if en "$n" 'sudo kpatronictl list'; then exit 0; fi
    done
    exit 1
    ;;
  observador)
    nodo=${2:-nodo1}
    valida_nodo "$nodo"
    en "$nodo" 'sudo kaizen-observador 200'
    ;;
  contador)
    # El contador vive en nodo1: es el único nodo desde el que kaizen_api puede entrar (pg_hba), igual que la API.
    valida_etiqueta "${2:-}"
    segundos=${3:-240}
    [[ "$segundos" =~ ^[0-9]{1,4}$ ]] || { echo "Segundos inválidos" >&2; exit 2; }
    if [[ "$(primario || true)" == "nodo1" ]]; then
      echo "Ojo: nodo1 es el primario. Si lo aíslas, también cortas al contador. Haz antes un switchover:" >&2
      echo "  ssh nodo1-proyecto 'sudo kpatronictl switchover kaizen --leader nodo1 --candidate <síncrona>'" >&2
    fi
    en nodo1 "sudo kaizen-contador-failover $2 $segundos"
    ;;
  particion)
    valida_nodo "${2:-}"
    [[ "$2" != "nodo1" ]] || { echo "nodo1 tiene el contador: aislarlo invalida la prueba. Cambia antes el primario." >&2; exit 1; }
    avisa_si_no_es_primario "$2"
    echo "Aislando $2 durante 90 s (la regla se quita sola)…"
    en "$2" "sudo systemd-run --unit=kaizen-particion-prueba --on-active=1 sh -c \
      'iptables -I INPUT 1 -i wg0 -j DROP; iptables -I OUTPUT 1 -o wg0 -j DROP; sleep 90; \
       iptables -D INPUT -i wg0 -j DROP; iptables -D OUTPUT -o wg0 -j DROP'"
    ;;
  congelar)
    valida_nodo "${2:-}"
    [[ "$2" != "nodo1" ]] || { echo "nodo1 tiene el contador: congelarlo invalida la prueba. Cambia antes el primario." >&2; exit 1; }
    avisa_si_no_es_primario "$2"
    echo "Congelando Patroni y PostgreSQL en $2 (red de seguridad: se descongela a los 90 s si el watchdog no actúa)…"
    en "$2" "sudo systemd-run --unit=kaizen-descongelar-prueba --on-active=90 systemctl kill -s SIGCONT patroni \
      && sudo systemctl kill -s SIGSTOP patroni"
    ;;
  verificar)
    valida_etiqueta "${2:-}"
    lider=$(primario)
    echo "Primario: $lider"
    en "$lider" "sudo -u postgres psql -d kaizen -XAtc \"select 'filas en la base: ' || count(*) || ' · distintas: ' || count(distinct recurso) from kaizen.bitacora_auditoria where recurso like '$2:%'\""
    en "$lider" 'sudo kpatronictl list'
    echo "Compara 'filas en la base' con 'confirmados' del contador: deben ser iguales."
    ;;
  limpiar)
    valida_nodo "${2:-}"
    en "$2" 'sudo sh -c "while iptables -D INPUT -i wg0 -j DROP 2>/dev/null; do :; done; \
      while iptables -D OUTPUT -o wg0 -j DROP 2>/dev/null; do :; done; \
      systemctl kill -s SIGCONT patroni 2>/dev/null || true; \
      systemctl stop kaizen-particion-prueba.timer kaizen-descongelar-prueba.timer 2>/dev/null || true"; echo "Listo."'
    ;;
  *)
    uso
    ;;
esac
