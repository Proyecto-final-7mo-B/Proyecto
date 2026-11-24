# Entrada pública: Nginx con HTTPS

## Qué hace
Es la **única puerta desde Internet**. Termina TLS con un certificado público, aplica cabeceras de seguridad y
límites de peticiones, y pasa `/api/` a la API, que escucha solo en `127.0.0.1:8000` de nodo1.

## Cómo está desplegado

| | |
|---|---|
| Equipo | nodo1 |
| Versión | Nginx 1.24 (Ubuntu 24.04) |
| Dominio | `proyecto-kaizen.northcentralus.cloudapp.azure.com` (etiqueta DNS de Azure) |
| Certificado | Let's Encrypt (certbot), vence el 20-feb-2027 y se renueva solo (`certbot.timer`); el hook `/etc/letsencrypt/renewal-hooks/deploy/recargar-nginx.sh` recarga Nginx |
| TLS | 1.2 y 1.3, solo cifrados ECDHE + AEAD (grado A), OCSP stapling, sin *session tickets* |
| Cabeceras | HSTS (1 año), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Content-Security-Policy: default-src 'none'`, `Permissions-Policy`; sin versión del servidor |
| Bitácora | `/var/log/nginx/kaizen-access.log`, **sin** *query string* ni cabecera `Authorization`; errores en `kaizen-error.log` |

## Rutas y límites

| Ruta | Destino | Límite por IP |
|---|---|---|
| `:80` | Reto ACME y redirección 301 a HTTPS | — |
| `/salud` | Responde Nginx (para el monitoreo) | — |
| `/api/v1/auth/login`, `/registro`, `/recuperar`, `/restablecer` | API | 5 por minuto (ráfaga 5) — zona `kaizen_auth` |
| `/api/v1/auth/renovar`, `/api/v1/auth/salir` | API | 30 por minuto (ráfaga 10) — zona `kaizen_sesion`, para que varios usuarios detrás de un mismo NAT no reciban 429 |
| `/api/` (resto) | API | 10 por segundo (ráfaga 20) — zona `kaizen_api` |
| `/` | 404 en JSON (aquí se publicará la app web) | — |

**Errores en el formato de la API:** los 429 y los 502/503/504 generados por Nginx salen como
`application/problem+json` (`demasiadas-peticiones`, `servicio-no-disponible`). Mientras la API no esté desplegada,
`/api/` responde 503 en JSON.

## Archivos

| Archivo | Contenido |
|---|---|
| `/etc/nginx/conf.d/00-kaizen-global.conf` | `server_tokens off`, zonas de límite (`kaizen_auth`, `kaizen_sesion`, `kaizen_api`), formato de bitácora |
| `/etc/nginx/sites-available/kaizen` (enlazado en `sites-enabled`) | Los dos `server` (80 y 443), cabeceras, rutas y páginas de error |
| `/etc/nginx/kaizen-proxy.conf` | Cabeceras hacia la API (`X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`) y tiempos de espera |

Fail2ban vigila la bitácora de errores de Nginx (bots y exceso de límites); ver [10_endurecimiento](../10_endurecimiento/).

## Cómo comprobarlo

```bash
sudo nginx -t && sudo systemctl reload nginx
curl -sI https://proyecto-kaizen.northcentralus.cloudapp.azure.com/salud
curl -s  https://proyecto-kaizen.northcentralus.cloudapp.azure.com/api/v1/habitos    # 503 en JSON si la API no corre
nmap --script ssl-enum-ciphers -p 443 proyecto-kaizen.northcentralus.cloudapp.azure.com   # solo cifrados grado A
```
