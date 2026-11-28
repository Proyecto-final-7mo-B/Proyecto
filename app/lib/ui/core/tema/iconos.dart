import 'package:flutter/material.dart';

/// Íconos de línea (Material *outlined*, incluidos en Flutter) para que todo se vea como en los bosquejos.
///
/// El ícono de un hábito es el de su **subcategoría**, que viene del catálogo (contrato v1.6, §6.3).
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
  static const IconData editar = Icons.edit_outlined;
  static const IconData archivar = Icons.archive_outlined;
  static const IconData reactivar = Icons.unarchive_outlined;
  static const IconData recordatorio = Icons.notifications_none;

  // Racha por niveles (doc. 05) y Hoy
  static const IconData rachaChispa = Icons.auto_awesome;
  static const IconData rachaLlena = Icons.local_fire_department;
  static const IconData rachaEmblema = Icons.military_tech;
  static const IconData protector = Icons.shield_outlined;
  static const IconData prioridadAlta = Icons.flag_outlined;
  static const IconData hito = Icons.flag;
  static const IconData consejo = Icons.lightbulb_outline;
  static const IconData actividad = Icons.directions_run;
  static const IconData constancia = Icons.grid_view;
  static const IconData acerca = Icons.info_outline;
  static const IconData logros = Icons.emoji_events_outlined;
  static const IconData rachaMaxima = Icons.emoji_events_outlined;
  static const IconData cumplimiento = Icons.task_alt;

  /// Ícono genérico cuando el nombre no está en [_porNombre] (el admin puede crear subcategorías nuevas).
  static const IconData categoriaGenerica = Icons.check_circle_outline;

  /// Nombres de Material Symbols que guarda la base (`categoria.icono`, `subcategoria.icono`, `logro.icono`) →
  /// íconos de Flutter. Desde el contrato v1.6 el ícono viene del catálogo, no se adivina por el nombre.
  static const Map<String, IconData> _porNombre = {
    // categorías
    'fitness_center': Icons.fitness_center,
    'favorite': Icons.favorite_border,
    'school': Icons.school_outlined,
    'spa': Icons.spa_outlined,
    'savings': Icons.savings_outlined,
    'category': categoriaGenerica,
    // subcategorías
    'directions_bike': Icons.directions_bike,
    'directions_run': Icons.directions_run,
    'directions_walk': Icons.directions_walk,
    'accessibility_new': Icons.accessibility_new,
    'timer': Icons.timer_outlined,
    'water_drop': Icons.water_drop_outlined,
    'bedtime': Icons.bedtime_outlined,
    'eco': Icons.eco_outlined,
    'cookie': Icons.cookie_outlined,
    'no_drinks': Icons.no_drinks_outlined,
    'smoke_free': Icons.smoke_free,
    'menu_book': Icons.menu_book_outlined,
    'edit_note': Icons.edit_note,
    'translate': Icons.translate,
    'self_improvement': Icons.self_improvement,
    'volunteer_activism': Icons.volunteer_activism_outlined,
    'phonelink_off': Icons.phonelink_off,
    'groups': Icons.groups_outlined,
    'park': Icons.park_outlined,
    'receipt_long': Icons.receipt_long_outlined,
    // logros
    'local_fire_department': Icons.local_fire_department_outlined,
    'whatshot': Icons.whatshot_outlined,
    'workspace_premium': Icons.workspace_premium_outlined,
    'military_tech': Icons.military_tech_outlined,
    'stairs': Icons.stairs_outlined,
    'verified': Icons.verified_outlined,
    'shield': Icons.shield_outlined,
    'hourglass_bottom': Icons.hourglass_bottom,
    'route': Icons.route_outlined,
  };

  /// Ícono para un nombre de Material Symbols del catálogo (genérico si no se conoce).
  static IconData porNombre(String nombre) => _porNombre[nombre] ?? categoriaGenerica;

  /// Nombres que la app sabe dibujar (para la prueba de que el catálogo no trae íconos desconocidos).
  static Iterable<String> get nombresConocidos => _porNombre.keys;

  static const Map<String, String> _iconoPorClave = {
    'aprendizaje': 'translate',
    'educacion': 'school',
    'ejercicio': 'fitness_center',
    'bienestar': 'spa',
    'finanzas': 'savings',
    'hidratacion': 'water_drop',
    'lectura': 'menu_book',
    'meditacion': 'self_improvement',
    'salud': 'favorite',
    'sueno': 'bedtime',
  };

  /// Ícono por nombre de categoría (respaldo para datos anteriores al catálogo v1.6).
  static IconData deCategoria(String nombre) {
    final icono = _iconoPorClave[normalizar(nombre)];
    return icono == null ? categoriaGenerica : porNombre(icono);
  }

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
