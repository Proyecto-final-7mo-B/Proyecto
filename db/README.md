# Base de datos (PostgreSQL 16)

Estructura de la base `kaizen` que corre en el clúster (ver [`infraestructura/06_base_de_datos`](../infraestructura/06_base_de_datos/)).
Responsable: Jael Contreras.

```
db/
├── sql/         esquema, funciones, triggers, procedimientos, vistas, roles, RLS y sus pruebas
├── cambios/     cada cambio posterior de estructura: un script fechado y sus pruebas
└── sinteticos/  generador de datos sintéticos (~100 mil check-ins en las 3 regiones) para el clúster
```

La estructura vigente en el clúster es **`sql/01`-`07` + los scripts de `cambios/` en orden de fecha**.
Se comprobó que el resultado tiene los mismos objetos, las 17 políticas RLS y los 152 permisos que el dump del primario
del 23-nov-2026.

## `sql/`: esquema original (2.ª entrega)

| Archivo | Contenido |
|---|---|
| `01_esquema.sql` | Tipos, tablas fragmentadas por región (`LIST`), bitácora por mes, tablas globales, índices |
| `02_funciones.sql` | `fn_region`, `fn_dia_programado`, `fn_rachas`, `fn_cumplimiento`, … (todas con `search_path` fijo) |
| `03_triggers.sql` | T1-T10: invariantes del negocio (rachas, validación por lote, región fija, inmutabilidad, …) |
| `04_procedimientos.sql` | P1-P9: operaciones con reglas (registro, check-in idempotente, Escalera, cápsula, derechos ARCO, …) |
| `05_vistas.sql` | Racha vigente, enmascaramiento para administración, métricas por región (k ≥ 5) |
| `06_roles.sql` | Roles de servicio con mínimo privilegio (`kaizen_api`, `kaizen_etl`, `kaizen_monitor`, `kaizen_admin`) |
| `07_rls.sql` | Row-Level Security: cada transacción de la API solo ve las filas del usuario fijado |
| `90_pruebas.sql` | 62 pruebas automáticas (se ejecutan con los roles reales) |
| `91_carga_demo.sql` | Datos sintéticos para demostración (**no** se aplica en producción) |
| `run_pruebas.sh` | Recrea la base de prueba, aplica 01-07 y corre `90_pruebas.sql` |

## `cambios/`: cambios posteriores

| Fecha | Archivo | Qué cambió |
|---|---|---|
| 23-nov-2026 | `2026-11-23_ajustes_frontend_backend.sql` | `habito.escalera_activa`; suspensión de usuarios (`usuario.suspendido_en`, `sp_admin_suspender_usuario`, trigger en `sesion`, `v_usuario_admin`); categorías administrables (`sp_admin_crear_categoria`, `sp_admin_actualizar_categoria`, categoría inactiva no se usa); recuperación de contraseña (`recuperacion_contrasena`, `sp_solicitar_recuperacion`, `sp_restablecer_contrasena`); catálogo de 8 categorías; códigos `KZ010`-`KZ015` |
| 23-nov-2026 | `2026-11-23_rol_tareas.sql` | Rol `kaizen_tareas` (solo ejecuta 4 procedimientos de mantenimiento), `sp_limpiar_expirados`, `sp_crear_particion_bitacora` pasa a `SECURITY DEFINER` |
| 27-nov-2026 | `2026-11-27_evidencia_cientifica.sql` | Respaldo científico: catálogo jerárquico (5 categorías con clave, color e ícono; 22 subcategorías; unidades permitidas con factor y paso); `referencia_cientifica` (óptimo, máximo y piso por subcategoría, con fuentes); `habito.subcategoria_id`, `prioridad`, `intencion`; `fn_evaluar_meta` y `v_habito_evidencia` (zona bajo/óptimo/alto/excesivo); Escalera v2 (tope en el óptimo, baja por exceso desde el primer día, espera de 7 días tras "Mantener", redondeo por unidad, `motivo`); protector de racha (1 falla por semana); cápsulas 7/30/66; logros (`logro`, `logro_usuario`, `fn_logros_usuario`, `sp_otorgar_logros_semanales`); códigos `KZ016`-`KZ017`. Migra los hábitos existentes |
| 27-nov-2026 | `2026-11-27_evidencia_cientifica_revertir.sql` | Reversión del anterior (vuelve al estado del 23-nov) |
| 27-nov-2026 | `2026-11-27_recomendaciones.sql` | Revisión de Jael de la app: `fuente_cientifica` (las 53 fuentes de la investigación, para "Acerca de Kaizen"); `habito_recomendado` (100 hábitos saludables, 20 por categoría, meta en el óptimo, momento sugerido; id = md5 de su clave) y `v_habito_recomendado`; `habito.recomendacion_id` con el trigger `trg_habito_0_recomendacion` (copia los datos de la recomendación); "Plan si-entonces" ya no se otorga por la intención que trae una recomendación; `fn_dias_protegidos` (escudo del calendario); `sp_admin_guardar_recomendacion`; código `KZ018`. Aplicado en el clúster el 27-nov |
| 27-nov-2026 | `2026-11-27_recomendaciones_revertir.sql` | Reversión del anterior (los hábitos creados desde una recomendación se conservan como personalizados) |

| Archivo | Uso |
|---|---|
| `pruebas_ajustes.sql` | 40 pruebas de los cambios del 23-nov. Corren en una transacción que se revierte |
| `pruebas_evidencia.sql` | 81 pruebas de los cambios del 27-nov (zonas, Escalera v2, protector, cápsulas, logros, administración, permisos). Se revierten; pasan también sobre los datos sintéticos |
| `demo_zona_horaria.sql` | Demuestra por qué la API debe fijar `set_config('TimeZone', …)`: entre las 18:00 y las 23:59 de México la fecha UTC ya es "mañana" y las rachas se ven rotas. Se revierte |
| `pruebas_recomendaciones.sql` | 46 pruebas de las recomendaciones, las fuentes y los días protegidos (catálogo, zonas en el óptimo, crear desde una recomendación con el rol de la API, KZ018, días protegidos igual que `fn_rachas`, RLS, administración, permisos). Se revierten |
| `run_pruebas.sh` | Corre `../sql/run_pruebas.sh`; aplica los cambios del 23-nov y `pruebas_ajustes.sql`; aplica los del 27-nov y `pruebas_evidencia.sql`; aplica las recomendaciones y `pruebas_recomendaciones.sql` |

Cada cambio nuevo de estructura se agrega aquí como `AAAA-MM-DD_descripcion.sql` (en una transacción, idempotente
si se puede), con sus pruebas, y va en su propio PR.

## Roles y contraseñas

Los roles se crean **sin contraseña**. La contraseña de cada cuenta de servicio se genera en el equipo que la usa y
a PostgreSQL solo llega su verificador SCRAM-SHA-256. Ningún archivo de esta carpeta tiene secretos: los hashes y
las IPs que aparecen en las pruebas son valores ficticios.

## Probar en local

Con un PostgreSQL 16 o superior local (no hace falta contenedor):

```bash
psql -U postgres -c "CREATE ROLE kaizen_owner LOGIN"      # una sola vez
export PGHOST=/ruta/al/socket PGPORT=5432

./sql/run_pruebas.sh          # solo el esquema original    → 62 OK, 0 FALLA
./cambios/run_pruebas.sh      # esquema original + cambios  → 62 OK + 40 OK + 81 OK + 46 OK
```

Comprobado el 27-nov-2026 en PostgreSQL 18.6: 62/62, 40/40, 81/81 y 46/46 (229 en total); las recomendaciones también
se revirtieron y se volvieron a aplicar. La migración del 27-nov también se probó sobre
la carga sintética completa (aplicar, revertir y volver a aplicar).

## Aplicar en el clúster

Los scripts se aplican **en el primario** (`sudo kpatronictl list` dice cuál es); los cambios llegan solos a las
réplicas y al plan B.

1. Base nueva: `01`-`05` y `07` como dueño del esquema (`kaizen_owner`) y `06` como `postgres`, en el mismo orden que
   `sql/run_pruebas.sh`.
2. Después, cada script de `cambios/` en orden de fecha, como `postgres`.
3. Al terminar, correr las pruebas del cambio (se revierten y no dejan datos).
