# Red privada: WireGuard

## Qué hace
Une los 5 equipos en una red privada cifrada, `10.10.0.0/24`. Todo el tráfico interno viaja por ella: etcd,
replicación de PostgreSQL, monitoreo, respaldos, bitácoras y SSH. Desde Internet solo se ve el puerto UDP de WireGuard
(y 80/443 en nodo1).

## Cómo está desplegada

| Equipo | Interfaz | IP | Puerto | Peers |
|---|---|---|---|---|
| nodo1, nodo2, nodo3 | `wg0` | 10.10.0.1 / .2 / .3 | 51820/udp | Las otras 2 VMs (por IP privada de Azure), la laptop y el HomeLab |
| Laptop | `wg0` | 10.10.0.4 | — | Las 3 VMs |
| HomeLab | `wg-kaizen` | 10.10.0.10 | 51821/udp | Las 3 VMs (por su IP pública), con `PersistentKeepalive = 25` |

- **Cifrado:** ChaCha20-Poly1305 (WireGuard). Cada equipo generó su propia llave; solo se intercambiaron las públicas.
- **HomeLab detrás de NAT:** el HomeLab inicia el túnel hacia las VMs y lo mantiene vivo cada 25s.
- **La laptop no es peer del HomeLab.** Para administrarlo se usa otra vía, fuera de Kaizen.
- En el HomeLab la interfaz de Kaizen es **independiente** de cualquier otra VPN del servidor y vive en su propia zona
  de firewalld (ver [02_firewall](../02_firewall/)).

## Archivos

| Equipo | Archivo |
|---|---|
| VMs y laptop | `/etc/wireguard/wg0.conf` y `/etc/wireguard/private.key` (carpeta 700 root) |
| HomeLab | `/etc/wireguard/wg-kaizen.conf` y `/etc/wireguard/wg-kaizen.key` (600 root) |

Arranque automático: `wg-quick@wg0` (VMs) y `wg-quick@wg-kaizen` (HomeLab) habilitados en systemd. En la laptop se
levanta a mano: `sudo systemctl start wg-quick@wg0`.

## Cómo comprobarlo

```bash
sudo wg show                           # cada peer con "latest handshake" de hace menos de 2-3 minutos
ip -br addr show wg0                   # la IP 10.10.0.x
ping -c1 10.10.0.2                     # alcanzar a otro nodo
```

Evidencia: se capturó tráfico con tcpdump y no hay datos en claro de etcd ni de la replicación.
