import '../../domain/models/frecuencia.dart';
import '../../domain/models/habito.dart';
import '../../l10n/gen/app_localizations.dart';
import '../core/widgets/contador_meta.dart';

/// Formatos de texto que comparten varias pantallas.

/// "2", "8.5", "16.5" (sin ".0"), como en el contador de la meta.
String numero(num n) => ContadorMeta.formatoNumero(n);

/// Iniciales de los días para una máscara que no es L-V ni S-D: "L, Mi, V".
const List<String> _dias = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

/// "diario", "L-V", "S-D", "L, Mi, V" o "3 por semana".
String textoFrecuencia(Frecuencia f, AppLocalizations t) => switch (f) {
  Diaria() => t.frecuenciaDiaria,
  DiasSemana(mascara: 127) => t.frecuenciaDiaria,
  DiasSemana(mascara: DiasSemana.lunesAViernes) => t.frecuenciaLaV,
  DiasSemana(mascara: 96) => t.frecuenciaFinDeSemana,
  DiasSemana(:final dias) => [for (final d in dias) _dias[d - 1]].join(', '),
  NPorSemana(:final veces) => t.frecuenciaVeces(veces),
};

/// Subtítulo de un hábito como en el bosquejo de Hoy: "2 L · diario", "20 min · L-V" y, si ya subió de nivel con la
/// Escalera, "10 min · Nivel 3".
String subtituloHabito(Habito h, AppLocalizations t) {
  final meta = '${numero(h.meta)} ${h.unidad}';
  return h.nivel > 1 ? '$meta · ${t.nivelN(h.nivel)}' : '$meta · ${textoFrecuencia(h.frecuencia, t)}';
}

/// Saludo según la hora: días (5–12), tardes (12–19), noches.
String saludo(DateTime ahora, String nombre, AppLocalizations t) {
  final primerNombre = nombre.trim().split(RegExp(r'\s+')).first;
  final h = ahora.hour;
  if (h >= 5 && h < 12) {
    return t.saludoManana(primerNombre);
  }
  return h >= 12 && h < 19 ? t.saludoTarde(primerNombre) : t.saludoNoche(primerNombre);
}
