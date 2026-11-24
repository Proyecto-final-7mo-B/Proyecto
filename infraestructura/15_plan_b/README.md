# Plan B: réplica en caliente en el HomeLab

## Qué hace
Una cuarta copia de la base, **fuera de Azure**, que recibe los cambios del primario en tiempo real. Si se perdiera la
región de Azure completa, los datos siguen en casa con una pérdida de segundos, y se puede promover para atender.

## Cómo está desplegado

| | |
|---|---|
| Dónde | HomeLab, contenedor `kaizen-pg-planb` (`postgres:16.16`), UID 41001, límite de 512 MB |
| Escucha | Solo `127.0.0.1:5433` |
| Tipo | Réplica asíncrona por *streaming*, **fuera** del clúster de Patroni (no participa en las elecciones) |
| Rol | `planb_replica` (LOGIN REPLICATION, máximo 2 conexiones). Es propio: el HomeLab no conoce la contraseña de `replicator` y este acceso se puede revocar solo |
| Seguridad | TLS `verify-full` + **certificado de cliente** (`homelab-cliente`) + contraseña SCRAM |
| Sigue al primario | Su conexión lista los 3 nodos y elige el que acepta escrituras, así que tras un failover se reconecta sola al primario nuevo |

```
primary_conninfo = 'host=10.10.0.1,10.10.0.2,10.10.0.3 port=5432 user=planb_replica
                    target_session_attrs=read-write sslmode=verify-full sslrootcert=… sslcert=… sslkey=…
                    application_name=planb_homelab'
```

Configuración en el HomeLab: `/opt/kaizen-homelab/config/pg-planb/` (`postgresql.conf`, `pg_hba.conf`); contraseña y
certificados en `/etc/kaizen-homelab/tls/pg-planb/`.

## Cómo se usaría (manual)

```bash
# 1. Confirmar que el clúster de la nube está perdido (no promover si sigue vivo: habría dos primarios)
# 2. Promover la réplica
sudo podman exec kaizen-pg-planb pg_ctl promote -D /var/lib/postgresql/data
sudo podman exec kaizen-pg-planb psql -h /var/run/postgresql -p 5433 -U postgres -c 'select pg_is_in_recovery()'   # f
```

Hoy el plan B conserva los datos. Para atender usuarios desde casa falta correr la API en el HomeLab, cosa que se hará
cuando exista la API.

## Cómo comprobarlo

```bash
# en el primario: debe aparecer planb_homelab en streaming
sudo -u postgres psql -c "select application_name, state, sync_state, replay_lag from pg_stat_replication"
```
La alerta `PlanBAtrasado` de Prometheus avisa si se atrasa.
