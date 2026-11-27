import '../../l10n/gen/app_localizations.dart';
import '../../utils/fechas.dart';

/// Los consejos del widget "Consejo con evidencia" (doc. 05): uno al día, rotando, cada uno con su cita corta. La
/// novedad evita el desgaste del mensaje (F46). Los textos y sus fuentes están en `app_es.arb` (`consejoNN` y
/// `consejoCitaNN`) y salen de los documentos 01 y 03 de la investigación.
abstract final class ConsejosEvidencia {
  static const int total = 14;

  /// Índice del consejo de [dia]: avanza uno por día y da la vuelta.
  static int delDia(DateTime dia) =>
      (Fechas.soloFecha(dia).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay) % total;

  /// Texto y cita del consejo [indice].
  static ({String texto, String cita}) de(AppLocalizations t, int indice) => switch (indice % total) {
    0 => (texto: t.consejo00, cita: t.consejoCita00),
    1 => (texto: t.consejo01, cita: t.consejoCita01),
    2 => (texto: t.consejo02, cita: t.consejoCita02),
    3 => (texto: t.consejo03, cita: t.consejoCita03),
    4 => (texto: t.consejo04, cita: t.consejoCita04),
    5 => (texto: t.consejo05, cita: t.consejoCita05),
    6 => (texto: t.consejo06, cita: t.consejoCita06),
    7 => (texto: t.consejo07, cita: t.consejoCita07),
    8 => (texto: t.consejo08, cita: t.consejoCita08),
    9 => (texto: t.consejo09, cita: t.consejoCita09),
    10 => (texto: t.consejo10, cita: t.consejoCita10),
    11 => (texto: t.consejo11, cita: t.consejoCita11),
    12 => (texto: t.consejo12, cita: t.consejoCita12),
    _ => (texto: t.consejo13, cita: t.consejoCita13),
  };
}
