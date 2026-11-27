import 'package:flutter/painting.dart';

/// Paleta de Kaizen (solo tema claro). La estructura se midió con cuentagotas sobre los bosquejos de Figma
/// (`Escritorio 02 Inicio`, `Escritorio 08 Cápsula`, `Móvil 03 Crear hábito`, `Web 01 Login`); los tokens de progreso,
/// bienestar y racha por niveles salen de la investigación de color (`12_investigacion_cientifica/04_colores.md`), con
/// su contraste WCAG medido en `test/unit/tema/contraste_test.dart`.
///
/// Regla: ninguna pantalla escribe un `Color(0x…)` propio; todo sale de aquí o del `ColorScheme` del tema.
abstract final class KaizenColores {
  // Marinos
  /// Riel lateral, barra de título y texto principal.
  static const Color marino900 = Color(0xFF121A3A);

  /// **Primario**: tarjeta "2 de 5", botones principales, check cumplido, chip seleccionado.
  static const Color marino800 = Color(0xFF1B2A5E);

  /// Pista de una barra de progreso que va sobre `marino800`.
  static const Color marino700 = Color(0xFF3A4A82);

  // Azules
  /// Destino activo del riel y enlaces ("Editar", textos de ayuda).
  static const Color azul600 = Color(0xFF2F4A9A);

  /// Intensidad media (calendario, semana).
  static const Color azul400 = Color(0xFF7F9BE0);

  /// Intensidad baja y barras secundarias de las gráficas.
  static const Color azul200 = Color(0xFFC3D1F0);

  /// Tarjeta de sugerencia, fondo del ícono de hábito, selector segmentado.
  static const Color azul100 = Color(0xFFE4EAF8);

  /// Día sin registro en el calendario y pista clara de las barras.
  static const Color azul50 = Color(0xFFEEF1F9);

  /// Texto secundario sobre `marino800` ("Escrita el 12 de octubre · Guardada cifrada").
  static const Color textoSobreMarino = Color(0xFFAEBCDE);

  // Neutros
  /// Fondo de todas las pantallas.
  static const Color fondo = Color(0xFFF7F8FB);

  /// Tarjetas y campos.
  static const Color superficie = Color(0xFFFFFFFF);

  /// Borde de las tarjetas.
  static const Color borde = Color(0xFFEEF0F6);

  /// Borde de campos, chips y botones secundarios.
  static const Color bordeCampo = Color(0xFFE4E8F1);

  /// Borde de controles sin marcar (círculo del check-in).
  static const Color bordeControl = Color(0xFFC9D1E3);

  /// Texto principal.
  static const Color texto = marino900;

  /// Subtítulos ("2 L · diario", fechas).
  static const Color textoSecundario = Color(0xFF606882);

  // Acentos
  /// **Acento de racha** (nivel 7–29 días): llama y número de racha, reloj de arena, botón "Abrir", estado
  /// "Suspendido".
  static const Color naranjaRacha = Color(0xFFC2410C);

  // Racha por niveles (doc. 04 y 05): la calidez y la saturación crecen con la racha (F42). Nunca el rojo de error.
  /// 0 días: neutro, sin mensaje de falla (F09, F40). 4.83:1.
  static const Color rachaSinRacha = Color(0xFF6B7280);

  /// 1–6 días: chispa ámbar. 5.02:1.
  static const Color rachaChispa = Color(0xFFB45309);

  /// 30–65 días: llama naranja profundo con aro. 7.31:1.
  static const Color rachaProfunda = Color(0xFF9A3412);

  /// 66 días o más: "hábito formado", dorado (asociación cultural con el logro; confianza baja). 4.92:1.
  static const Color rachaDorada = Color(0xFFA16207);

  /// Rayo de la cápsula abierta y anillo de progreso de la cápsula.
  static const Color naranjaClaro = Color(0xFFF0763F);

  /// Fondo de un aviso ("La foto solo se agrega desde Android…").
  static const Color avisoFondo = Color(0xFFFFF4DB);

  /// Texto de un aviso.
  static const Color avisoTexto = Color(0xFF7A4F00);

  /// Errores de formulario (Material 3).
  static const Color error = Color(0xFFB3261E);

  /// Fondo del ícono del estado de error.
  static const Color errorFondo = Color(0xFFFBE9E7);

  // Progreso y bienestar (doc. 04)
  /// Checks hechos, barras de avance, "N de M", "Ritmo ideal": verde esmeralda (emociones positivas y logro,
  /// F42/F44). 5.48:1 sobre blanco. El rojo queda solo para errores.
  static const Color verdeProgreso = Color(0xFF047857);

  /// Fondo de "Hechos hoy" y de las tarjetas de logro (brillo alto, saturación baja: calma). Ícono encima: 4.63:1.
  static const Color verdeProgresoFondo = Color(0xFFE1EFEB);

  /// Barra de avance **sobre la tarjeta marino** ("2 de 5"): el mismo esmeralda, más claro, porque `verdeProgreso`
  /// sobre marino solo da 2.49:1. 7.10:1 contra `marino800` y 4.40:1 contra su pista `marino700`.
  static const Color verdeProgresoSobreMarino = Color(0xFF34D399);

  /// Bienestar, Laboratorio y señal del día: azul-verde, el tono que mejor combina agrado y baja activación (F42).
  /// 5.47:1 sobre blanco.
  static const Color tealBienestar = Color(0xFF0F766E);

  /// El mismo teal, claro, para íconos **sobre el riel marino** (consejo saludable). 9.22:1 contra `marino800`.
  static const Color tealSobreMarino = Color(0xFF5EEAD4);

  /// Color de una categoría a partir de su hex del catálogo (`#D9480F`). Si el texto no es válido, el marino.
  static Color deHex(String hex) {
    final limpio = hex.replaceFirst('#', '');
    final valor = limpio.length == 6 ? int.tryParse(limpio, radix: 16) : null;
    return valor == null ? marino800 : Color(0xFF000000 | valor);
  }

  /// Fondo del ícono de una categoría: su color al 12 % sobre blanco (contraste del ícono ≥ 3:1, doc. 04).
  static Color fondoDe(Color color) => Color.lerp(superficie, color, 0.12)!;

  /// Escala de intensidad 0 → 4 del calendario y del mapa de calor (sin registro → meta completa). Es azul y no
  /// verde a propósito: la intensidad se lee por brillo (F42), y el verde queda para "hecho".
  static const List<Color> intensidad = [azul50, azul200, azul400, azul600, marino800];

  /// Color de la escala para un nivel; fuera de rango se recorta a 0–4.
  static Color deIntensidad(int nivel) => intensidad[nivel.clamp(0, intensidad.length - 1)];

  /// Texto legible sobre un nivel de la escala (blanco sobre los dos niveles oscuros).
  static Color textoSobreIntensidad(int nivel) => nivel.clamp(0, 4) >= 3 ? superficie : texto;

  /// Series de las gráficas: principal, secundarias y resaltado.
  static const List<Color> series = [marino800, azul400, azul200, naranjaRacha];
}
