import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../utils/hitos.dart';
import 'tema/colores.dart';
import 'tema/iconos.dart';

/// Cómo se ve cada nivel de racha (colores del doc. 04, niveles del doc. 05). La calidez, la saturación y el tamaño
/// crecen con la racha (F42); ningún nivel usa el rojo de error (F40).
extension AparienciaRacha on NivelRacha {
  Color get color => switch (this) {
    NivelRacha.sinRacha => KaizenColores.rachaSinRacha,
    NivelRacha.chispa => KaizenColores.rachaChispa,
    NivelRacha.llama => KaizenColores.naranjaRacha,
    NivelRacha.llamaConAro => KaizenColores.rachaProfunda,
    NivelRacha.formado || NivelRacha.emblema => KaizenColores.rachaDorada,
  };

  IconData get icono => switch (this) {
    NivelRacha.sinRacha || NivelRacha.llama => KaizenIconos.racha,
    NivelRacha.chispa => KaizenIconos.rachaChispa,
    NivelRacha.llamaConAro || NivelRacha.formado => KaizenIconos.rachaLlena,
    NivelRacha.emblema => KaizenIconos.rachaEmblema,
  };

  /// Factor de tamaño del símbolo: "también cambia de tamaño" (doc. 05).
  double get escala => switch (this) {
    NivelRacha.sinRacha || NivelRacha.chispa => 0.9,
    NivelRacha.llama => 1,
    NivelRacha.llamaConAro => 1.1,
    NivelRacha.formado => 1.15,
    NivelRacha.emblema => 1.2,
  };

  /// Desde 30 días el símbolo va dentro de un aro; en el emblema, el aro es marino (los dos colores de la identidad).
  Color? get colorAro => switch (this) {
    NivelRacha.llamaConAro || NivelRacha.formado => color,
    NivelRacha.emblema => KaizenColores.marino800,
    _ => null,
  };

  /// Nombre del nivel para la lectura de pantalla; `null` en los niveles que no necesitan explicación.
  String? nombre(AppLocalizations t) => switch (this) {
    NivelRacha.formado => t.nivelRachaFormado,
    NivelRacha.emblema => t.nivelRachaEmblema,
    _ => null,
  };
}
