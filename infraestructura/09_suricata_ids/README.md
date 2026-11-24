# Detección de intrusos: Suricata

## Qué hace
Inspecciona el tráfico de nodo1, la única VM expuesta a Internet, y genera alertas ante patrones de ataque conocidos
y ante tráfico que no debería existir en la red interna.

## Cómo está desplegado

| | |
|---|---|
| Equipo | nodo1 |
| Versión | Suricata 7.0.3 (modo IDS: detecta y alerta, no bloquea) |
| Interfaces | `eth0` (Internet) y `wg0` (red privada) |
| Recursos | Perfil de detección bajo para cuidar la RAM (~540 MB); límite de systemd de 1.2 GB |
| Reglas | **ET Open** (53,532), actualizadas a diario a las 04:30 UTC con `suricata-update.timer` |
| Reglas propias | `/etc/suricata/rules/kaizen.rules`: **sid 9000001**, intento de llegar a puertos administrativos (2379, 2380, 5432, 8008) desde fuera de la malla; **sid 9000002**, conexión a PostgreSQL sin TLS |
| Ruido suprimido | sid 2260001, solo para tráfico interno `10.10.0.0/24` (lo disparaban las sondas TLS del monitoreo), en `/etc/suricata/threshold.config` |
| Configuración | `/etc/suricata/suricata.yaml` (el original quedó en `suricata.yaml.orig`) |
| Alertas | `/var/log/suricata/fast.log` y `eve.json`; además viajan por syslog al HomeLab ([11_bitacoras](../11_bitacoras/)) |

Lynis marca "interfaz en modo promiscuo" en nodo1: es Suricata capturando, a propósito.

## Cómo comprobarlo

```bash
systemctl status suricata
sudo suricata -T -c /etc/suricata/suricata.yaml        # prueba la configuración
sudo tail -f /var/log/suricata/fast.log                # alertas en vivo
sudo jq 'select(.event_type=="alert") | .alert.signature' /var/log/suricata/eve.json | sort | uniq -c | sort -rn | head
```

Prueba controlada: un escaneo de puertos desde fuera genera alertas ET SCAN en `fast.log`, y las mismas aparecen en
la bitácora de nodo1 dentro del HomeLab.
