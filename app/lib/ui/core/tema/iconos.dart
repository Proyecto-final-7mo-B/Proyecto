import 'package:flutter/material.dart';

/// Íconos de línea (Material *outlined*, incluidos en Flutter) para que todo se vea como en los bosquejos.
///
/// El ícono de un hábito **se deriva de su categoría**: la API no guarda íconos (contrato v1.4, §6.3).
abstract final class KaizenIconos {
  // Navegación
  static const IconData hoy = Icons.home_outlined;
  static const IconData habitos = Icons.format_list_bulleted;
  static const IconData progreso = Icons.bar_chart_outlined;
  static const IconData laboratorio = Icons.science_outlined;
  static const IconData capsulas = Icons.hourglass_empty;
  static const IconData admin = Icons.shield_outlined;
  static const IconData perfil = Icons.person_outline;

  // Acciones y estados
  static const IconData racha = Icons.local_fire_department_outlined;
  static const IconData capsulaSellada = Icons.hourglass_empty;
  static const IconData capsulaAbierta = Icons.bolt_outlined;
  static const IconData agregar = Icons.add;
  static const IconData buscar = Icons.search;
  static const IconData cumplido = Icons.check;
  static const IconData sinConexion = Icons.cloud_off_outlined;
  static const IconData error = Icons.error_outline;
  static const IconData vacio = Icons.inbox_outlined;
  static const IconData candado = Icons.lock_outline;
  static const IconData reloj = Icons.schedule;
  static const IconData siguiente = Icons.chevron_right;
  static const IconData atras = Icons.chevron_left;
  static const IconData verContrasena = Icons.visibility_outlined;
  static const IconData ocultarContrasena = Icons.visibility_off_outlined;

  /// Ícono genérico cuando la categoría no está en el catálogo inicial (el admin puede crear nuevas).
  static const IconData categoriaGenerica = Icons.check_circle_outline;

  static const Map<String, IconData> _porCategoria = {
    'aprendizaje': Icons.translate,
    'ejercicio': Icons.fitness_center,
    'finanzas': Icons.savings_outlined,
    'hidratacion': Icons.water_drop_outlined,
    'lectura': Icons.menu_book_outlined,
    'meditacion': Icons.self_improvement,
    'salud': Icons.favorite_border,
    'sueno': Icons.bedtime_outlined,
  };

  /// Ícono para el nombre de una categoría (sin importar mayúsculas ni acentos).
  static IconData deCategoria(String nombre) => _porCategoria[normalizar(nombre)] ?? categoriaGenerica;

  /// Minúsculas, sin acentos ni espacios a los lados: "Hidratación " → "hidratacion".
  static String normalizar(String texto) {
    const conAcento = 'áéíóúüñ';
    const sinAcento = 'aeiouun';
    final buffer = StringBuffer();
    for (final rune in texto.trim().toLowerCase().runes) {
      final c = String.fromCharCode(rune);
      final i = conAcento.indexOf(c);
      buffer.write(i >= 0 ? sinAcento[i] : c);
    }
    return buffer.toString();
  }
}
