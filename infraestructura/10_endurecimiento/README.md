# Endurecimiento de las VMs

Aplicado igual en nodo1, nodo2 y nodo3. Resultado de **Lynis: 65 → 82** en los tres (meta ≥ 75).

## Controles

| Control | Detalle | Archivo |
|---|---|---|
| SSH | Solo con llave y solo el usuario `azureuser`; sin root (`PermitRootLogin no`); 3 intentos; sin X11 ni reenvío de agente; reenvío TCP solo local y solo en nodo1 (túneles de desarrollo); banner legal; registro `VERBOSE`. Además, el firewall solo acepta SSH desde la laptop por WireGuard | `/etc/ssh/sshd_config.d/01-kaizen.conf`, `/etc/issue.net` |
| Kernel | Sin redirecciones ICMP ni *source routing*, `rp_filter`, registro de paquetes marcianos, `kptr_restrict` y `dmesg_restrict`, sin `sysrq` ni volcados de programas SUID | `/etc/sysctl.d/90-kaizen.conf` |
| Módulos | `dccp`, `sctp`, `rds`, `tipc` y `usb-storage` deshabilitados | `/etc/modprobe.d/90-kaizen-blacklist.conf` |
| Cuentas | Umask 027, rondas SHA mínimas 10,000, edad de contraseña, *home* en 750, sin volcados de memoria | `/etc/login.defs`, `/etc/security/limits.d/90-kaizen-core.conf` |
| Servicios | ModemManager, udisks2 y packagekit deshabilitados | — |
| auditd | Vigila identidad (usuarios y grupos), sudo, SSH, WireGuard, etcd, Patroni, **los secretos de Kaizen (`/etc/kaizen/`)**, el firewall y la carga de módulos del kernel | `/etc/audit/rules.d/90-kaizen.rules` |
| AIDE | Base de integridad de archivos (~33 MB) con revisión diaria; excluye datos que cambian solos (PostgreSQL, etcd, bitácoras) | `/etc/aide/aide.conf.d/99_kaizen`, `/var/lib/aide/aide.db` |
| Fail2ban | SSH en los 3 nodos; en nodo1 también bots de Nginx y exceso de límites de peticiones. Bloqueo de 1 h; nunca bloquea a la laptop (10.10.0.4) | `/etc/fail2ban/jail.d/90-kaizen.conf`, `91-kaizen-nginx.conf` |
| Contabilidad | `acct` (comandos por usuario) y `sysstat` | — |

**No se aplicó:** contraseña de GRUB (no hay consola física en Azure) ni particiones separadas para `/var` y `/home`
(requeriría reinstalar). Lynis da un falso positivo `PKGS-7388`: no lee el formato `ubuntu.sources` de Ubuntu 24.04.

## Cómo comprobarlo

```bash
sudo lynis audit system --quick | grep "Hardening index"
sudo fail2ban-client status sshd
sudo ausearch -k kaizen-secretos --start today        # accesos a /etc/kaizen/
sudo aide --check --config /etc/aide/aide.conf | head
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication|maxauthtries"
```
