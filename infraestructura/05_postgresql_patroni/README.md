# Clúster de PostgreSQL 16 con Patroni

## Qué hace
Tres copias de la base de datos: un **primario** que acepta escrituras y dos **réplicas**. Patroni vigila cada nodo y,
si el primario cae, promueve una réplica en ~25 s sin intervención. Se eligió la postura **CP**: ante una partición
se prefiere dejar de escribir a perder datos confirmados.

## Cómo está desplegado

| | |
|---|---|
| Versiones | PostgreSQL 16.15 y Patroni 3.2.2 (paquetes de Ubuntu 24.04) |
| Nodos | nodo1, nodo2 y nodo3; servicio `patroni` (PostgreSQL lo arranca Patroni) |
| Clúster | scope `kaizen`, namespace `/kaizen/` en etcd |
| Roles al 24-nov-2026 | Primario **nodo2** · réplica síncrona nodo3 · réplica asíncrona nodo1 (timeline 7) |
| Datos | `/var/lib/postgresql/16/main`, con *data checksums*, UTF8 y `C.UTF-8` |
| Escucha | `10.10.0.N:5432` y `127.0.0.1:5432` |
| Configuración local | `/etc/patroni/config.yml` (incluye `pg_hba`) |
| Configuración común | Vive en etcd; se ve con `sudo kpatronictl show-config` |
| Contraseñas de Patroni | `/etc/patroni_env.conf` (600 root), como variables `PATRONI_*` |

### Sincronía (postura CP)

```yaml
synchronous_mode: true
synchronous_mode_strict: true      # sin réplica síncrona, NO se aceptan escrituras
synchronous_node_count: 1
synchronous_commit: "on"
ttl: 30                            # el líder debe renovarse cada 30 s en etcd
loop_wait: 10
maximum_lag_on_failover: 1048576   # una réplica atrasada más de 1 MB no se promueve
```

Cada `COMMIT` espera a que la réplica síncrona lo tenga: un failover nunca pierde una escritura confirmada.

### Parámetros principales de PostgreSQL
`shared_buffers 1GB`, `effective_cache_size 2560MB`, `work_mem 8MB`, `max_connections 100`, `wal_level replica`,
`max_wal_size 2GB`, `wal_keep_size 512MB`, `timezone UTC`, `password_encryption scram-sha-256`,
`shared_preload_libraries pgaudit` (`pgaudit.log = role, ddl`), `log_connections` y `log_disconnections` activos.

### Cifrado y acceso
- **Solo TLS 1.3** (`ssl_min_protocol_version`), con el certificado `nodoN` de la CA interna.
- La replicación y `pg_rewind` exigen **certificado de la CA y contraseña SCRAM**.
- El superusuario `postgres` solo entra por el socket local (`sudo -u postgres psql`).
- `pg_hba` (en `/etc/patroni/config.yml`), en resumen:

| Tipo | Base | Usuario | Origen | Método |
|---|---|---|---|---|
| hostssl | replication | `replicator` | 10.10.0.1-3 y 127.0.0.1 | SCRAM + certificado |
| hostssl | postgres | `rewind` | 10.10.0.1-3 | SCRAM + certificado |
| hostssl | kaizen | `kaizen_api` | 10.10.0.1 | SCRAM |
| hostssl | kaizen | `kaizen_tareas` | 10.10.0.1 | SCRAM |
| hostssl | kaizen | `kaizen_etl`, `kaizen_monitor` | 10.10.0.10 | SCRAM |
| hostssl | replication | `planb_replica` | 10.10.0.10 | SCRAM + certificado |
| — | todo lo demás | | | reject |

### API REST de Patroni (8008)
HTTPS con **certificado de cliente obligatorio** (`verify_client: required`). Las operaciones que cambian algo
(switchover, restart, editar la configuración) piden además usuario y contraseña. Se usa a través de `kpatronictl`.

### Watchdog
Módulo `softdog` cargado al arrancar (`/etc/modules-load.d/kaizen-softdog.conf`) y `watchdog: mode: automatic`.
Patroni lo arma solo en el primario: si Patroni se cuelga siendo primario, el núcleo reinicia la VM antes de que
otro nodo sea elegido. Así nunca hay dos primarios.

### Cómo se conecta un cliente (la API)
Le da a libpq los 3 nodos y libpq se queda con el que acepta escrituras. No necesita saber quién es el primario:

```
host=10.10.0.1,10.10.0.2,10.10.0.3 port=5432,5432,5432 dbname=kaizen user=kaizen_api
target_session_attrs=read-write sslmode=verify-full sslrootcert=/etc/kaizen/ca.crt connect_timeout=5
```

## Administración

`kpatronictl` (`/usr/local/sbin/kpatronictl`) carga las credenciales de `/etc/patroni_env.conf` y llama a `patronictl`:

```bash
sudo kpatronictl list                     # roles, timeline y retraso
sudo kpatronictl history                  # failovers y switchovers
sudo kpatronictl switchover kaizen --leader nodo2 --candidate nodo3    # cambio controlado
sudo -u postgres psql -d kaizen           # en el primario, para escribir
```

## Pruebas hechas

| Prueba | Resultado |
|---|---|
| Caída de Patroni en el primario | 26.7 s sin escrituras; 0 escrituras confirmadas perdidas |
| Primario congelado | El watchdog reinició la VM; nunca hubo dos primarios |
| Partición de red del primario | 21.7 s; 0 escrituras confirmadas perdidas |
| Switchover nodo1 → nodo2 (23-nov) | Réplicas en streaming en < 1 min; la API encontró sola al nuevo primario |
