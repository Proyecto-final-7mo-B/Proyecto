# Historial de cambios de estructura

Estos archivos **ya están incluidos** en `../kaizen_esquema.sql`: no hay que ejecutarlos en el entorno local.
Se guardan para saber qué cambió y para poder aplicar lo mismo en otra base que tenga la estructura anterior.

| Fecha | Archivo | Qué cambió | Dónde se aplicó |
|---|---|---|---|
| 23-nov-2026 | `2026-11-23_ajustes_frontend_backend.sql` | `habito.escalera_activa`; suspensión de usuarios (`usuario.suspendido_en`, `sp_admin_suspender_usuario`, trigger en `sesion`, `v_usuario_admin`); categorías administrables (`sp_admin_crear_categoria`, `sp_admin_actualizar_categoria`, índice sin mayúsculas, trigger de categoría activa); recuperación de contraseña (`recuperacion_contrasena`, `sp_solicitar_recuperacion`, `sp_restablecer_contrasena`); catálogo de 8 categorías; códigos KZ010–KZ015 | Clúster (primario nodo1, replicado a nodo2 y nodo3) el 23-nov-2026, 22:12 h del centro de México |
| 23-nov-2026 | `2026-11-23_rol_tareas.sql` | Rol `kaizen_tareas` (solo desde nodo1), `sp_limpiar_expirados`, `sp_crear_particion_bitacora` pasa a SECURITY DEFINER | Clúster (primario nodo2) el 23-nov-2026, 23:00 h |

`demo_zona_horaria.sql` demuestra el error de zona horaria (ver LEEME principal, sección 5.2).

`pruebas_ajustes.sql` contiene las 40 pruebas de esos cambios. Corren en una transacción que se revierte:

```bash
docker exec -i kaizen-pg psql -X -v ON_ERROR_STOP=1 -U postgres -d kaizen < postgres/cambios/pruebas_ajustes.sql
```
