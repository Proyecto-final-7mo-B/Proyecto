import '../../../domain/models/logro.dart';
import '../base_local/almacen_local.dart';

/// Detecta los logros nuevos comparando con los que el usuario ya vio (tabla `marcas`, JSON), como pide el contrato
/// (§6.13: "la app detecta los nuevos comparando con su copia local").
///
/// La primera vez (instalación nueva o después de cerrar sesión) solo anota los que ya tiene, sin avisar: si no, una
/// cuenta con historia vería 6 avisos de golpe.
class NovedadesLogros {
  NovedadesLogros(this.almacen);

  static const String clave = 'logros_vistos';

  final AlmacenLocal almacen;

  /// Los obtenidos en [actuales] que aún no se habían visto, en el orden del catálogo. Los anota como vistos.
  Future<List<Logro>> revisar(List<Logro> actuales) async {
    final obtenidos = [
      for (final l in actuales)
        if (l.obtenido) l,
    ];
    final guardado = await almacen.leerJson(clave);
    final vistos = guardado is List ? {for (final c in guardado) c as String} : null;
    final nuevos = vistos == null
        ? const <Logro>[]
        : [
            for (final l in obtenidos)
              if (!vistos.contains(l.clave)) l,
          ];
    if (vistos == null || nuevos.isNotEmpty) {
      await almacen.guardarJson(clave, [...?vistos, for (final l in vistos == null ? obtenidos : nuevos) l.clave]);
    }
    return nuevos;
  }
}
