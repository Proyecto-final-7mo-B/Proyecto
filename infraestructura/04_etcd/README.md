# etcd

## Qué hace
Guarda el estado del clúster de Patroni: quién es el líder de PostgreSQL, la configuración común y los miembros.
Con 3 miembros tolera la caída de 1 (quórum de 2). Si se pierde el quórum, Patroni deja de promover primarios:
prefiere no escribir a arriesgarse a tener dos (postura CP).

## Cómo está desplegado

| | |
|---|---|
| Versión | etcd 3.4 (paquete de Ubuntu 24.04), servicio `etcd` de systemd |
| Miembros | nodo1, nodo2 y nodo3 |
| Puertos | 2379 (clientes) en `10.10.0.N` y `127.0.0.1`; 2380 (entre miembros) en `10.10.0.N` |
| Seguridad | TLS 1.3 y **certificado de cliente obligatorio** en los dos puertos (`ETCD_CLIENT_CERT_AUTH` y `ETCD_PEER_CLIENT_CERT_AUTH`) |
| Datos | `/var/lib/etcd/default` |
| Configuración | `/etc/default/etcd` |
| Certificados | `/etc/etcd/pki/` (`node.crt`/`node.key` del miembro; `client.crt`/`client.key` para `etcdctl`) |

Configuración principal (nodo N):

```
ETCD_NAME="nodoN"
ETCD_LISTEN_PEER_URLS="https://10.10.0.N:2380"
ETCD_LISTEN_CLIENT_URLS="https://10.10.0.N:2379,https://127.0.0.1:2379"
ETCD_INITIAL_CLUSTER="nodo1=https://10.10.0.1:2380,nodo2=https://10.10.0.2:2380,nodo3=https://10.10.0.3:2380"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_PEER_CLIENT_CERT_AUTH="true"
```

Quién lo usa: Patroni en cada nodo (certificado `patroni-nodoN`) y Prometheus en el HomeLab (`homelab-cliente`).

## Claves que escribe Patroni (namespace `/kaizen/`)

| Clave | Contenido |
|---|---|
| `/kaizen/kaizen/leader` | Líder actual; expira si no se renueva en 30 s |
| `/kaizen/kaizen/sync` | Réplica síncrona actual |
| `/kaizen/kaizen/config` | Configuración dinámica del clúster |
| `/kaizen/kaizen/members/nodoN` | Estado de cada nodo |

**No se editan a mano:** todo cambio se hace con `kpatronictl`.

## Cómo comprobarlo

```bash
E="sudo etcdctl --endpoints=https://10.10.0.1:2379,https://10.10.0.2:2379,https://10.10.0.3:2379 \
   --cacert=/etc/etcd/pki/ca.crt --cert=/etc/etcd/pki/client.crt --key=/etc/etcd/pki/client.key"
$E endpoint health -w table      # los 3 en true
$E endpoint status -w table      # un solo líder
$E member list -w table
```
