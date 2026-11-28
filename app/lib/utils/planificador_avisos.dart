import '../domain/models/avisos.dart';
import '../domain/models/frecuencia.dart';
import '../l10n/gen/app_localizations.dart';
import 'hitos.dart';

/// Lo que el planificador necesita saber de un hábito.
typedef HabitoAvisable = ({
  String id,
  String nombre,
  String meta,
  String? intencion,
  Frecuencia frecuencia,
  int racha,
  bool protegidaEstaSemana,
  bool hechoHoy,
  Hora? hora,
});

/// Una sugerencia pendiente de la Escalera.
typedef SugerenciaAvisable = ({String id, String habitoNombre});

/// Decide qué avisos programar en los próximos [dias] días, con las reglas del doc. 06 de la investigación:
///
/// - **Recordatorio** del hábito a la hora que eligió el usuario, solo los días que toca y, hoy, solo si sigue
///   pendiente. El texto lleva la intención (F04, F48).
/// - **Desvanecimiento:** con 66 días o más de racha, el recordatorio pasa a semanal (F01, F48).
/// - **Si se ignoran** 3 recordatorios seguidos (sin check-in en las 2 h siguientes), el hábito avisa en días
///   alternos; vuelve a diario con 3 días seguidos con check-in (F46, F49).
/// - **Racha en riesgo** (20:00 por omisión) si la racha es de 3 o más y el hábito sigue pendiente hoy (F09, F47).
/// - **Nuevo micro-paso** una sola vez por sugerencia y **resumen semanal** (domingo 18:00 por omisión).
/// - Los **automáticos** (racha en riesgo, micro-paso, resumen) respetan las **horas de silencio** y un **tope de 3
///   al día**. Lo que programó el usuario (recordatorios y "Mis avisos") siempre llega: es su decisión explícita.
/// - **Rotación:** cada tipo tiene varios textos y no se repite ninguno de los últimos 3 (F46).
class PlanificadorAvisos {
  PlanificadorAvisos(this.t);

  final AppLocalizations t;

  static const int topeAutomaticosPorDia = 3;
  static const int noRepetirUltimos = 3;
  static const Duration ventanaRespuesta = Duration(hours: 2);
  static const int ignoradosParaAlternar = 3;
  static const int checkinsParaVolver = 3;
  static const int idInicial = 70000;

  /// [historial] trae lo que ya pasó (avisos entregados y check-ins) y los micro-pasos programados que aún no llegan.
  List<AvisoProgramado> planificar({
    required DateTime ahora,
    required List<HabitoAvisable> habitos,
    required List<SugerenciaAvisable> sugerencias,
    required PreferenciasAvisos preferencias,
    required List<EventoAviso> historial,
    int dias = 7,
  }) {
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final p = preferencias;
    final rotacion = _Rotacion(historial);
    final candidatos = <_Candidato>[];

    for (var d = 0; d < dias; d++) {
      final fecha = DateTime(hoy.year, hoy.month, hoy.day + d);
      final automaticos = <_Candidato>[];

      // Recordatorios de los hábitos.
      if (p.recordatorios) {
        for (final h in habitos) {
          final hora = h.hora;
          if (hora == null || !_tocaRecordatorio(h, fecha, hoy, historial, ahora)) {
            continue;
          }
          final cuando = _en(fecha, hora);
          if (!cuando.isAfter(ahora) || (d == 0 && h.hechoHoy)) {
            continue;
          }
          candidatos.add(_Candidato(TipoAviso.recordatorio, cuando, habito: h));
        }
      }

      // "Mis avisos".
      for (final a in p.personales) {
        final cuando = _en(fecha, a.hora);
        if (a.activo && a.tocaEn(fecha) && cuando.isAfter(ahora)) {
          candidatos.add(_Candidato(TipoAviso.personal, cuando, personal: a));
        }
      }

      // Racha en riesgo: solo hoy (mañana todavía no se sabe).
      if (d == 0 && p.rachaEnRiesgo) {
        final cuando = _en(fecha, p.horaRachaEnRiesgo);
        if (cuando.isAfter(ahora)) {
          final enRiesgo = [
            for (final h in habitos)
              if (h.racha >= 3 && !h.hechoHoy && _tocaHoy(h, fecha)) h,
          ]..sort((a, b) => b.racha.compareTo(a.racha));
          for (final h in enRiesgo) {
            automaticos.add(_Candidato(TipoAviso.rachaEnRiesgo, cuando, habito: h));
          }
        }
      }

      // Nuevo micro-paso: una vez por sugerencia, lo antes posible fuera del silencio. Si ya estaba programado y aún
      // no llega, se conserva su hora (replanificar no lo pospone ni lo pierde).
      if (d == 0 && p.microPaso) {
        final avisadas = {
          for (final e in historial)
            if (e.sugerenciaId != null) e.sugerenciaId!: e.cuando,
        };
        for (final s in sugerencias) {
          final previo = avisadas[s.id];
          if (previo != null && !previo.isAfter(ahora)) {
            continue;
          }
          final cuando = previo ?? _primerMomentoLibre(ahora.add(const Duration(minutes: 1)), p);
          automaticos.add(_Candidato(TipoAviso.microPaso, cuando, sugerencia: s));
        }
      }

      // Resumen semanal.
      if (p.resumenSemanal && fecha.weekday == p.diaResumen) {
        final cuando = _en(fecha, p.horaResumen);
        if (cuando.isAfter(ahora)) {
          automaticos.add(_Candidato(TipoAviso.resumenSemanal, cuando));
        }
      }

      // Automáticos: fuera del silencio y como mucho 3 al día (racha en riesgo, micro-paso y resumen, en ese orden).
      final delDia = [
        for (final c in automaticos)
          if (!p.enSilencio((hora: c.cuando.hour, minuto: c.cuando.minute))) c,
      ];
      candidatos.addAll(delDia.take(topeAutomaticosPorDia));
    }

    candidatos.sort((a, b) => a.cuando.compareTo(b.cuando));
    return [for (var i = 0; i < candidatos.length; i++) _construir(candidatos[i], idInicial + i, rotacion)];
  }

  // ───────────────────────── Reglas de los recordatorios ─────────────────────────

  static DateTime _en(DateTime fecha, Hora h) => DateTime(fecha.year, fecha.month, fecha.day, h.hora, h.minuto);

  /// "N por semana" se puede hacer cualquier día: se le recuerda a diario.
  static bool _tocaHoy(HabitoAvisable h, DateTime fecha) =>
      h.frecuencia is NPorSemana || h.frecuencia.programadoEn(fecha);

  /// Desvanecimiento (≥ 66 días: semanal) y modo de días alternos (si se ignoran).
  static bool _tocaRecordatorio(
    HabitoAvisable h,
    DateTime fecha,
    DateTime hoy,
    List<EventoAviso> historial,
    DateTime ahora,
  ) {
    if (!_tocaHoy(h, fecha)) {
      return false;
    }
    if (h.racha >= Hitos.habitoFormado) {
      return fecha.weekday == _primerDiaDeLaSemana(h.frecuencia);
    }
    if (modoAlterno(h.id, historial, ahora)) {
      // Uno sí y uno no, contando los días que tocan desde hoy.
      var indice = 0;
      for (
        var d = DateTime(hoy.year, hoy.month, hoy.day);
        d.isBefore(fecha);
        d = DateTime(d.year, d.month, d.day + 1)
      ) {
        if (_tocaHoy(h, d)) {
          indice++;
        }
      }
      return indice.isEven;
    }
    return true;
  }

  /// El primer día de la semana (1 = lunes) en que toca el hábito; el día del recordatorio semanal.
  static int _primerDiaDeLaSemana(Frecuencia f) => switch (f) {
    DiasSemana(:final dias) => dias.isEmpty ? DateTime.monday : dias.reduce((a, b) => a < b ? a : b),
    _ => DateTime.monday,
  };

  /// `true` si el hábito avisa en días alternos: 3 recordatorios seguidos sin check-in en las 2 h siguientes. Vuelve a
  /// diario cuando, después de eso, hay 3 días seguidos con check-in.
  static bool modoAlterno(String habitoId, List<EventoAviso> historial, DateTime ahora) {
    final checkins = [
      for (final e in historial)
        if (e.esCheckin && e.habitoId == habitoId) e.cuando,
    ];
    final recordatorios = [
      for (final e in historial)
        if (e.tipo == TipoAviso.recordatorio &&
            e.habitoId == habitoId &&
            !e.cuando.add(ventanaRespuesta).isAfter(ahora))
          e.cuando,
    ]..sort();
    var ignoradosSeguidos = 0;
    DateTime? desde;
    for (final t in recordatorios) {
      final respondido = checkins.any((c) => !c.isBefore(t) && !c.isAfter(t.add(ventanaRespuesta)));
      ignoradosSeguidos = respondido ? 0 : ignoradosSeguidos + 1;
      if (ignoradosSeguidos >= ignoradosParaAlternar) {
        desde = t;
      }
    }
    if (desde == null) {
      return false;
    }
    // ¿3 días seguidos con check-in después de pasar a días alternos?
    final dias = {
      for (final c in checkins)
        if (c.isAfter(desde)) DateTime(c.year, c.month, c.day),
    }.toList()..sort();
    var seguidos = 0;
    for (var i = 0; i < dias.length; i++) {
      seguidos = i > 0 && dias[i].difference(dias[i - 1]).inDays == 1 ? seguidos + 1 : 1;
      if (seguidos >= checkinsParaVolver) {
        return false;
      }
    }
    return true;
  }

  /// [desde] o, si cae en silencio, el final del silencio.
  static DateTime _primerMomentoLibre(DateTime desde, PreferenciasAvisos p) {
    if (!p.enSilencio((hora: desde.hour, minuto: desde.minute))) {
      return desde;
    }
    var fin = DateTime(desde.year, desde.month, desde.day, p.silencioHasta.hora, p.silencioHasta.minuto);
    if (!fin.isAfter(desde)) {
      fin = DateTime(fin.year, fin.month, fin.day + 1, fin.hour, fin.minute);
    }
    return fin;
  }

  // ───────────────────────── Textos ─────────────────────────

  AvisoProgramado _construir(_Candidato c, int id, _Rotacion rotacion) {
    final h = c.habito;
    switch (c.tipo) {
      case TipoAviso.recordatorio:
        final textos = [
          t.avisoRecordatorio0,
          t.avisoRecordatorio1,
          t.avisoRecordatorio2,
          t.avisoRecordatorio3,
          t.avisoRecordatorio4,
          t.avisoRecordatorio5,
        ]; // fmt: skip
        final i = rotacion.siguiente(c.tipo, textos.length);
        return AvisoProgramado(
          id: id,
          cuando: c.cuando,
          tipo: c.tipo,
          habitoId: h!.id,
          plantilla: i,
          titulo: h.nombre,
          cuerpo: textos[i](h.intencion ?? t.avisoBuenMomento, h.nombre, h.meta),
        );
      case TipoAviso.rachaEnRiesgo:
        final textos = [t.avisoRiesgo0, t.avisoRiesgo1, t.avisoRiesgo2, t.avisoRiesgo3, t.avisoRiesgo4, t.avisoRiesgo5];
        final i = rotacion.siguiente(c.tipo, textos.length);
        final cuerpo = textos[i]('${h!.racha}', '${h.racha + 1}', h.nombre, h.meta);
        return AvisoProgramado(
          id: id,
          cuando: c.cuando,
          tipo: c.tipo,
          habitoId: h.id,
          plantilla: i,
          titulo: t.avisoRiesgoTitulo('${h.racha}'),
          cuerpo: h.protegidaEstaSemana ? cuerpo : '$cuerpo${t.avisoRiesgoProtector}',
        );
      case TipoAviso.microPaso:
        final textos = [t.avisoMicroPaso0, t.avisoMicroPaso1, t.avisoMicroPaso2, t.avisoMicroPaso3];
        final i = rotacion.siguiente(c.tipo, textos.length);
        return AvisoProgramado(
          id: id,
          cuando: c.cuando,
          tipo: c.tipo,
          plantilla: i,
          sugerenciaId: c.sugerencia!.id,
          titulo: t.avisoMicroPasoTitulo,
          cuerpo: textos[i](c.sugerencia!.habitoNombre),
        );
      case TipoAviso.resumenSemanal:
        final textos = [
          t.avisoResumen0,
          t.avisoResumen1,
          t.avisoResumen2,
          t.avisoResumen3,
          t.avisoResumen4,
          t.avisoResumen5,
        ];
        final i = rotacion.siguiente(c.tipo, textos.length);
        return AvisoProgramado(
          id: id,
          cuando: c.cuando,
          tipo: c.tipo,
          plantilla: i,
          titulo: t.avisoResumenTitulo,
          cuerpo: textos[i],
        );
      case TipoAviso.personal:
        final a = c.personal!;
        return AvisoProgramado(
          id: id,
          cuando: c.cuando,
          tipo: c.tipo,
          titulo: t.avisoPersonalTitulo,
          cuerpo: a.texto.trim().isEmpty ? t.avisoPersonalTexto : a.texto.trim(),
        );
    }
  }
}

class _Candidato {
  _Candidato(this.tipo, this.cuando, {this.habito, this.personal, this.sugerencia});

  final TipoAviso tipo;
  final DateTime cuando;
  final HabitoAvisable? habito;
  final AvisoPersonal? personal;
  final SugerenciaAvisable? sugerencia;
}

/// Elige el texto de cada tipo sin repetir ninguno de los últimos [PlanificadorAvisos.noRepetirUltimos].
class _Rotacion {
  _Rotacion(List<EventoAviso> historial) {
    final ordenados = [...historial.where((e) => e.tipo != null && e.plantilla != null)]
      ..sort((a, b) => a.cuando.compareTo(b.cuando));
    for (final e in ordenados) {
      (_usadas[e.tipo!] ??= []).add(e.plantilla!);
    }
  }

  final Map<TipoAviso, List<int>> _usadas = {};

  int siguiente(TipoAviso tipo, int cuantas) {
    final usadas = _usadas[tipo] ??= [];
    final recientes = usadas.length <= PlanificadorAvisos.noRepetirUltimos
        ? usadas.toSet()
        : usadas.sublist(usadas.length - PlanificadorAvisos.noRepetirUltimos).toSet();
    final inicio = usadas.isEmpty ? 0 : (usadas.last + 1) % cuantas;
    var elegida = inicio;
    for (var k = 0; k < cuantas; k++) {
      final i = (inicio + k) % cuantas;
      if (!recientes.contains(i)) {
        elegida = i;
        break;
      }
    }
    usadas.add(elegida);
    return elegida;
  }
}
