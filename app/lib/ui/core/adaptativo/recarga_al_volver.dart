import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Recarga una pantalla cada vez que su ruta **vuelve** a ser la actual.
///
/// go_router reutiliza la pantalla que quedó abajo en la pila: al regresar (con "‹", con el riel o con la barra
/// inferior) no se vuelve a crear y sus datos quedarían viejos. Por ejemplo, archivar un hábito desde su detalle y
/// tocar "Hoy" en el riel mostraba todavía el "N de M" anterior.
mixin RecargaAlVolver<T extends StatefulWidget> on State<T> {
  /// La ruta de esta pantalla (`/hoy`, `/habitos/123`).
  String get rutaPropia;

  /// Qué hacer al volver.
  Future<void> recargarAlVolver();

  GoRouterDelegate? _delegado;
  String? _ultima;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegado = GoRouter.maybeOf(context)?.routerDelegate;
    if (!identical(delegado, _delegado)) {
      _delegado?.removeListener(_alCambiarRuta);
      _delegado = delegado?..addListener(_alCambiarRuta);
      _ultima = _rutaActual;
    }
  }

  /// La ruta que se ve. Con `push`, `currentConfiguration.uri` sigue siendo la de abajo: la de arriba es la
  /// `matchedLocation` de la última coincidencia.
  String? get _rutaActual {
    final configuracion = _delegado?.currentConfiguration;
    return configuracion == null || configuracion.isEmpty ? null : configuracion.last.matchedLocation;
  }

  void _alCambiarRuta() {
    final actual = _rutaActual;
    final volvio = actual == rutaPropia && _ultima != rutaPropia;
    _ultima = actual;
    if (volvio && mounted) {
      recargarAlVolver();
    }
  }

  @override
  void dispose() {
    _delegado?.removeListener(_alCambiarRuta);
    super.dispose();
  }
}
