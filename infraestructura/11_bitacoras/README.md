# Bitácoras centralizadas

## Qué hace
Cada VM envía **todas** sus bitácoras al HomeLab. Si una VM se compromete o se pierde, el registro de lo que pasó
sigue a salvo fuera de ella.

## Cómo está desplegado

| | |
|---|---|
| Qué se envía | Sistema, SSH, sudo, auditd, Patroni y PostgreSQL (incluido pgAudit), Fail2ban, ufw y las alertas de Suricata |
| Cómo viaja | rsyslog, TCP 20514, **dentro de WireGuard** |
| Si el HomeLab está apagado | Cada VM guarda una cola en disco de hasta 256 MB y la envía al volver |
| Receptor | rsyslog en el HomeLab (en el sistema, fuera de los contenedores) |
| Dónde se guarda | `/var/log/kaizen/<equipo>/AAAA-MM-DD.log` (600 root): un archivo por equipo y por día |
| Retención | 90 días (`systemd-tmpfiles` borra lo más viejo) |
| Acceso al puerto | 20514 abierto solo para 10.10.0.1-3 en la zona `kaizen` de firewalld |

## Archivos

| Dónde | Archivo |
|---|---|
| VMs | `/etc/rsyslog.d/90-kaizen-remoto.conf` |
| HomeLab | `/etc/rsyslog.d/90-kaizen-receptor.conf`, `/etc/tmpfiles.d/kaizen-bitacoras.conf` |

## Cómo comprobarlo

```bash
# en el HomeLab
sudo ls /var/log/kaizen/                                   # una carpeta por VM
sudo tail -f /var/log/kaizen/nodo1/$(date +%F).log
sudo grep -h "suricata" /var/log/kaizen/nodo1/*.log | tail # alertas del IDS
# en una VM: generar un evento y verlo llegar
logger -t prueba-kaizen "hola HomeLab"
```
