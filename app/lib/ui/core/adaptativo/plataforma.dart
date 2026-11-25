import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Dónde corre la app. Decide qué destinos existen (admin no existe en móvil) y qué *shell* se usa.
enum Plataforma {
  /// Android e iOS.
  movil,

  /// Linux, Windows y macOS.
  escritorio,

  /// Navegador.
  web;

  /// La plataforma real. En pruebas se pasa una explícita.
  static Plataforma actual() => desde(esWeb: kIsWeb, sistema: defaultTargetPlatform);

  static Plataforma desde({required bool esWeb, required TargetPlatform sistema}) {
    if (esWeb) {
      return Plataforma.web;
    }
    return switch (sistema) {
      TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia => Plataforma.movil,
      TargetPlatform.linux || TargetPlatform.windows || TargetPlatform.macOS => Plataforma.escritorio,
    };
  }

  /// El panel de administración solo existe en escritorio y web (bosquejos 09 y 10).
  bool get permiteAdmin => this != Plataforma.movil;

  /// Atajo Ctrl+K (⌘K en Mac) para buscar.
  bool get tieneTeclado => this != Plataforma.movil;
}

/// Hace disponible la [Plataforma] para toda la app (las pruebas la fijan aquí).
class PlataformaApp extends InheritedWidget {
  const PlataformaApp({required this.plataforma, required super.child, super.key});

  final Plataforma plataforma;

  /// La plataforma más cercana; si no hay `PlataformaApp` arriba, la real.
  static Plataforma de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlataformaApp>()?.plataforma ?? Plataforma.actual();

  @override
  bool updateShouldNotify(PlataformaApp oldWidget) => oldWidget.plataforma != plataforma;
}
