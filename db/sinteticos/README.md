# Datos sintéticos para el clúster

Puebla la base `kaizen` del clúster con **personas inventadas** para la presentación: suficientes datos para ver la
fragmentación, la replicación y el monitoreo con carga. Issue #26.

| | |
|---|---|
| Check-ins (`registro`) | **100 086**, casi en tercios: MX-NORTE 33 557 · MX-CENTRO-SUR 33 541 · LATAM 32 988 |
| Cuentas | 927 (310 · 309 · 308), en los 32 estados de México y los 19 países de LATAM que acepta `fn_region` |
| Además | 2 503 hábitos, 33 664 señales de ánimo y energía, 276 cápsulas cifradas (28 abiertas), 1 025 sugerencias de la Escalera (401 respondidas), 4 236 eventos de bitácora |
| Historial | 120 días; constancia variable por persona (unos cumplen casi siempre, otros abandonan) |

Ningún dato es real: los correos usan el dominio reservado `@kaizen.test` (RFC 2606) y las IPs el rango de
documentación `203.0.113.x` (RFC 5737). Nombres y apellidos se combinan al azar.

## Cuentas para la demostración

Todas usan la misma contraseña, que **no se versiona** (la responsable la tiene en su copia de secretos).

| Correo | Región | Para mostrar |
|---|---|---|
| `demo@kaizen.test` | MX-NORTE | 4 hábitos, uno por cada caso de la evidencia: Caminar 30 min (óptimo, racha de más de 30 días, prioridad alta), Repasar apuntes 300 min (excesivo: la Escalera propone bajar a 240), Leer 15 páginas (bajo con 20 días seguidos: propone subir) y Dormir 7 h (óptimo). Todos con intención "Después de ___"; cápsula de 30 lista para abrir y otra de 66; logros; señales |
| `admin@kaizen.test` | MX-CENTRO-SUR | Rol administrador: usuarios enmascarados, métricas, suspensión |
| `latam@kaizen.test` | LATAM | Región LATAM con sugerencias de la Escalera pendientes |
| `nuevo@kaizen.test` | MX-CENTRO-SUR | Recién registrado, sin hábitos |
| `suspendido@kaizen.test` | MX-NORTE | Suspendido por el admin: el login debe rechazarlo (`KZ012`) |
| `nombre.apellidoN@kaizen.test` | las 3 | Los 922 usuarios sintéticos |

## Cómo funciona

```
laptop: generar.py ──(SQL con COPY: huellas, hashes y cifrados; sin llaves)──▶ cargar.sh ──ssh──▶ primario: psql como postgres
```

- `generar.py` lee **solo** `KAIZEN_EMAIL_HMAC_KEY` y `KAIZEN_CAPSULA_KEY_V1` del `.env` de la API, para que los
  usuarios usen las mismas convenciones que la API: HMAC del correo en el directorio, contraseña Argon2id y cápsulas
  AES-256-GCM (AAD = id de la cápsula). Así se puede iniciar sesión con ellos desde la app.
- El SQL corre en **una transacción**: si algo falla no queda nada. Antes de escribir comprueba que el nodo sea el
  primario, que la fecha coincida (UTC) y que no haya ya datos `@kaizen.test`. También comprueba que la región de
  cada usuario coincida con `fn_region`, que las categorías existan y que las rachas coincidan con
  `sp_reconstruir_rachas`. Al final prueba como `kaizen_api` que el directorio encuentra a demo por su HMAC y que la RLS
  devuelve 0 filas sin usuario fijado.
- Las réplicas (nodo1, nodo3 y el plan B del HomeLab) reciben los datos solas.
- Misma semilla = mismas personas, hábitos y check-ins.

## Uso

```bash
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

# 1. Generar (queda en salida/, que no se versiona)
.venv/bin/python generar.py --llaves <ruta>/api.env --password-archivo <ruta>/sinteticos.pass
#    opciones: --registros 100000  --dias 120  --semilla 2026

# 2. Cargar en el primario (el líder de: ssh nodo1-proyecto sudo kpatronictl list)
./cargar.sh nodo2-proyecto

# 3. Evidencia: filas por fragmento, directorio, poda de particiones, tamaño y retraso de las réplicas
ssh nodo2-proyecto 'cd /tmp && sudo -u postgres psql -X -d kaizen' < verificar.sql

# Para quitarlo todo (cancelación ARCO de cada cuenta @kaizen.test)
ssh nodo2-proyecto 'cd /tmp && sudo -u postgres psql -X -v ON_ERROR_STOP=1 -d kaizen' < limpiar.sql
```

El script generado sirve solo el mismo día (UTC) en que se generó, porque las fechas son relativas a "hoy".
La bitácora es de solo inserción: `limpiar.sql` borra todo lo demás, pero los eventos de bitácora se quedan.

## Verificación (26-nov-2026)

- En un PostgreSQL local con `sql/01-07` + `cambios/` y llaves de prueba: carga, login simulado (HMAC → directorio →
  Argon2), descifrado de cápsulas, `limpiar.sql` y recarga.
- En el clúster: carga en 30 s en el primario (nodo2); nodo1, nodo2 y nodo3 con las mismas cifras (927 usuarios,
  100 086 check-ins, 33 664 señales); retraso de réplicas 0 bytes; la consulta con región lee solo su fragmento.

## Recarga del 27-nov-2026 (esquema con respaldo científico)

- Antes: respaldo diferencial con pgBackRest (`20261122-210929F_20261127-012645D`), migración
  `cambios/2026-11-27_evidencia_cientifica.sql` (4 s) y sus 81 pruebas en el primario.
- `limpiar.sql` y carga nueva: 965 cuentas (322 · 322 · 321) y 100 080 check-ins (33 345 · 33 184 · 33 551),
  2 576 hábitos con subcategoría, prioridad e intención; 298 cápsulas de 7/30/66; 2 585 logros.
- Hábitos por zona de la evidencia: óptimo 919 · bajo 640 · sin referencia 508 · alto 325 · excesivo 184.
- nodo1, nodo2 y nodo3 con las mismas cifras; plan B en el HomeLab transmitiendo, retraso de 0 bytes.
- Salidas en `evidencia_cambios_2026-11-27/` (fuera del repositorio).

