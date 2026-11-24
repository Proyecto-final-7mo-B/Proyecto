# Cuentas y dónde vive cada secreto

Regla general: **cada secreto vive en el equipo que lo usa**, con permisos solo para su dueño. Las contraseñas de las
cuentas de servicio se generaron en el equipo que las usa y a PostgreSQL solo llegó su verificador SCRAM-SHA-256.
Este documento dice **dónde** están; los valores nunca se escriben en el repositorio.

## Acceso a los equipos

| Cuenta | Dónde | Cómo entra |
|---|---|---|
| `azureuser` | nodo1-3 | SSH con llave, solo desde la laptop (10.10.0.4) por WireGuard; `sudo` sin contraseña |
| `root` | nodo1-3 | No entra por SSH |
| Usuario de administración | HomeLab | SSH con llave; `sudo` **con** contraseña |

## PostgreSQL

| Rol | Desde dónde | Dónde está la contraseña |
|---|---|---|
| `postgres`, `replicator`, `rewind` | Patroni en cada nodo | `/etc/patroni_env.conf` (600 root) en nodo1-3 |
| `kaizen_api` | nodo1 | nodo1 `/etc/kaizen/api.env` (`KAIZEN_DB_PASSWORD`) |
| `kaizen_tareas` | nodo1 | nodo1 `/etc/kaizen/tareas.env` (`KAIZEN_TAREAS_DB_PASSWORD`) |
| `kaizen_etl` | HomeLab | HomeLab `/etc/kaizen-homelab/secretos/` |
| `kaizen_monitor` | HomeLab | HomeLab `/etc/kaizen-homelab/secretos/` (copia en `secretos/monitoreo/`) |
| `planb_replica` | HomeLab | HomeLab `/etc/kaizen-homelab/secretos/` y `tls/pg-planb/` |

## Secretos de la API (nodo1)

`/etc/kaizen/api.env` (600 root) — auditd vigila la carpeta `/etc/kaizen/`:

| Variable | Qué es | Si se pierde |
|---|---|---|
| `KAIZEN_DB_PASSWORD` | Contraseña de `kaizen_api` | Se asigna otra |
| `KAIZEN_JWT_LLAVE_PRIVADA`, `KAIZEN_JWT_KID` | Semilla Ed25519 (base64) para firmar los JWT, y su identificador | Se genera otra; todos vuelven a iniciar sesión |
| `KAIZEN_EMAIL_HMAC_KEY` | Llave del HMAC del correo (directorio de usuarios) | **Nadie podría iniciar sesión**: no se cambia nunca |
| `KAIZEN_CAPSULA_KEY_V1` | Llave AES-256-GCM de las cápsulas | **Los mensajes no se podrían descifrar** |
| `KAIZEN_MONGO_API_PASSWORD` | Usuario `kaizen_api` de MongoDB (solo lectura) | Se copia otra vez del HomeLab |
| `KAIZEN_URL_RESTABLECER` | Página del enlace de recuperación de contraseña | — |
| `KAIZEN_SMTP_*` | Cuenta de correo para enviar la recuperación | Pendiente de crear |

Además: `/etc/kaizen/ca.crt` (público), para verificar PostgreSQL y MongoDB.

## Servicios del clúster

| Servicio | Credencial | Dónde |
|---|---|---|
| API REST de Patroni | Usuario + certificado de cliente | `/etc/patroni_env.conf` y `/etc/patroni/pki/client.key` |
| etcd | Solo certificados | `/etc/etcd/pki/*.key` |
| PostgreSQL TLS | Certificado `nodoN` | `/etc/patroni/pki/server.key` |
| pgBackRest | Llave SFTP y contraseña de cifrado del repositorio | `/var/lib/postgresql/.ssh/id_pgbackrest`; `/etc/pgbackrest/conf.d/cifrado.conf` (640 root:postgres) |
| Nginx | Certificado de Let's Encrypt | `/etc/letsencrypt/live/…/privkey.pem` |
| WireGuard | Llave de cada equipo | `/etc/wireguard/` (700 root) |

## HomeLab

| Servicio | Credencial | Dónde |
|---|---|---|
| MongoDB | `admin`, `kaizen_etl`, `kaizen_api` | `/etc/kaizen-homelab/secretos/` y `secretos/mongo/` |
| Grafana | `admin` | `/etc/kaizen-homelab/secretos/grafana/` |
| Prometheus y Blackbox | Certificado `homelab-cliente` | `/etc/kaizen-homelab/tls/monitoreo/` |
| Repositorio de respaldos (SFTP) | Usuario `pgbackrest`, sin contraseña, una llave pública por nodo | `/etc/ssh/pgbackrest_keys/authorized_keys` |
| Firma de respaldos | Llave Ed25519 | `/etc/kaizen-homelab/firma/` |
| Certificados | `homelab`, `homelab-cliente` | `/etc/kaizen-homelab/pki/` y copias por servicio en `tls/<servicio>/` |

## Copias en la laptop de administración (carpeta `ssh/`)

| Qué | Por qué |
|---|---|
| Llave de la CA, cifrada (+ copia en USB) | Es la única forma de firmar certificados |
| Contraseña de cifrado del repositorio de respaldos | Restaurar si se pierden las 3 VMs |
| Llave pública de firma de respaldos | Verificar respaldos fuera del HomeLab |
| Llaves SSH de las VMs | Acceso |
| `kaizen_api/` (`api.env`, `tareas.env`) | Copia de los secretos de la API: sin las llaves de HMAC y de cápsulas se pierde el acceso o los mensajes |
