# MongoDB (base analítica)

## Qué hace
Guarda los resúmenes que calcula el proceso ETL a partir de PostgreSQL. De ahí salen el Laboratorio personal (F2) y
los indicadores I1-I6 del panel de administración. **No guarda datos personales:** cada usuario aparece con un
seudónimo `usuario_sdn` (HMAC de su id), sin nombre, correo ni IP.

## Cómo está desplegado

| | |
|---|---|
| Dónde | HomeLab, contenedor `kaizen-mongodb` |
| Versión | MongoDB **4.4.30**. Las versiones 5.0+ exigen un CPU con AVX y el del HomeLab no lo tiene |
| Escucha | 127.0.0.1 y 10.10.0.10, puerto 27017 |
| Acceso por red | Solo desde nodo1 (la API), por regla de firewalld en la zona `kaizen` |
| Cifrado | **TLS obligatorio** con el certificado `homelab` de la CA interna; el cliente verifica con `ca.crt` |
| Autenticación | Usuario y contraseña (SCRAM) |
| Proceso | UID 41000, sin privilegios; límite de 600 MB de RAM (caché de WiredTiger de 0.25 GB) |
| Datos | `/var/lib/kaizen-homelab/mongo` (volumen con etiqueta SELinux) |
| TLS dentro del contenedor | `/etc/kaizen-tls/` (montado de `/etc/kaizen-homelab/tls/mongo/`); TLS 1.0 y 1.1 deshabilitados |

## Base `kaizen_analitica`

| Colección | Contenido | Índice único |
|---|---|---|
| `resumen_diario` | Un documento por usuario y día: cumplimiento, hábitos (categoría, nivel, racha, hora) y señales | `(usuario_sdn, fecha)` |
| `perspectivas_semanales` | Resultado del Laboratorio por usuario y semana ISO | `(usuario_sdn, semana)` |
| `metricas_globales` | Agregados por región y día | `(fecha, region)` |

Hoy está vacía: la llena el ETL cuando exista. El ETL creará además dos colecciones: `indicadores` (series I1-I6 listas
para el panel, porque la API no puede leer datos de todos los usuarios por la RLS) y `etl_control` (marca de la última
extracción). El detalle de cada documento está en el documento del backend "MongoDB analítica y ETL".

## Por qué no está replicada
Los requisitos piden replicación solo de la base relacional, y PostgreSQL ya la tiene (3 nodos, failover, plan B y
respaldos). MongoDB guarda **datos derivados**: si se pierden, una corrida del ETL los recalcula desde PostgreSQL. Con el
HomeLab apagado la app sigue funcionando; solo el Laboratorio y los indicadores responden "analítica no disponible".

## Usuarios

| Usuario | Permiso | Quién lo usa | Dónde vive la contraseña |
|---|---|---|---|
| `admin` | Administrador | Solo para administrar | HomeLab `/etc/kaizen-homelab/secretos/mongo/` |
| `kaizen_etl` | Lectura y escritura en `kaizen_analitica` | El ETL | HomeLab `/etc/kaizen-homelab/secretos/` |
| `kaizen_api` | **Solo lectura** en `kaizen_analitica` | La API (desde nodo1) | HomeLab y nodo1 `/etc/kaizen/api.env` (`KAIZEN_MONGO_API_PASSWORD`) |

## Cómo comprobarlo

```bash
sudo podman exec -it kaizen-mongodb mongo --tls --tlsCAFile /etc/kaizen-tls/ca.crt --host 127.0.0.1 \
     -u admin -p --authenticationDatabase admin
> use kaizen_analitica
> db.getCollectionNames()
```

Comprobado desde nodo1 (23-nov-2026): la API conecta con TLS verificado contra la CA, ve las 3 colecciones y una
escritura es rechazada (solo lectura).
