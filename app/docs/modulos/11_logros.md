# Paso 11 · Logros

**Estado:** terminado · **Fecha:** 27-nov-2026 · **Contrato:** v1.7 (§6.13, sin cambios) · **IA:** asistido (Claude), revisado por Samuel Rizo

Una sección propia para las **insignias**:

- **10 logros**, cada uno con su porqué:
  - rachas de 7, 30, 66 ("Hábito formado") y 100 días;
  - primer micro-paso;
  - ritmo ideal;
  - semana OMS;
  - racha salvada;
  - cápsula abierta;
  - plan si-entonces.
- **Los otorga la base**, con triggers y la tarea semanal (desde el 27-nov). La app solo los lee con `GET /logros`, y cada uno se obtiene una sola vez.
- **Este paso no cambia la base, el contrato ni el backend.** Angel ya tiene `GET /logros` en el contrato v1.7.

Lo nuevo en la app:

- **Logros** (`/logros`): el resumen ("6 de 10 insignias"), el filtro Todos · Obtenidos · Por obtener y una cuadrícula con cada insignia:
  - obtenida: con su fecha;
  - de racha pendiente: con su avance ("34 de 66 días");
  - las demás pendientes: "Por obtener".
- **Detalle de cada insignia:** cómo se obtiene, por qué existe, con qué hábito se obtuvo y "¿En qué nos basamos?" (abre Acerca de Kaizen). No muestra las claves de las fuentes, por la regla del 27-nov.
- **Navegación:**
  - en escritorio y web, una sección del riel y de la barra superior, entre Cápsulas y Acerca de;
  - en el teléfono se entra desde la tarjeta **"Último logro"** de Hoy y desde **Perfil**. La barra inferior se queda con 5 destinos.
- **Hoy:**
  - tarjeta **"Último logro"**, o **"Tu próxima insignia"** con su avance si aún no hay ninguna;
  - aviso breve **"Insignia nueva: …"** con "Ver" cuando se obtiene una (al marcar un hábito, al aceptar una subida, al volver a Hoy).
- **Sin red:** se ven los últimos logros leídos (copia local).

## Respaldo científico

`Evidencias_generales/12_investigacion_cientifica/05_rachas_y_motivacion.md`. La sección nueva **"Sección Logros
(Paso 11, 27-nov)"** cubre:

- el avance de lo que falta (gradiente de meta, F10);
- los colores de la racha y el gris con candado (F40, F42, F45);
- el aviso breve (F47, F48);
- el filtro por estado en lugar de por categoría (solo 4 de los 10 logros dependen de un hábito);
- que no hay rankings ni puntos.

Cada logro trae su porqué desde la base (`logro.porque`). Por ejemplo, "Hábito formado" se apoya en la mediana de 66
días (F01, F02).

## Cómo funciona

```
 base (PostgreSQL): triggers en racha, sugerencia_ajuste, capsula y habito + sp_otorgar_logros_semanales (lunes)
        │ fn_logros_usuario(region, usuario)
        ▼
 GET /logros ──► LogrosRepositoryApi ──► LogrosRepositoryLocal (copia en `marcas`: sin red se ve la última)
                                                 │
            ┌────────────────────────────────────┴─────────────────────────────┐
            ▼                                                                  ▼
   PantallaLogros (LogrosViewModel)                  HoyViewModel: ultimoLogro / proximoLogro
                                                     NovedadesLogros.revisar() ──► "Insignia nueva"
```

- **Novedades:** `NovedadesLogros` guarda en el dispositivo (`marcas`, clave `logros_vistos`) los que el usuario ya
  vio. La primera vez (instalación nueva o después de cerrar sesión) solo los anota, sin avisar. Después avisa de cada
  nuevo una vez. Hoy revisa al cargar, tras cada check-in y tras responder una sugerencia.
- **El aviso no tapa ni lo tapan:**
  - el de la insignia se va solo a los 4 s (un SnackBar con botón se quedaría pegado);
  - los demás avisos de Hoy esperan su turno (por ejemplo, "tu nueva meta es…" después de "Insignia nueva: Primer micro-paso").
- **El *fake*** (`LogrosRepositoryFake`) aplica las mismas reglas que la base:
  - la mejor racha de cualquier hábito;
  - un día perdonado por el protector;
  - una subida aceptada;
  - una cápsula abierta;
  - un hábito **personalizado** con intención (los recomendados traen la suya);
  - 150 min OMS en alguna de las 4 semanas anteriores;
  - 4 semanas en el óptimo con ≥ 85 %.
  - La fecha de cada uno se fija la primera vez que se cumple.
  - Daniela tiene **6 de 10**.

## Pantallas

| Dónde | Qué |
|---|---|
| `/logros` (teléfono) | Encabezado con regresar, resumen con barra, filtro, cuadrícula de 2 columnas y la nota "Sin rankings ni puntos" |
| `/logros` (escritorio y web) | Igual, en 3 o 4 columnas (desde 1200 px), dentro del riel o de la barra superior |
| Detalle | Insignia grande, estado (fecha u avance), "Con <hábito>", Cómo se obtiene, Por qué existe, "¿En qué nos basamos?" y Cerrar |
| Hoy | "Último logro" después de Próximo hito (teléfono) o debajo de Meta OMS y Próximo hito (escritorio y web) |
| Perfil | Botón "Logros" junto a "Notificaciones" |

**Colores (doc. 04):**
- Las insignias de racha llevan el color de su nivel: llama naranja a los 7, más profundo a los 30, dorado a los 66 y a los 100.
- Las demás obtenidas van en verde de progreso.
- Las que faltan van en gris, con candado y el texto "Por obtener" (el color nunca va solo).
- Nunca se usa el rojo de error.

## Archivos

| Archivo | Qué |
|---|---|
| `domain/models/logro.dart` | `Logro`, `TipoLogro`, `ultimoObtenido`, `proximoPorObtener`; JSON del contrato §6.13; `porqueParaMostrar` quita "(F3)" |
| `data/fake/logros_demo.dart` | El catálogo de la base (los mismos 10, en su orden) |
| `data/repositories/logros/` | Interfaz, `_api` (`GET /logros`), `_fake` (las reglas de la base) y `_local` (copia en `marcas`) |
| `data/services/logros/novedades_logros.dart` | Qué logros son nuevos en este dispositivo |
| `ui/logros/` | `LogrosViewModel`, `PantallaLogros` (con `TarjetaLogro` y el detalle), `InsigniaLogro`, `TarjetaUltimoLogro` |
| `ui/hoy/view_models/hoy_viewmodel.dart` | `ultimoLogro`, `proximoLogro`, `tomarLogrosNuevos()`; los logros se piden junto con lo demás y se revisan tras cada check-in |
| `ui/hoy/widgets/pantalla_hoy.dart` | Tarjeta "Último logro" y el aviso "Insignia nueva" (los demás avisos esperan su turno) |
| `config/dependencias.dart` | `logros` (con copia local) y `novedadesLogros`, con sus proveedores |
| `routing/`, `ui/core/adaptativo/destinos.dart`, `ui/core/tema/iconos.dart`, `ui/provisional/` | Ruta `/logros`, destino del riel y de la barra superior (también en Ctrl K), ícono y botón en Perfil |
| `l10n/app_es.arb` | Textos de la sección |

## Pruebas

| Tipo | Archivo | Cuántas | Qué cubren |
|---|---|---|---|
| Unitarias | `test/unit/logros/logros_test.dart` | 14 | JSON del contrato; "(F3)"; último y próximo. *Fake:* catálogo y orden, Daniela 6 de 10 con hábito y fecha, se obtienen una vez, primer micro-paso al aceptar, cápsula al abrir, plan si-entonces solo personalizado, "Primera semana" justo al día 7, sin red. Copia local sin red; novedades (la primera vez no avisa, después una vez); `LogrosViewModel` (filtros y error) |
| Unitarias | `test/unit/hoy/hoy_viewmodel_test.dart` | +3 | Sin repositorio no hay tarjeta; último y próximo; la primera carga no avisa y aceptar una subida avisa una vez; un check-in que da un logro lo avisa |
| Unitarias | `repositorios_api_test`, `dependencias_almacen_test`, `adaptativo_test` | +1 y ajustes | `GET /logros`; cableado con copia local y 19 proveedores; 8 secciones en el riel |
| Widget | `test/widget/logros/logros_test.dart` | 8 | Resumen, obtenidas y avance, sin fuentes; filtros; detalle y "¿En qué nos basamos?"; error y Reintentar; riel en escritorio con 4 columnas; desde Perfil y desde "Último logro"; cuenta nueva; aceptar una subida avisa "Insignia nueva" y "Ver" abre Logros con 7 de 10 |
| Widget | `pantalla_hoy_test`, `navegacion_test` | ajustes | La nueva meta llega después del aviso de la insignia; el riel con Logros (y se desplaza para llegar a Admin a 800 px) |
| Golden | `test/golden/logros_golden_test.dart` | 3 | Teléfono, escritorio y detalle; `shell_escritorio`, `shell_web` y `acerca_escritorio` se regeneraron (el riel lleva Logros y Hoy, la tarjeta) |
| Integración | `integration_test/logros_test.dart` | 1 | Entrar → "Último logro" → aceptar la subida → "Insignia nueva" → Ver → 7 de 10 → detalle |

**Resultado:**
- **Pruebas:** 692 de 692 en verde (659 sin goldens), más las 7 de integración en Linux.
- **`flutter analyze`:** sin avisos.
- **Cobertura:** 97.7 %; ViewModels, 98.5 %. Logros, entre 93 y 100 %.
- **Compilación:** compilan web, Linux y el APK.

## Cómo probarlo

Con `flutter run -d linux --dart-define=KAIZEN_FUENTE=fake` (o en el teléfono), como Daniela (`KaizenDemo2026!`):

1. **Hoy:** la tarjeta "Último logro" dice "Ritmo ideal · Obtenida el 23 nov · Con Tomar agua". Tócala.
2. **Logros:** "6 de 10 insignias". "Hábito formado" va en "34 de 66 días". Prueba los filtros y abre "Un mes": dice con qué hábito se obtuvo y por qué existe.
3. Regresa a Hoy y **acepta el micro-paso** de Leer: aparece "Insignia nueva: Primer micro-paso". Toca **Ver**: ahora son 7 de 10.
4. En escritorio, **Logros** está en el riel. En el teléfono, en **Perfil → Logros**.
