# Firewall: NSG de Azure, ufw y firewalld

## Qué hace
Tres capas con **denegación por omisión**: solo pasa lo que un servicio necesita y solo desde quien lo necesita.

## 1. NSG de Azure (antes de llegar a la VM)

| VM | Entradas permitidas desde Internet |
|---|---|
| nodo1 | 80/tcp, 443/tcp (Nginx) y 51820/udp (WireGuard) |
| nodo2, nodo3 | Solo 51820/udp (WireGuard)|

SSH (22) **no** está abierto en el NSG: solo se entra por WireGuard.

## 2. ufw en nodo1, nodo2 y nodo3

`ufw default deny incoming`, `ufw default allow outgoing`.

| Puerto | Origen permitido | Para qué |
|---|---|---|
| 51820/udp | Cualquiera | WireGuard (autenticado por llave) |
| 22/tcp | Solo 10.10.0.4 (laptop), por `wg0` | SSH |
| 2379, 2380/tcp | 10.10.0.1-3 | etcd (clientes y miembros) |
| 5432/tcp | 10.10.0.1-3 | PostgreSQL (replicación y API) |
| 8008/tcp | 10.10.0.1-3 | API REST de Patroni |
| 2379, 5432, 8008, 9100/tcp | 10.10.0.10 (HomeLab) | Monitoreo, ETL, plan B y node_exporter |
| 80, 443/tcp | Cualquiera (solo nodo1) | HTTPS público |

Las reglas de base de datos y Patroni van además **amarradas a la interfaz `wg0`**: aunque alguien abriera el NSG,
no responderían por la IP pública.

## 3. firewalld en el HomeLab

| Zona | Interfaces | Qué permite |
|---|---|---|
| `kaizen` | `wg-kaizen` | 27017/tcp solo desde 10.10.0.1 (la API lee MongoDB); 20514/tcp (bitácoras) y 22/tcp (SFTP de respaldos) desde 10.10.0.1-3. Sin reenvío ni masquerade |
| Zona de la red de casa | Red local y otras VPN del servidor | Ajena a Kaizen |

No existe ninguna política entre las zonas: el HomeLab **no** puede servir de puente entre la red de Kaizen y la de casa.

## Cómo comprobarlo

```bash
sudo ufw status numbered                                     # en cada VM
sudo firewall-cmd --zone=kaizen --list-all                   # en el HomeLab
nmap -Pn proyecto-kaizen.northcentralus.cloudapp.azure.com   # desde fuera: solo 80 y 443
```

Resultado del escaneo externo (nmap): solo 80/443 abiertos en nodo1; nada en nodo2 ni nodo3.
