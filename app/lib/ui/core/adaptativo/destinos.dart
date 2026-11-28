import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../tema/iconos.dart';
import 'plataforma.dart';

/// Una sección de la navegación principal.
@immutable
class Destino {
  const Destino({required this.ruta, required this.etiqueta, this.icono});

  final String ruta;
  final String etiqueta;

  /// `null` = la escalera dibujada (`IconoEscalera`), que Material no trae.
  final IconData? icono;

  @override
  bool operator ==(Object other) => other is Destino && other.ruta == ruta && other.etiqueta == etiqueta;

  @override
  int get hashCode => Object.hash(ruta, etiqueta);
}

/// Destinos de la navegación según la plataforma y el rol.
///
/// - **Barra inferior** (pantallas compactas): Hoy · Hábitos · Progreso · Lab · Perfil (bosquejos móviles). La
///   Escalera y las Cápsulas se abren desde Hoy y desde el detalle de un hábito.
/// - **Riel y barra superior** (medianas y amplias): Hoy · Hábitos · Progreso · Escalera · Laboratorio · Cápsulas ·
///   Logros (Paso 11) · Acerca de (en qué se basa la app y sus fuentes; 27-nov), y Admin solo con rol admin y fuera
///   de Android/iOS. El perfil se abre con el avatar. En el teléfono, "Acerca de" se abre desde Nuevo hábito y desde
///   el detalle del hábito, y "Logros" desde la tarjeta "Último logro" de Hoy y desde Perfil.
List<Destino> destinosDe({
  required AppLocalizations t,
  required Plataforma plataforma,
  required bool esAdmin,
  required bool compacto,
}) {
  if (compacto) {
    return [
      Destino(ruta: Rutas.hoy, etiqueta: t.navHoy, icono: KaizenIconos.hoy),
      Destino(ruta: Rutas.habitos, etiqueta: t.navHabitos, icono: KaizenIconos.habitos),
      Destino(ruta: Rutas.progreso, etiqueta: t.navProgreso, icono: KaizenIconos.progreso),
      Destino(ruta: Rutas.laboratorio, etiqueta: t.navLab, icono: KaizenIconos.laboratorio),
      Destino(ruta: Rutas.perfil, etiqueta: t.navPerfil, icono: KaizenIconos.perfil),
    ];
  }
  return [
    Destino(ruta: Rutas.hoy, etiqueta: t.navHoy, icono: KaizenIconos.hoy),
    Destino(ruta: Rutas.habitos, etiqueta: t.navHabitos, icono: KaizenIconos.habitos),
    Destino(ruta: Rutas.progreso, etiqueta: t.navProgreso, icono: KaizenIconos.progreso),
    Destino(ruta: Rutas.escalera, etiqueta: t.navEscalera),
    Destino(ruta: Rutas.laboratorio, etiqueta: t.navLaboratorio, icono: KaizenIconos.laboratorio),
    Destino(ruta: Rutas.capsulas, etiqueta: t.navCapsulas, icono: KaizenIconos.capsulas),
    Destino(ruta: Rutas.logros, etiqueta: t.navLogros, icono: KaizenIconos.logros),
    Destino(ruta: Rutas.acerca, etiqueta: t.navAcerca, icono: KaizenIconos.acerca),
    if (esAdmin && plataforma.permiteAdmin) Destino(ruta: Rutas.admin, etiqueta: t.navAdmin, icono: KaizenIconos.admin),
  ];
}

/// Índice del destino que contiene [ruta] (`/habitos/123/editar` → Hábitos), o `null` si ninguno
/// (p. ej., `/perfil` en escritorio, donde el perfil no está en el riel).
int? indiceSeleccionado(List<Destino> destinos, String ruta) {
  int? mejor;
  var largo = -1;
  for (var i = 0; i < destinos.length; i++) {
    final base = destinos[i].ruta;
    if (Rutas.dentroDe(ruta, base) && base.length > largo) {
      mejor = i;
      largo = base.length;
    }
  }
  return mejor;
}
