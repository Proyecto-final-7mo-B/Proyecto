# Base de datos `kaizen`

## Qué es
La base transaccional de la app, dentro del clúster de [05_postgresql_patroni](../05_postgresql_patroni/): base
`kaizen`, esquema `kaizen`, dueño `kaizen_owner` (rol sin login). Las reglas de negocio importantes se hacen cumplir
**en la base** (triggers, procedimientos y RLS), no solo en la API.

## Fragmentación horizontal por región
La llave de fragmentación es `usuario.region`, calculada por `fn_region(pais, estado)` al registrarse. Las tablas de
usuario están particionadas por lista (`PARTITION BY LIST (region)`), y una consulta que incluye la región lee un
solo fragmento (poda de particiones comprobada con `EXPLAIN`).

| Región | Quién cae ahí |
|---|---|
| `MX-NORTE` | 18 estados de México (AGU, BCN, BCS, CHH, COA, COL, DUR, GUA, JAL, MIC, NAY, NLE, QUE, SIN, SLP, SON, TAM, ZAC) |
| `MX-CENTRO-SUR` | 14 estados (CAM, CHP, CMX, GRO, HID, MEX, MOR, OAX, PUE, ROO, TAB, TLA, VER, YUC) |
| `LATAM` | 19 países (AR, BO, BR, CL, CO, CR, CU, DO, EC, SV, GT, HN, NI, PA, PY, PE, PR, UY, VE) |

## Objetos

| Tipo | Detalle |
|---|---|
| 9 tablas fragmentadas (3 particiones c/u) | `usuario`, `habito`, `registro`, `racha`, `nivel_habito`, `sugerencia_ajuste`, `senal_diaria`, `capsula`, `sesion` |
| 1 tabla por mes | `bitacora_auditoria` (inmutable; particiones creadas hasta jun-2027 + `DEFAULT`) |
| 3 tablas globales | `categoria`, `directorio_usuarios` (HMAC del correo → usuario y región), `recuperacion_contrasena` (solo el SHA-256 del token) |
| 8 funciones | `fn_region`, `fn_dia_programado`, `fn_dia_programado_anterior`, `fn_rachas`, `fn_cumplimiento`, `fn_auditar`, `fn_usuario_actual`, `fn_verificar_admin` |
| 15 procedimientos | Registro, check-in idempotente, Escalera, cápsula, ARCO, recuperación de contraseña, administración y mantenimiento |
| 19 triggers | Racha recalculada, nivel inicial, meta solo por Escalera, región inmutable, consentimiento de señales, categoría activa, cuenta suspendida, bitácora inmutable… |
| 3 vistas | `v_racha_vigente`, `v_usuario_admin` (datos enmascarados), `v_metricas_region` (solo grupos de 5 o más) |
| RLS | 17 políticas: con el rol de la API, cada transacción solo ve las filas del usuario fijado con `set_config('kaizen.usuario_id', …, true)`. Sin eso, 0 filas |
| Catálogo | 8 categorías: Aprendizaje, Ejercicio, Finanzas, Hidratación, Lectura, Meditación, Salud y Sueño |

Los errores de negocio usan `SQLSTATE` propios, de `KZ001` a `KZ015`.

## Roles (mínimo privilegio)

| Rol | Login desde | Puede |
|---|---|---|
| `kaizen_owner` | — (NOLOGIN) | Dueño del esquema |
| `kaizen_api` | nodo1 | Leer, insertar en columnas permitidas y ejecutar los procedimientos de la API. Sin DDL, sin `UPDATE`/`DELETE` de reglas de negocio. 40 conexiones; `statement_timeout` 5 s |
| `kaizen_tareas` | nodo1 | Solo ejecutar 4 procedimientos de mantenimiento (Escalera diaria, limpieza de expirados, partición de la bitácora, verificación de rachas). No lee tablas |
| `kaizen_etl` | HomeLab | Solo lectura, **sin columnas personales**, sesión de solo lectura |
| `kaizen_monitor` | HomeLab | Métricas (`pg_monitor`), sin acceso a datos |
| `kaizen_admin` | — (grupo) | Mantenimiento para personas, sin ser superusuario |

## Zona horaria
La base trabaja en UTC. Las consultas que usan "hoy" (`current_date`) deben correr con la zona del usuario: la API
fija `set_config('TimeZone', <zona IANA>, true)` en cada transacción. Las tareas diarias corren a las 08:00 UTC.

## Cómo comprobarlo

```bash
sudo -u postgres psql -d kaizen
\dt kaizen.*                 -- tablas y particiones
\df kaizen.*                 -- funciones y procedimientos
\dp kaizen.habito            -- permisos por columna
SELECT tableoid::regclass, count(*) FROM kaizen.registro GROUP BY 1;   -- filas por fragmento
```

Pruebas: 62 del esquema original y 40 de los cambios del 23-nov-2026; todas pasan en el clúster.
