# Paso 9 · Identidad visual, motivación y hábitos recomendados

**Estado:** terminado · **Fecha:** 27-nov-2026 · **Contrato:** v1.7 · **IA:** asistido (Claude), revisado por Samuel Rizo

El profesor pidió que la app se sustente en evidencia científica (26-nov) y Jael revisó la app el 27-nov. Este paso
reúne lo visual y lo motivacional de esa retroalimentación:

- **Paleta con respaldo:** verde para lo hecho y el progreso, teal para el bienestar, el rojo solo para errores.
- **Racha por niveles:** chispa → llama → llama con aro → "hábito formado" dorado (66 días) → emblema (100), con el escudo del protector.
- **Celebración** al cruzar 7, 30, 66 y 100 días.
- **Hoy:** lo pendiente arriba por prioridad y lo hecho al final ("Hechos hoy"), con su animación.
- **Widgets del escritorio y web:** meta semanal OMS, próximo hito (barra hacia el hito y un mensaje de ánimo) y **"Esta semana, por hábito"**. El **Consejo saludable** va en el riel de escritorio (en web, en la columna derecha de Hoy); es solo el consejo, sin enlace, y cambia cada día.
- **Nuevo hábito = 100 hábitos recomendados** (20 por categoría). Solo se elige prioridad y cápsula; para todo lo demás está **Hábito personalizado** (el formulario del Paso 7).
- **Acerca de Kaizen** (`/acerca`): una **sección del riel y de la barra superior** ("Acerca de"), con portada, cómo funciona, los rangos por categoría y las 53 fuentes con filtro por tema.
- **Escudo en el calendario** el día que el protector perdonó una falla: en el del detalle y en el de Hoy (escritorio).
- **Detalle del hábito:** tarjetas de racha y cumplimiento con ícono, color y nota; la gráfica de tendencia con ejes, valores, la línea del 85 % y su explicación.
- El aviso **"Sin conexión"** ya no aparece mientras un check-in se envía, solo cuando de verdad falló.

**Regla nueva (27-nov):** fuera del detalle del hábito no se muestran fuentes, solo lo recomendado y la medición. El
detalle conserva la fuente y "Acerca de Kaizen" las reúne todas.

## Respaldo científico

Todo está en `Evidencias_generales/12_investigacion_cientifica/`.

| Qué | Documento | Fuentes principales |
|---|---|---|
| Colores, contraste y simulación de daltonismo | 04 | F40–F45 |
| Niveles de racha, celebraciones, widgets, consejo en el riel | 05 | F01, F09, F10, F42, F47, F48 |
| Orden de Hoy (pendientes por prioridad, hechos abajo) | 07 | F02, F03, F10 |
| Los 100 hábitos recomendados, sin fuentes en pantalla, escudo | 08 | doc. 03, F04, F06, F53 |

## Pantallas

### Hoy (`/hoy`)

- **Teléfono:** "N de M" (barra verde sobre marino) y semana L–D. Luego los pendientes, ordenados por prioridad y nombre, con "Alta" y su bandera. Después vienen:
  - "Hechos hoy · N hechos";
  - la tarjeta compacta **Próximo hito**;
  - **Tu mes** (el calendario con el % del mes y los escudos, como en escritorio);
  - la sugerencia y la señal;
  - el **Consejo saludable** al final.
- **Escritorio y web:** debajo de los hábitos van **Meta semanal OMS** y **Próximo hito** lado a lado (misma altura) y **Esta semana, por hábito** (el % de lunes a hoy de cada hábito, con su ícono y color). Sustituye al mapa de 12 semanas, que repetía lo del calendario (revisión de Jael, 27-nov). El calendario del mes marca con un escudo los días en que el protector perdonó a algún hábito. En web, el **Consejo saludable** va en la columna derecha; en escritorio, en el riel; en el teléfono, al final de Hoy. El calendario ("Tu mes") lleva el % de cumplimiento del mes.
- **Marcar** un hábito lo baja a "Hechos hoy" con una animación de 350 ms; desmarcarlo lo regresa a su lugar. Sin animación si el sistema pide reducir movimiento.
- **Celebración:** si un check-in hace cruzar 7, 30, 66 o 100 días (o cada centena después), se abre un diálogo. Lleva el símbolo del nivel, "¡7 días seguidos!", el dato científico sin cita y "Seguir". La animación dura 900 ms.

### Nuevo hábito (`/habitos/nuevo`) y Hábito personalizado (`/habitos/nuevo/personalizado`)

- Chips de categoría (con su color e ícono) y, por subcategoría, tarjetas con nombre, "30 min · L-V" y el momento ("Después de comer"). En escritorio, dos columnas.
- Tocar una abre el detalle: una hoja abajo en el teléfono, un diálogo en escritorio. Muestra meta y frecuencia, "Dentro de lo recomendado: 30–60 min cada vez", **Cuándo**, **Por qué**, prioridad (alta, media o baja), cápsula (sin cápsula, 7, 30 o 66) y **Crear hábito**.
- Al crear sin cápsula regresa a donde se empezó; con cápsula abre su pantalla, igual que el formulario.
- **Hábito personalizado** *reemplaza* esta pantalla por el formulario. Así, al guardar se vuelve al origen y no a las recomendaciones.
- "¿En qué nos basamos?" abre "Acerca de Kaizen".

### Acerca de Kaizen (`/acerca`)

- **Portada:** el porqué de Kaizen sobre marino y tres cifras (66 días, 18 rangos, 53 fuentes).
- **Cómo funciona:** seis tarjetas con ícono (formación de hábitos, creación, Escalera, rachas y protector, colores, qué es Kaizen).
- **Rangos recomendados:** una tarjeta por categoría con su color, cada subcategoría con su rango, máximo, cita y una pastilla de confianza (verde, ámbar o gris, con texto) (`GET /categorias`).
- **Fuentes:** filtro por tema y una tarjeta por fuente con su clave, tema y confianza. Al abrirla muestra lo que tomamos de ella, el enlace (seleccionable) y cómo se verificó (`GET /fuentes`).
- Si la API falla, los textos se ven igual y se puede reintentar.
- Se llega desde el **riel** (escritorio), la **barra superior** (web), **Nuevo hábito** y el **detalle del hábito** ("¿En qué nos basamos?"; es la entrada en el teléfono) y la búsqueda Ctrl K. Ya no está en Perfil.

### Detalle del hábito

- El calendario marca con un **escudo** los días que perdonó el protector (`GET /habitos/{id}/protegidos`). Si esa consulta falla o no hay red, el calendario se ve sin escudos.
- **Tarjetas (escritorio):**
  - **Racha actual:** símbolo y color de su nivel, más "Próximo hito".
  - **Racha máxima:** trofeo dorado, más "Tu mejor marca".
  - **Cumplimiento de 30 días:** con los umbrales de la Escalera. Verde desde 85 % ("Ritmo para subir de nivel"), ámbar de 50 a 84 % y gris debajo de 50 %. Nunca rojo.
- **Tendencia:** la dibuja la app con `fl_chart`, a partir de los check-ins que ya trae el detalle; funciona sin red y sigue la paleta. Lleva:
  - **eje Y:** "% de días cumplidos", de 0 a 100 %;
  - **eje X:** "Semana que empieza el…", con fechas;
  - un punto por semana y su valor al tocarlo;
  - la línea punteada del 85 % (con lo que la Escalera propone subir);
  - una explicación debajo.
- **Las gráficas de Matplotlib** son para los reportes del panel de admin (imágenes del ETL, #33). En la app no hacen falta, porque la gráfica se dibuja con los datos que ya llegan.
- "¿En qué nos basamos?" abre Acerca de Kaizen.

## Datos (contrato v1.7)

| Repositorio | Método | API |
|---|---|---|
| `HabitosRepository` | `recomendados()` | `GET /habitos/recomendados` |
| | `crearRecomendado(id, prioridad:)` | `POST /habitos {"recomendacion_id","prioridad"}`: la base copia lo demás |
| | `diasProtegidos(id, desde:, hasta:)` | `GET /habitos/{id}/protegidos` → `{"fechas": […]}` |
| `CategoriasRepository` | `fuentes()` | `GET /fuentes` |
| `ProgresoRepository` | `obtener(...)` (sin cambio de firma) | `actividad_semanal` en `/progreso` (meta OMS) |

- **Sin red:** recomendaciones y fuentes se leen de la copia en la tabla `marcas` (como JSON, sin tablas nuevas). Crear una recomendada sí exige red. Los días protegidos, sin red, vuelven vacíos.
- **Modo *fake*:** `lib/data/fake/recomendados_demo.dart` y `fuentes_demo.dart` salen de la base con estas consultas. Los ids son los del clúster: categorías y subcategorías de `catalogo_demo.dart`; recomendaciones de `md5('kaizen-recomendacion:' || clave)`.

```sql
SELECT json_agg(json_build_object('id', id, 'clave', clave, 'nombre', nombre,
  'categoria', json_build_object('id', categoria_id, 'clave', categoria_clave, 'nombre', categoria_nombre,
                                 'color', categoria_color, 'icono', categoria_icono),
  'subcategoria', json_build_object('id', subcategoria_id, 'clave', subcategoria_clave, 'nombre', subcategoria_nombre,
                                    'icono', subcategoria_icono, 'sentido', sentido),
  'unidad', unidad, 'meta', meta,
  'frecuencia', json_build_object('tipo', frecuencia_tipo, 'dias_semana', dias_semana, 'veces_semana', veces_semana),
  'momento', momento, 'porque', porque, 'fuentes', fuentes, 'zona', zona,
  'optimo_desde', optimo_desde, 'optimo_hasta', optimo_hasta)
  ORDER BY categoria_orden, subcategoria_orden, orden) FROM kaizen.v_habito_recomendado;

SELECT json_agg(row_to_json(f) ORDER BY clave) FROM kaizen.fuente_cientifica f;
```

- La demo tiene a "Estudiar inglés" con racha de 6 (marcarlo hoy celebra los 7). "Leer" tiene una falla perdonada el lunes de esta semana: escudo en su fila de Hoy y en el calendario, y su racha sigue en 34.
- **Corrección del *fake*:** un hábito creado después de las 18:00 en México quedaba "creado mañana" y rechazaba el check-in de hoy. Ahora `DatosDemo.diaDe` toma el día local de un instante guardado en UTC.

## Archivos

| Archivo | Qué |
|---|---|
| `ui/core/tema/colores.dart` | Tokens nuevos: `verdeProgresoSobreMarino`, `tealBienestar`, `tealSobreMarino` y los colores de la racha (`rachaSinRacha`, `rachaChispa`, `rachaProfunda`, `rachaDorada`) |
| `utils/hitos.dart` | `NivelRacha` y `Hitos` (siguiente, cruzado) |
| `ui/core/apariencia_racha.dart` | Color, ícono, escala y aro de cada nivel |
| `ui/core/widgets/indicador_racha.dart` | Racha por niveles con escudo del protector |
| `ui/core/widgets/celebracion_hito.dart` | Celebración de los hitos |
| `ui/core/widgets/fila_habito.dart`, `barra_progreso.dart` | "Alta", escudo, check y barras en verde |
| `ui/core/widgets/calendario_mes.dart` | Escudo en los días protegidos |
| `ui/core/adaptativo/consejo_riel.dart` | Consejo saludable en el riel de escritorio (sin enlace) |
| `ui/core/adaptativo/destinos.dart` | "Acerca de" en el riel y la barra superior |
| `ui/core/widgets/tarjeta_kpi.dart` | Ícono, color y nota opcionales |
| `ui/habitos/widgets/tarjetas_detalle.dart` | Gráfica de tendencia con ejes, valores, tooltip y línea del 85 % |
| `ui/hoy/consejos.dart` | Los 14 consejos (en `app_es.arb`) y su rotación diaria |
| `ui/hoy/widgets/panel_hoy.dart` | Meta semanal OMS, Próximo hito (barra y ánimo), Consejo saludable, Esta semana por hábito |
| `ui/hoy/view_models/hoy_viewmodel.dart` | Pendientes y hechos, celebración, próximo hito, meta OMS, semana por hábito, escudos del calendario, consejo del día |
| `ui/habitos/widgets/pantalla_recomendados.dart` y `view_models/recomendados_viewmodel.dart` | Nuevo hábito con las recomendaciones |
| `ui/acerca/` | Acerca de Kaizen |
| `domain/models/recomendacion.dart` | `HabitoRecomendado` y `FuenteCientifica` |
| `domain/models/progreso.dart` | `ActividadSemanal` y `MejorRacha.categoriaClave` |
| `data/sync/sincronizador.dart`, `almacen_local.dart` | El aviso solo con fallas reales (`fallidos` en la cola); JSON en `marcas` |

## Pruebas

| Tipo | Archivo | Cuántas | Qué cubren |
|---|---|---|---|
| Unitarias | `test/unit/tema/contraste_test.dart` | 6 | Hex del doc. 04, contraste WCAG de cada token y de cada categoría del catálogo, ningún token de progreso es el rojo de error |
| Unitarias | `test/unit/utils/hitos_test.dart` | 5 | Cortes de nivel, siguiente hito, hito cruzado (solo al subir), rotación de los 14 consejos |
| Unitarias | `test/unit/hoy/hoy_viewmodel_test.dart` | +10 | Pendientes y hechos, celebración una sola vez (y no al desmarcar ni con error), próximo hito, meta OMS sumada de los registros, semana por hábito, escudos del calendario de Hoy, consejo del día |
| Unitarias | `test/unit/habitos/recomendados_viewmodel_test.dart` | 8 | 100 recomendaciones, grupos por subcategoría, elegir reinicia, crear con prioridad, KZ018, error de carga; Acerca de Kaizen |
| Unitarias | `repositorios_fake_test`, `repositorios_api_test`, `sin_conexion_test`, `base_local_test` | +11 | Recomendaciones (20 por categoría, id de la base, **la zona de la base = la de `EvaluadorEvidencia` en las 100**), crear desde una recomendación, días protegidos, fuentes, rutas y cuerpos de la API, copia sin red, aviso solo con fallas reales |
| Widget | `test/widget/hoy/panel_hoy_test.dart` | 13 | Meta OMS (falta, dentro, arriba, vigorosos), próximo hito (barra y el ánimo según qué tan cerca va), consejo sin cita ni enlace, semana por hábito, celebración (textos y reducir movimiento), **ningún widget de progreso o racha usa el rojo** |
| Widget | `test/widget/hoy/pantalla_hoy_test.dart` | +7 | Orden y "Hechos hoy" con animación, celebración al marcar, tarjeta compacta, widgets de escritorio, consejo en web (sin enlace), escudo en el calendario de Hoy, "Tu mes" y el consejo en el teléfono |
| Widget | `test/widget/habitos/recomendados_test.dart` | 8 | Recomendaciones sin fuentes, personalizado, detalle, crear con prioridad y cápsula, sin cápsula, tabaco, KZ018, escritorio con diálogo |
| Widget | `test/widget/acerca/acerca_test.dart` | 6 | Portada y secciones, rangos, fuentes con filtro por tema que se abren, sección del riel (ya no en Perfil), entrada desde el detalle del hábito, consejo del riel sin enlace, escudo del calendario |
| Golden | `componentes_golden_test`, `habitos_golden_test` | +6 | Racha por niveles, celebración del 66, recomendaciones (móvil, escritorio y su detalle), Acerca de Kaizen |
| Integración | `integration_test/*` | 5 | Las 5 en Linux (habitos ahora pasa por "Hábito personalizado") |

**Resultado:**
- **Pruebas:** 618 de 618 en verde (590 sin goldens), más las 5 de integración en Linux.
- **`flutter analyze`:** sin avisos.
- **Cobertura:** 97.6 %; ViewModels, 98.2 %.
- **Compilación:** compilan web, Linux y el APK.
- **Base de datos:** `db/cambios/run_pruebas.sh` da 229 OK (46 nuevas) y las 46 también pasan en el clúster.

## Cómo probarlo

Con `flutter run -d linux --dart-define=KAIZEN_FUENTE=fake`, como Daniela (`KaizenDemo2026!`):

1. En **Hoy**, revisa el orden: Dormir, Leer (con escudo) y Estudiar inglés arriba, y "Hechos hoy" con Ejercicio (bandera "Alta") y Tomar agua. Marca **Estudiar inglés**: baja a "Hechos hoy" y aparece la celebración de 7 días.
2. Con la ventana ancha, revisa los widgets: meta OMS, próximo hito con su curva y las 12 semanas. El **Consejo saludable** está en el riel; tócalo para abrir "Acerca de Kaizen".
3. **Nuevo hábito:** recorre las categorías, abre "Caminar a paso rápido", elige "Alta" y "30 días", y pulsa **Crear hábito**: se abre la cápsula. Prueba también **Hábito personalizado**.
4. Abre **Leer** y baja al calendario: el lunes lleva un escudo.
5. En modo avión (teléfono) o sin red, marca un hábito: el aviso "Sin conexión" aparece. Con red, marcar ya no hace parpadear el aviso.
