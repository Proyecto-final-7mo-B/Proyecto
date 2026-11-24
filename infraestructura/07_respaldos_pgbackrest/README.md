# Respaldos: pgBackRest

## Qué hace
Respalda el clúster en el HomeLab, cifrado desde el origen, y archiva el WAL de forma continua: se puede restaurar a
cualquier momento con una pérdida máxima de ~1 minuto (RPO ≤ 60 s).

## Cómo está desplegado

| Aspecto | Configuración |
|---|---|
| Versión | pgBackRest 2.50, instalado en nodo1-3 |
| Stanza | `kaizen` |
| Repositorio | HomeLab `/srv/pgbackrest/repo`. Las VMs escriben por **SFTP** con el usuario `pgbackrest`, que solo puede usar SFTP, está encerrado en `/srv/pgbackrest` y acepta una llave por nodo, cada una limitada a la IP de su nodo |
| Cifrado | AES-256-CBC **en el origen**: el HomeLab solo guarda datos cifrados y no conoce la contraseña |
| WAL | `archive_mode=on`, `archive_command = pgbackrest --stanza=kaizen archive-push %p`, `archive_timeout=60`. Envío asíncrono con cola de máximo 2 GiB, para no llenar el disco del primario si el HomeLab está apagado |
| Réplicas | Pueden recuperar WAL del repositorio (`restore_command = pgbackrest … archive-get`) |
| Calendario (UTC) | Completo: domingos 03:00. Diferencial: lunes a sábado 03:00 |
| Retención | 4 respaldos completos |
| Quién respalda | Los temporizadores existen en los 3 nodos, pero `/usr/local/sbin/kaizen-respaldo` solo actúa en el **primario vigente** |
| Firma | El HomeLab firma con **Ed25519** el manifiesto de cada respaldo nuevo (cada hora) en `/srv/pgbackrest/firmas/`; la firma se verifica antes de restaurar |
| Prueba de restauración | Contenedor aislado en el HomeLab (`kaizen-prueba-restauracion`): restauró en 11 s |

## Archivos

| Dónde | Archivo |
|---|---|
| VMs | `/etc/pgbackrest/pgbackrest.conf`, `/etc/pgbackrest/conf.d/cifrado.conf` (640 root:postgres), llave SFTP `/var/lib/postgresql/.ssh/id_pgbackrest` |
| VMs | Temporizadores `kaizen-respaldo-full.timer` y `kaizen-respaldo-diff.timer`; bitácoras en `/var/log/pgbackrest/` |
| HomeLab | Repositorio `/srv/pgbackrest/repo` (SELinux `ssh_home_t`), firmas `/srv/pgbackrest/firmas/`, llave de firma `/etc/kaizen-homelab/firma/` |

## Cuando el HomeLab está apagado
- Los respaldos programados fallan y se registran.
- El WAL se queda en el primario (`pg_wal`) y se envía solo al volver el HomeLab.
- Volcado manual previo a los cambios del 23-nov: `/var/backups/kaizen/antes_ajustes_2026-11-23.dump` en nodo1.

## Cómo comprobarlo

```bash
sudo -u postgres pgbackrest --stanza=kaizen info          # status: ok y lista de respaldos
sudo -u postgres pgbackrest --stanza=kaizen check         # prueba el archivado de WAL de punta a punta
sudo -u postgres psql -XAtc "select archived_count, failed_count, last_archived_time from pg_stat_archiver"
sudo kaizen-respaldo full                                  # respaldo completo manual (en el primario)
```
