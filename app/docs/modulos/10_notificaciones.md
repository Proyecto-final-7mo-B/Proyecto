# Paso 10 · Notificaciones adaptativas y "Mis avisos"

**Estado:** terminado · **Fecha:** 27-nov-2026 · **Contrato:** v1.7 (sin cambios) · **IA:** asistido (Claude), revisado por Samuel Rizo

Los avisos viven **en el teléfono**: la app los arma y los programa en el sistema (Android e iOS). No pasan por la
API ni por la base de datos, y no hay servidor de *push* (decisión del 26-nov: nada de enviar datos a un tercero).

- **Recordatorio de cada hábito** a la hora que elige el usuario, **solo los días que toca y solo si sigue
  pendiente**. Al marcar el hábito, el de hoy se quita. El texto lleva la intención ("Después de cenar: Leer.").
- **"Mis avisos":** el usuario programa los suyos **a cualquier hora** (9:35, 22:20…), **los días que quiera** y
  con **su propio texto**. Se pueden apagar, editar y quitar.
- **Automáticos:**
  - **racha en riesgo** (20:00, racha de 3 o más y el hábito pendiente);
  - **nuevo micro-paso** (una vez por sugerencia de la Escalera);
  - **resumen semanal** (domingo 18:00).
  La hora de la racha en riesgo y el día y la hora del resumen los elige el usuario.
- **Reglas del doc. 06:**
  - como mucho **3 automáticos al día**;
  - nada automático en las **horas de silencio** (22:00–08:00, configurables);
  - los textos **rotan** sin repetir ninguno de los últimos 3;
  - con **66 días** de racha, el recordatorio pasa a **semanal**;
  - si se ignoran **3 recordatorios seguidos**, ese hábito avisa en **días alternos** hasta que se hace 3 días seguidos.
- **Lo que programa el usuario siempre llega:** los recordatorios y "Mis avisos" no cuentan para el tope ni
  respetan el silencio, porque son su decisión explícita. En Android van a la **hora exacta** si el usuario lo
  permite (Android 14 lo trae apagado); la pantalla ofrece **"Permitir hora exacta"**.
- Todo se configura en **Perfil → Notificaciones** (`/perfil/notificaciones`), también desde Ctrl K.

## Respaldo científico

`Evidencias_generales/12_investigacion_cientifica/06_notificaciones.md`, con la sección **"Cambios al implementar
(Paso 10, 27-nov)"**:

- solo cuando falta el hábito y en el momento que eligió la persona: F49, F50;
- la intención en el texto: F04, F48;
- la rotación de textos: F46;
- la racha en riesgo: F09, F47;
- el desvanecimiento a los 66 días: F01, F48;
- el tope y el silencio solo para lo automático, y "Mis avisos": F02, F49, F50.

La **felicitación de hito** es la celebración dentro de la app al hacer el check-in (Paso 9): el hito se cruza con la
app abierta y una notificación después la repetiría.

## Cómo funciona

```
    abrir la app · volver al frente · check-in · cambiar preferencias · poner o quitar un recordatorio
                                                  │
                                                  ▼
  GestorAvisos.replanificar()  ──►  PlanificadorAvisos.planificar()  (puro: reglas del doc. 06, 7 días)
        │  lee: hábitos (copia local), sugerencias,                │
        │       preferencias e historial (tabla marcas, JSON),     ▼
        │       horas de recordatorio (tabla recordatorios)   List<AvisoProgramado>
        ▼                                                          │
  Notificador.reemplazar(plan)  ◄──────────────────────────────────┘
        NotificadorLocal: cancelAll + zonedSchedule de una sola vez por aviso (ids 70000+)
        NotificadorEnMemoria: escritorio, web y pruebas
```

- **Cada plan reemplaza al anterior.** No hay alarmas repetitivas: si el hábito se marca, el plan nuevo ya no trae
  el de hoy. Si no se abre la app en 7 días, los avisos se acaban; al abrirla se vuelven a planear.
- **Historial (30 días):** lo que ya pasó (avisos entregados y check-ins) sirve para la rotación y para detectar los
  recordatorios ignorados. Lo futuro del plan anterior se descarta en cada plan. Los micro-pasos se guardan aunque no
  hayan llegado, para avisar de cada sugerencia una sola vez sin posponerla al replanificar.
- **Check-ins:** `RegistrosRepositoryConAvisos` envuelve a los registros. Con cada check-in cumplido anota el evento y
  vuelve a planear; al desmarcar, también vuelve a planear (el recordatorio regresa).
- **Varias peticiones a la vez:** si llega una mientras se arma un plan, se arma uno más al terminar, y quien la pidió
  espera a ese segundo plan.
- **Errores:** si el sistema falla al programar, se registra y la app sigue; los avisos nunca la tumban.
- **Cerrar sesión:** espera el plan en curso, deja todo sin programar y no vuelve a planear hasta iniciar sesión.
- **Canales de Android:** uno por tipo (Recordatorios de tus hábitos, Mis avisos, Racha en riesgo, Micro-pasos de la
  Escalera, Resumen semanal), así que también se pueden apagar desde los ajustes del sistema.

## Pantalla: Notificaciones (`/perfil/notificaciones`)

| Sección | Qué hace |
|---|---|
| **Mis avisos** | Lista con hora y días ("22:20 · Lunes a viernes"), interruptor y quitar. "Agregar aviso" abre un diálogo con el reloj del sistema, los días (Lun … Dom, siempre al menos uno) y el texto (80 caracteres; vacío = "Revisa tus hábitos de hoy"). Tocar un aviso lo edita |
| **Recordatorios de tus hábitos** | Interruptor general y cada hábito activo con su hora ("Poner hora" o la hora con el botón para quitarla) |
| **Avisos automáticos** | Racha en riesgo (con su hora), Nuevo micro-paso y Resumen semanal (día y hora), cada uno con interruptor |
| **Horas de silencio** | Desde / Hasta |
| **Próximos avisos** | Los siguientes 5 programados ("Hoy 21:00", "Mañana 09:35", "28 nov 18:00") |
| **Cómo funcionan** | Las reglas en palabras simples, sin fuentes (regla del 27-nov) |

- **Escritorio** (1000 px o más): dos columnas. A la izquierda, lo que programa el usuario; a la derecha, lo
  automático. En escritorio y web, un aviso explica que las notificaciones llegan en el teléfono.
- **Avisos de la pantalla:**
  - si se negó el permiso, se explica cómo activarlo;
  - en Android sin "Alarmas y recordatorios", una tarjeta ofrece **Permitir hora exacta**.
- El campo de recordatorio del formulario de hábitos (Paso 7) sigue igual. Por dentro, la hora se guarda en la tabla
  local y el aviso lo arma el planificador.

## Archivos

| Archivo | Qué |
|---|---|
| `domain/models/avisos.dart` | `TipoAviso`, `AvisoPersonal`, `PreferenciasAvisos` (valores del doc. 06, silencio que cruza la medianoche), `AvisoProgramado`, `EventoAviso` (JSON) |
| `utils/planificador_avisos.dart` | `PlanificadorAvisos`: todas las reglas, puro y sin Flutter |
| `data/services/avisos/notificador.dart` | Interfaz `Notificador` y `NotificadorEnMemoria` |
| `data/services/avisos/notificador_local.dart` | `flutter_local_notifications`: zona del teléfono, canales, hora exacta o inexacta |
| `data/services/avisos/gestor_avisos.dart` | `GestorAvisos`: preferencias, historial, replanificar, check-ins, cerrar sesión |
| `data/services/recordatorios/servicio_recordatorios_adaptativo.dart` | El servicio del formulario: guarda la hora y vuelve a planear |
| `data/repositories/registros/registros_repository_con_avisos.dart` | Los check-ins ajustan los avisos |
| `data/services/base_local/almacen_local.dart` | `recordatorios()`: todas las horas, para el planificador |
| `ui/notificaciones/` | `NotificacionesViewModel` y `PantallaNotificaciones` (con `DialogoAviso`) |
| `config/dependencias.dart`, `app.dart` | Cableado; volver a planear al abrir, al iniciar sesión y al volver al frente; cancelar al salir |
| `routing/`, `ui/provisional/`, `ui/core/adaptativo/busqueda.dart` | Ruta, botón "Notificaciones" en Perfil y entrada de Ctrl K |
| `l10n/app_es.arb` | Los textos rotativos (6 por tipo; 4 de micro-paso) y los de la pantalla |
| `android/app/src/main/AndroidManifest.xml` | `SCHEDULE_EXACT_ALARM` |

Se retiraron `servicio_recordatorios_local.dart` (alarmas repetitivas) y `servicio_recordatorios_con_copia.dart`:
los reemplaza el planificador.

## Pruebas

| Tipo | Archivo | Cuántas | Qué cubren |
|---|---|---|---|
| Unitarias | `test/unit/notificaciones/planificador_avisos_test.dart` | 22 | Recordatorio de 7 días con la intención; hoy no si ya se hizo o ya pasó; días que tocan y "N por semana"; desvanecimiento a los 66 días; días alternos tras 3 ignorados y regreso con 3 días seguidos; ventana de 2 h; rotación sin repetir los últimos 3; "Mis avisos" (hora libre, días, sin silencio ni tope, inactivos); racha en riesgo (umbral, pendiente, protector, hora); tope de 3; silencio; micro-paso una vez (y conservado al replanificar, y al terminar el silencio); resumen (día y hora); ids y orden; preferencias y eventos en JSON |
| Unitarias | `test/unit/notificaciones/gestor_avisos_test.dart` | 7 | Preferencias guardadas; recordatorio que se va con el check-in (con el envoltorio de registros); micro-paso una sola vez; sin permiso no se guarda; historial de 30 días; replanificaciones simultáneas; cerrar sesión con un plan en curso; textos de los días |
| Unitarias | `test/unit/notificaciones/notificaciones_viewmodel_test.dart` | 6 | Carga; agregar a las 22:20, editar a las 9:35 de los lunes, apagar y quitar; sin permiso; recordatorio por hábito; automáticos, horas y silencio; hora exacta |
| Unitarias | `test/unit/datos/recordatorios_test.dart` | 7 | Notificador local: cancela y programa una vez por aviso, zona horaria, canal, *payload*, hora exacta o inexacta, zona inválida; notificador en memoria |
| Unitarias | `dependencias_almacen_test`, `sin_conexion_test` | 3 | Cableado (registros con avisos, servicio adaptativo, proveedor del gestor), hora en la tabla local |
| Widget | `test/widget/notificaciones/notificaciones_test.dart` | 11 | Desde Perfil con cada sección; reloj del sistema; aviso de 22:20 de lunes a viernes (editar, apagar, quitar); al menos un día; recordatorio y racha en riesgo a otra hora; interruptores y silencio; día del resumen; escritorio y web; hora exacta; sin permiso; Ctrl K |
| Golden | `test/golden/notificaciones_golden_test.dart` | 2 | Teléfono y escritorio (dos columnas) |
| Integración | `integration_test/notificaciones_test.dart` | 1 | Entrar → recordatorio de Leer a las 21:00 → marcarlo quita el de hoy → aviso de 22:20 de lunes a viernes → salir no deja nada |

**Resultado:**
- **Pruebas:** 663 de 663 en verde (633 sin goldens), más las 6 de integración en Linux.
- **`flutter analyze`:** sin avisos.
- **Cobertura:** 97.7 %; ViewModels, 98.4 %. El planificador, los modelos y el ViewModel están al 100 %.
- **Compilación:** compilan web, Linux y el APK.

## Cómo probarlo

**En el teléfono** (`flutter run --dart-define=KAIZEN_FUENTE=fake`), como Daniela (`KaizenDemo2026!`):

1. **Perfil → Notificaciones.** Acepta el permiso al agregar el primer aviso. Si aparece **Permitir hora exacta**, tócalo y activa "Alarmas y recordatorios".
2. **Agregar aviso:** pon la hora a 2 o 3 minutos de ahora, todos los días, con un texto propio. Bloquea el teléfono: llega a esa hora. Aparece en **Próximos avisos**.
3. En **Recordatorios de tus hábitos**, pon "Leer" a 2 minutos de ahora. Antes de que llegue, marca **Leer** en Hoy: el aviso de hoy ya no llega (sale de "Próximos avisos").
4. Apaga **Racha en riesgo** y cambia la hora del **Resumen semanal**: "Próximos avisos" se actualiza.
5. **Cerrar sesión:** no llega nada más.

**En escritorio** (`flutter run -d linux --dart-define=KAIZEN_FUENTE=fake`): la pantalla está en dos columnas y
explica que las notificaciones llegan en el teléfono.
