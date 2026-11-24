# Monitoreo: Prometheus, Grafana, Blackbox y exportadores

## Qué hace
Recoge métricas de las 4 máquinas y de todos los servicios, las muestra en un tablero y evalúa reglas de alerta.
Todo corre en el HomeLab, en contenedores, y solo escucha en `127.0.0.1` (se entra por túnel SSH).

## Componentes

| Componente | Dónde | Puerto | Qué mide |
|---|---|---|---|
| Prometheus v3.16.0 | HomeLab (contenedor) | 127.0.0.1:9091 (el 9090 lo usa Cockpit) | Recolecta todo; 15 días de retención |
| Grafana 13.0.2 | HomeLab (contenedor) | 127.0.0.1:3000, HTTPS con el certificado `homelab` | Tablero **"Kaizen · Clúster y HomeLab"** (12 paneles), cargado por *provisioning* |
| node_exporter | nodo1-3 (nativo, 9100, solo para el HomeLab) y HomeLab (contenedor) | 9100 | CPU, RAM, disco, red |
| postgres_exporter v0.21.1 | HomeLab, uno por instancia | 127.0.0.1:9187-9190 | Conexiones, tamaño de la base, retraso de replicación (nodo1-3 y plan B). Usuario `kaizen_monitor`, TLS `verify-full` |
| Métricas de Patroni y etcd | Directo de cada nodo | 8008 y 2379 | Rol de cada nodo, réplica síncrona, líder de etcd. Con el certificado `homelab-cliente` (mTLS) |
| Blackbox v0.29.1 | HomeLab (contenedor) | 127.0.0.1:9115 | Sondas TLS a cada servicio y al HTTPS público; vencimiento de certificados |

**24 objetivos** en total.

## Alertas (10)

| Alerta | Se dispara cuando |
|---|---|
| `NodoCaido` | Una máquina deja de responder |
| `PatroniSinLider` | El clúster no tiene primario |
| `PatroniSinReplicaSincrona` | No hay réplica síncrona (las escrituras se detienen) |
| `EtcdSinLider` | etcd perdió el líder o el quórum |
| `RetrasoDeReplicacion` | Una réplica se atrasa |
| `PlanBAtrasado` | La réplica del plan B se atrasa |
| `DiscoCasiLleno` | Poco espacio en disco |
| `ConexionesAltas` | Muchas conexiones a PostgreSQL |
| `CertificadoPorVencer` | Un certificado vence en menos de 21 días |
| `SondaTLSFallida` | Un servicio no responde con TLS válido |

Las alertas se ven en Prometheus y en Grafana. **No se envían** por correo ni a otro canal (no hay Alertmanager).
Cuando el HomeLab está apagado, no hay monitoreo.

## Archivos (HomeLab)

| Archivo | Contenido |
|---|---|
| `/opt/kaizen-homelab/config/prometheus/prometheus.yml` | Objetivos |
| `/opt/kaizen-homelab/config/prometheus/reglas.yml` | Alertas |
| `/opt/kaizen-homelab/config/blackbox/blackbox.yml` | Sondas |
| `/opt/kaizen-homelab/config/grafana/` | Fuente de datos y tablero |

Cuando exista la API, se agrega como objetivo en `prometheus.yml`.

## Cómo comprobarlo

```bash
ssh -N -L 3000:127.0.0.1:3000 -L 9091:127.0.0.1:9091 <homelab>
# http://localhost:9091/targets   -> 24/24 "UP"
# http://localhost:9091/alerts    -> sin alertas activas
# https://localhost:3000          -> tablero "Kaizen · Clúster y HomeLab"
```
