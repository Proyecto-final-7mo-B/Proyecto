# HomeLab (Nodo L)

## Qué es
Un servidor físico en casa que se une a la red de Kaizen por WireGuard. Concentra lo que no conviene tener en las VMs
de la nube: la base analítica, el monitoreo, una copia en caliente de la base (plan B), los respaldos cifrados y las
bitácoras. Se enciende durante el desarrollo, las pruebas y la entrega.

| | |
|---|---|
| Hardware | Pentium J3710 (**sin AVX**), 3.7 GB RAM, 929 GB de disco |
| Sistema | Fedora 44, **SELinux en modo Enforcing**, firewalld |
| Red de Kaizen | `wg-kaizen`, 10.10.0.10 (ver [01_red_wireguard](../01_red_wireguard/)) |
| Contenedores | **Podman** + podman-compose 1.6 (la nube es nativa; el HomeLab usa contenedores) |

## Servicios en contenedores
Archivo de composición: `/opt/kaizen-homelab/compose.yaml`.

| Contenedor | Imagen | Escucha en | Detalle |
|---|---|---|---|
| kaizen-mongodb | `mongo:4.4.30` | 127.0.0.1 y 10.10.0.10 :27017 | [13_mongodb](../13_mongodb/) |
| kaizen-pg-planb | `postgres:16.16` | 127.0.0.1:5433 | [15_plan_b](../15_plan_b/) |
| kaizen-prometheus | `prometheus:v3.16.0` | 127.0.0.1:9091 | [14_monitoreo](../14_monitoreo/) |
| kaizen-grafana | `grafana-oss:13.0.2` | 127.0.0.1:3000 (HTTPS) | |
| kaizen-blackbox | `blackbox-exporter:v0.29.1` | 127.0.0.1:9115 | |
| kaizen-node-exporter | `node-exporter:v1.13.1` | 127.0.0.1:9100 | |
| kaizen-pgexp-nodo1/2/3/planb | `postgres-exporter:v0.21.1` | 127.0.0.1:9187-9190 | |

**Seguridad de los contenedores:**
- Cada servicio corre con su **propio UID** sin privilegios (41000 MongoDB, 41001 plan B, 41002 monitoreo, 41003 Grafana).
- `no-new-privileges`, versiones fijas (nunca `:latest`) y límite de memoria por contenedor.
- Volúmenes con etiqueta SELinux (`:Z`/`:z`).
- Secretos en `/etc/kaizen-homelab/secretos/` (700 root): cada servicio monta solo los suyos, como archivo, nunca
  como variable de entorno.
- Certificados por servicio en `/etc/kaizen-homelab/tls/<servicio>/`.
- Consumo total: ~1 GB de RAM.

## Servicios fuera de los contenedores
- Receptor de bitácoras (rsyslog 20514) → [11_bitacoras](../11_bitacoras/)
- Repositorio de pgBackRest por SFTP, firma horaria de respaldos y prueba de restauración → [07_respaldos_pgbackrest](../07_respaldos_pgbackrest/)

## Arranque automático
`/etc/systemd/system/kaizen-homelab.service` (habilitado) espera a `wg-quick@wg-kaizen` y a que exista la IP
10.10.0.10 (MongoDB se enlaza a ella), y luego ejecuta `podman-compose up -d`. Comprobado con reinicios reales:
todo levanta solo. Grafana tarda unos 3-5 minutos en responder en este CPU.

## Acceso desde la laptop
Todo escucha en `127.0.0.1`; se entra con túneles SSH al HomeLab:

```bash
ssh -N -L 3000:127.0.0.1:3000 -L 9091:127.0.0.1:9091 -L 27017:127.0.0.1:27017 -L 15433:127.0.0.1:5433 <homelab>
# Grafana https://localhost:3000 · Prometheus http://localhost:9091 · MongoDB localhost:27017 (TLS) · plan B localhost:15433
```

## Cómo comprobarlo

```bash
systemctl status kaizen-homelab wg-quick@wg-kaizen
sudo podman ps --format "table {{.Names}}\t{{.Status}}"      # 10 contenedores "Up"
sudo wg show wg-kaizen                                        # handshake con los 3 nodos
```
