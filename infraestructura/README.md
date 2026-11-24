# Infraestructura de Kaizen

Cómo está desplegada la infraestructura de Kaizen. Cada carpeta explica una tecnología: qué hace, dónde corre,
cómo está configurada y cómo se comprueba que funciona.



## Mapa general

```
                              Internet
                                 │  443 / 80 (solo nodo1)
     ┌──────────────────────── Azure · una región ─────────────────────────┐
     │  nodo1                       nodo2                   nodo3             
     │  Nginx (HTTPS) · Suricata   PostgreSQL 16            PostgreSQL 16  │
     │  PostgreSQL 16 · Patroni    Patroni · etcd           Patroni · etcd    │
     │  etcd · API (por desplegar)                                            │
     └───────────▲─────────────────────────▲─────────────────────▲───────────┘
                 └────────            WireGuard    ───────────────┘
                 │                                               │
   Laptop de administración                          HomeLab / Nodo L 
   (solo SSH)                                     Podman: MongoDB, Prometheus, Grafana,
                                                  réplica del plan B · respaldos · bitácoras
```

| Equipo | Sistema | Recursos | Qué corre |
|---|---|---|---|
| nodo1 | Ubuntu 24.04 (Azure) | 2 vCPU, 3.8 GB RAM, 29 GB | WireGuard, etcd, Patroni + PostgreSQL 16, Nginx, Suricata. Aquí correrán la API y sus tareas programadas |
| nodo2 | Ubuntu 24.04 (Azure) | 2 vCPU, 3.8 GB RAM | WireGuard, etcd, Patroni + PostgreSQL 16 |
| nodo3 | Ubuntu 24.04 (Azure) | 2 vCPU, 3.8 GB RAM | WireGuard, etcd, Patroni + PostgreSQL 16 |
| HomeLab | Fedora 44, SELinux Enforcing | Pentium J3710 (sin AVX), 3.7 GB, 929 GB | WireGuard, Podman (MongoDB, monitoreo, plan B), repositorio de respaldos, receptor de bitácoras |
| Laptop | Fedora 44 | — | Solo administración por SSH; guarda la CA cifrada |

**Primario de PostgreSQL:** cambia con los failovers. Al 24-nov-2026 es **nodo2**; se decidió que no esté en nodo1,
donde corre la API. Para saber cuál es: `sudo kpatronictl list` en cualquier nodo.

**El HomeLab** se enciende durante el desarrollo, las pruebas y la entrega. Mientras está apagado, los respaldos y
el archivado de WAL esperan en el primario y se ponen al día solos al encenderlo.

## Contenido

| Carpeta | Tema |
|---|---|
| [01_red_wireguard](01_red_wireguard/) | Red privada cifrada entre los 5 equipos |
| [02_firewall](02_firewall/) | NSG de Azure, ufw en las VMs y firewalld en el HomeLab |
| [03_pki_certificados](03_pki_certificados/) | CA interna y certificados de cada servicio |
| [04_etcd](04_etcd/) | Almacén de consenso que usa Patroni |
| [05_postgresql_patroni](05_postgresql_patroni/) | Clúster de PostgreSQL 16 con failover automático |
| [06_base_de_datos](06_base_de_datos/) | Esquema `kaizen`, fragmentación, roles y Row-Level Security |
| [07_respaldos_pgbackrest](07_respaldos_pgbackrest/) | Respaldos cifrados, WAL continuo y firma |
| [08_nginx_https](08_nginx_https/) | Entrada pública HTTPS y límites de peticiones |
| [09_suricata_ids](09_suricata_ids/) | Detección de intrusos en nodo1 |
| [10_endurecimiento](10_endurecimiento/) | SSH, kernel, auditd, AIDE y Fail2ban |
| [11_bitacoras](11_bitacoras/) | Bitácoras centralizadas en el HomeLab |
| [12_homelab](12_homelab/) | Servidor local con Podman |
| [13_mongodb](13_mongodb/) | Base analítica |
| [14_monitoreo](14_monitoreo/) | Prometheus, Grafana, Blackbox y exportadores |
| [15_plan_b](15_plan_b/) | Réplica en caliente fuera de la nube |
| [16_cuentas_y_secretos](16_cuentas_y_secretos/) | Qué cuenta usa cada servicio y dónde vive su secreto |

## Acceso rápido

```bash
sudo systemctl start wg-quick@wg0      # en la laptop: levantar la red de Kaizen
ssh nodo1-proyecto                     # o nodo2-proyecto / nodo3-proyecto (usuario azureuser)
sudo kpatronictl list                  # estado del clúster
```
