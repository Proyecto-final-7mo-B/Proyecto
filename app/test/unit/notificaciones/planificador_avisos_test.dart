import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/domain/models/avisos.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/l10n/gen/app_localizations.dart';
import 'package:kaizen/utils/planificador_avisos.dart';

/// Viernes 27-nov-2026, 10:00.
final DateTime _ahora = DateTime(2026, 11, 27, 10);

HabitoAvisable _h({
  String id = 'h1',
  String nombre = 'Leer',
  String? intencion = 'Después de cenar',
  Frecuencia frecuencia = const Diaria(),
  int racha = 0,
  bool protegida = false,
  bool hecho = false,
  Hora? hora = (hora: 21, minuto: 0),
}) => (
  id: id,
  nombre: nombre,
  meta: '10 páginas',
  intencion: intencion,
  frecuencia: frecuencia,
  racha: racha,
  protegidaEstaSemana: protegida,
  hechoHoy: hecho,
  hora: hora,
);

void main() {
  final t = lookupAppLocalizations(const Locale('es'));
  final planificador = PlanificadorAvisos(t);

  /// Solo recordatorios y "Mis avisos", salvo que la prueba pida otra cosa.
  const soloRecordatorios = PreferenciasAvisos(rachaEnRiesgo: false, microPaso: false, resumenSemanal: false);

  List<AvisoProgramado> planear({
    List<HabitoAvisable> habitos = const [],
    List<SugerenciaAvisable> sugerencias = const [],
    PreferenciasAvisos preferencias = soloRecordatorios,
    List<EventoAviso> historial = const [],
    DateTime? ahora,
  }) => planificador.planificar(
    ahora: ahora ?? _ahora,
    habitos: habitos,
    sugerencias: sugerencias,
    preferencias: preferencias,
    historial: historial,
  );

  List<int> diasDe(List<AvisoProgramado> avisos) => [for (final a in avisos) a.cuando.day];

  group('recordatorios', () {
    test('a la hora elegida, 7 días, con la intención en el texto', () {
      final r = planear(habitos: [_h()]);
      expect(diasDe(r), [27, 28, 29, 30, 1, 2, 3]);
      expect(r.every((a) => a.cuando.hour == 21 && a.tipo == TipoAviso.recordatorio && a.habitoId == 'h1'), isTrue);
      expect(r.first.titulo, 'Leer');
      expect(r.first.cuerpo, contains('Después de cenar'));
    });

    test('hoy no llega si ya se hizo o si ya pasó la hora', () {
      expect(diasDe(planear(habitos: [_h(hecho: true)])).first, 28);
      expect(diasDe(planear(habitos: [_h(hora: (hora: 9, minuto: 0))])).first, 28);
    });

    test('sin hora o con los recordatorios apagados, nada', () {
      expect(planear(habitos: [_h(hora: null)]), isEmpty);
      expect(planear(habitos: [_h()], preferencias: soloRecordatorios.copyWith(recordatorios: false)), isEmpty);
    });

    test('solo los días que toca; "N por semana" cuenta como diario', () {
      final lmv = DiasSemana(DiasSemana.mascaraDe([1, 3, 5]));
      // Vie 27, lun 30, mié 2.
      expect(diasDe(planear(habitos: [_h(frecuencia: lmv)])), [27, 30, 2]);
      expect(planear(habitos: [_h(frecuencia: const NPorSemana(3))]), hasLength(7));
    });

    test('sin intención usa "Es buen momento"', () {
      expect(planear(habitos: [_h(intencion: null)]).map((a) => a.cuerpo).join(), contains(t.avisoBuenMomento));
    });

    test('desvanecimiento: con 66 días de racha, uno por semana (el primer día que toca)', () {
      final r = planear(habitos: [_h(racha: 66)]);
      expect(diasDe(r), [30], reason: 'diario: el lunes');
      final mv = DiasSemana(DiasSemana.mascaraDe([3, 5]));
      expect(diasDe(planear(habitos: [_h(racha: 70, frecuencia: mv)])), [2], reason: 'el miércoles');
    });

    test('3 recordatorios ignorados: días alternos; 3 días seguidos con check-in: vuelve a diario', () {
      final ignorados = [
        for (final d in [24, 25, 26])
          EventoAviso(cuando: DateTime(2026, 11, d, 21), tipo: TipoAviso.recordatorio, habitoId: 'h1', plantilla: 0),
      ];
      expect(PlanificadorAvisos.modoAlterno('h1', ignorados, _ahora), isTrue);
      expect(PlanificadorAvisos.modoAlterno('h2', ignorados, _ahora), isFalse);
      expect(diasDe(planear(habitos: [_h()], historial: ignorados)), [27, 29, 1, 3]);

      // Respondió uno (check-in en las 2 h siguientes): ya no son 3 seguidos.
      final respondido = [...ignorados, EventoAviso.checkin(cuando: DateTime(2026, 11, 25, 22), habitoId: 'h1')];
      expect(PlanificadorAvisos.modoAlterno('h1', respondido, _ahora), isFalse);

      // Después, 3 días seguidos con check-in.
      final volvio = [
        ...ignorados,
        for (final d in [27, 28, 29]) EventoAviso.checkin(cuando: DateTime(2026, 11, d, 8), habitoId: 'h1'),
      ];
      expect(PlanificadorAvisos.modoAlterno('h1', volvio, DateTime(2026, 11, 29, 12)), isFalse);
      final dosDias = volvio.sublist(0, volvio.length - 1);
      expect(PlanificadorAvisos.modoAlterno('h1', dosDias, DateTime(2026, 11, 29, 12)), isTrue);
    });

    test('un recordatorio de hace menos de 2 h aún no cuenta como ignorado', () {
      final historial = [
        for (final d in [25, 26])
          EventoAviso(cuando: DateTime(2026, 11, d, 21), tipo: TipoAviso.recordatorio, habitoId: 'h1', plantilla: 0),
        EventoAviso(cuando: DateTime(2026, 11, 27, 9), tipo: TipoAviso.recordatorio, habitoId: 'h1', plantilla: 0),
      ];
      expect(PlanificadorAvisos.modoAlterno('h1', historial, _ahora), isFalse);
      expect(PlanificadorAvisos.modoAlterno('h1', historial, DateTime(2026, 11, 27, 11, 1)), isTrue);
    });

    test('los textos rotan y no se repite ninguno de los últimos 3', () {
      final historial = [
        for (final (i, p) in [0, 1, 2].indexed)
          EventoAviso(
            cuando: DateTime(2026, 11, 20 + i, 21),
            tipo: TipoAviso.recordatorio,
            habitoId: 'h1',
            plantilla: p,
          ),
      ];
      final r = planear(habitos: [_h()], historial: historial);
      final usadas = [0, 1, 2, for (final a in r) a.plantilla];
      expect(usadas[3], 3);
      for (var i = 3; i < usadas.length; i++) {
        expect(usadas.sublist(i - 3, i), isNot(contains(usadas[i])), reason: 'posición $i: $usadas');
      }
    });
  });

  group('mis avisos', () {
    test('a cualquier hora y los días elegidos; siempre llegan (sin silencio ni tope)', () {
      final p = soloRecordatorios.copyWith(
        personales: [
          const AvisoPersonal(id: 'a', hora: (hora: 22, minuto: 20), dias: 127, texto: '  Prepara la mochila '),
          // Sábado y domingo.
          const AvisoPersonal(id: 'b', hora: (hora: 9, minuto: 35), dias: 32 | 64, texto: ''),
          const AvisoPersonal(id: 'c', hora: (hora: 12, minuto: 0), dias: 127, texto: 'x', activo: false),
        ],
      );
      final r = planear(preferencias: p);
      final a = r.where((x) => x.cuerpo == 'Prepara la mochila').toList();
      expect(a, hasLength(7), reason: '22:20 está en silencio, pero lo programó el usuario');
      expect((a.first.cuando.hour, a.first.cuando.minute), (22, 20));
      final b = r.where((x) => x.cuerpo == t.avisoPersonalTexto).toList();
      expect(diasDe(b), [28, 29]);
      expect((b.first.cuando.hour, b.first.cuando.minute), (9, 35));
      expect(r.any((x) => x.cuerpo == 'x'), isFalse);
      expect(r.every((x) => x.tipo == TipoAviso.personal && x.titulo == t.avisoPersonalTitulo), isTrue);
    });

    test('hoy, solo si la hora aún no pasa', () {
      final p = soloRecordatorios.copyWith(
        personales: [const AvisoPersonal(id: 'a', hora: (hora: 9, minuto: 59), dias: 127, texto: 'x')],
      );
      expect(diasDe(planear(preferencias: p)).first, 28);
    });

    test('máscara de días y JSON', () {
      const a = AvisoPersonal(id: 'a', hora: (hora: 7, minuto: 5), dias: 1 | 16, texto: 'hola');
      expect(a.tocaEn(DateTime(2026, 11, 30)), isTrue, reason: 'lunes');
      expect(a.tocaEn(DateTime(2026, 11, 27)), isTrue, reason: 'viernes');
      expect(a.tocaEn(DateTime(2026, 11, 28)), isFalse);
      final b = AvisoPersonal.fromJson(a.toJson());
      expect((b.id, b.hora, b.dias, b.texto, b.activo), ('a', (hora: 7, minuto: 5), 17, 'hola', true));
      expect(formatoHoraAviso(a.hora), '07:05');
    });
  });

  group('automáticos', () {
    const todos = PreferenciasAvisos();

    test('racha en riesgo: 20:00, racha de 3 o más, pendiente y programado hoy', () {
      final r = planear(
        preferencias: todos.copyWith(resumenSemanal: false),
        habitos: [
          _h(racha: 5, hora: null),
          _h(id: 'h2', nombre: 'Agua', racha: 2, hora: null),
          _h(id: 'h3', nombre: 'Correr', racha: 9, hecho: true, hora: null),
          _h(id: 'h4', nombre: 'Yoga', racha: 9, hora: null, frecuencia: DiasSemana(DiasSemana.mascaraDe([1]))),
        ],
      );
      expect(r, hasLength(1));
      expect(r.single.tipo, TipoAviso.rachaEnRiesgo);
      expect((r.single.cuando.day, r.single.cuando.hour), (27, 20));
      expect(r.single.titulo, t.avisoRiesgoTitulo('5'));
      expect(r.single.cuerpo, endsWith(t.avisoRiesgoProtector), reason: 'el protector aún no se usó esta semana');
    });

    test('racha en riesgo: sin la frase del protector si ya se usó; hora configurable', () {
      final r = planear(
        preferencias: todos.copyWith(resumenSemanal: false, horaRachaEnRiesgo: (hora: 19, minuto: 30)),
        habitos: [_h(racha: 5, protegida: true, hora: null)],
      );
      expect(r.single.cuerpo, isNot(contains(t.avisoRiesgoProtector)));
      expect((r.single.cuando.hour, r.single.cuando.minute), (19, 30));
    });

    test('tope de 3 automáticos al día (los recordatorios no cuentan)', () {
      final r = planear(
        preferencias: todos.copyWith(resumenSemanal: false),
        habitos: [for (var i = 0; i < 5; i++) _h(id: 'h$i', nombre: 'H$i', racha: 3 + i)],
      );
      final riesgo = r.where((a) => a.tipo == TipoAviso.rachaEnRiesgo).toList();
      expect(riesgo, hasLength(PlanificadorAvisos.topeAutomaticosPorDia));
      expect([for (final a in riesgo) a.habitoId], ['h4', 'h3', 'h2'], reason: 'primero las rachas más largas');
      expect(r.where((a) => a.tipo == TipoAviso.recordatorio), hasLength(35));
    });

    test('horas de silencio: los automáticos no salen', () {
      final r = planear(
        preferencias: todos.copyWith(
          resumenSemanal: false,
          silencioDesde: (hora: 19, minuto: 0),
          silencioHasta: (hora: 7, minuto: 0),
        ),
        habitos: [_h(racha: 5, hora: null)],
      );
      expect(r, isEmpty);
    });

    test('nuevo micro-paso: una sola vez por sugerencia; en silencio, al terminar el silencio', () {
      const s = (id: 's1', habitoNombre: 'Leer');
      final p = todos.copyWith(rachaEnRiesgo: false, resumenSemanal: false);
      final r = planear(preferencias: p, sugerencias: [s]);
      expect(r.single.tipo, TipoAviso.microPaso);
      expect(r.single.sugerenciaId, 's1');
      expect(r.single.cuerpo, contains('Leer'));
      expect(r.single.cuando.isAfter(_ahora), isTrue);

      final yaAvisada = [EventoAviso(cuando: _ahora, tipo: TipoAviso.microPaso, sugerenciaId: 's1', plantilla: 0)];
      expect(planear(preferencias: p, sugerencias: [s], historial: yaAvisada), isEmpty);

      // Programado y aún no llega: se conserva su hora al replanificar.
      final pendiente = [
        EventoAviso(cuando: _ahora.add(const Duration(minutes: 1)), tipo: TipoAviso.microPaso, sugerenciaId: 's1'),
      ];
      expect(planear(preferencias: p, sugerencias: [s], historial: pendiente).single.cuando, pendiente.single.cuando);

      final noche = planear(preferencias: p, sugerencias: [s], ahora: DateTime(2026, 11, 27, 23, 10));
      expect((noche.single.cuando.day, noche.single.cuando.hour), (28, 8));
      expect(planear(preferencias: p.copyWith(microPaso: false), sugerencias: [s]), isEmpty);
    });

    test('resumen semanal: domingo 18:00, o el día y la hora que elija el usuario', () {
      final p = todos.copyWith(rachaEnRiesgo: false, microPaso: false);
      final r = planear(preferencias: p);
      expect(r.single.tipo, TipoAviso.resumenSemanal);
      expect((r.single.cuando.day, r.single.cuando.hour, r.single.titulo), (29, 18, t.avisoResumenTitulo));
      final lunes = planear(
        preferencias: p.copyWith(diaResumen: DateTime.monday, horaResumen: (hora: 8, minuto: 45)),
      );
      expect((lunes.single.cuando.day, lunes.single.cuando.hour, lunes.single.cuando.minute), (30, 8, 45));
      expect(
        planear(preferencias: p.copyWith(horaResumen: (hora: 23, minuto: 0))),
        isEmpty,
        reason: 'en silencio',
      );
    });
  });

  group('el plan', () {
    test('ordenado por hora, con ids únicos desde 70000', () {
      final r = planear(
        preferencias: const PreferenciasAvisos(
          personales: [AvisoPersonal(id: 'a', hora: (hora: 7, minuto: 0), dias: 127, texto: 'a')],
        ),
        habitos: [
          _h(racha: 4),
          _h(id: 'h2', nombre: 'Agua', hora: (hora: 12, minuto: 0)),
        ],
        sugerencias: [(id: 's1', habitoNombre: 'Leer')],
      );
      expect([for (final a in r) a.id], [for (var i = 0; i < r.length; i++) PlanificadorAvisos.idInicial + i]);
      for (var i = 1; i < r.length; i++) {
        expect(r[i].cuando.isBefore(r[i - 1].cuando), isFalse);
      }
      expect(TipoAviso.values.where((x) => x.automatico).toSet(), {
        TipoAviso.rachaEnRiesgo,
        TipoAviso.microPaso,
        TipoAviso.resumenSemanal,
      });
    });
  });

  group('preferencias', () {
    test('silencio que cruza la medianoche, dentro del día, o apagado', () {
      const p = PreferenciasAvisos();
      expect(p.enSilencio((hora: 23, minuto: 0)), isTrue);
      expect(p.enSilencio((hora: 7, minuto: 59)), isTrue);
      expect(p.enSilencio((hora: 8, minuto: 0)), isFalse);
      expect(p.enSilencio((hora: 21, minuto: 59)), isFalse);
      final siesta = p.copyWith(silencioDesde: (hora: 14, minuto: 0), silencioHasta: (hora: 16, minuto: 0));
      expect((siesta.enSilencio((hora: 15, minuto: 0)), siesta.enSilencio((hora: 23, minuto: 0))), (true, false));
      final sin = p.copyWith(silencioHasta: (hora: 22, minuto: 0));
      expect(sin.enSilencio((hora: 23, minuto: 0)), isFalse);
    });

    test('JSON de ida y vuelta; lo que falta toma el valor por omisión', () {
      final p = const PreferenciasAvisos().copyWith(
        rachaEnRiesgo: false,
        horaRachaEnRiesgo: (hora: 19, minuto: 15),
        diaResumen: 5,
        horaResumen: (hora: 17, minuto: 0),
        silencioDesde: (hora: 23, minuto: 30),
        personales: [const AvisoPersonal(id: 'a', hora: (hora: 6, minuto: 0), dias: 31, texto: 'Agua')],
      );
      final q = PreferenciasAvisos.fromJson(p.toJson());
      expect(q.toJson(), p.toJson());
      final vacio = PreferenciasAvisos.fromJson(const {'hora_resumen': 'no'});
      expect(vacio.toJson(), const PreferenciasAvisos().toJson());
    });

    test('eventos: JSON de avisos y de check-ins', () {
      final a = EventoAviso.desdeAviso(
        AvisoProgramado(
          id: 1,
          cuando: DateTime(2026, 11, 27, 21),
          tipo: TipoAviso.microPaso,
          titulo: 't',
          cuerpo: 'c',
          plantilla: 2,
          sugerenciaId: 's1',
        ),
      );
      final b = EventoAviso.fromJson(a.toJson());
      expect(
        (b.tipo, b.plantilla, b.sugerenciaId, b.cuando, b.esCheckin),
        (TipoAviso.microPaso, 2, 's1', a.cuando, false),
      );
      final c = EventoAviso.fromJson(EventoAviso.checkin(cuando: _ahora, habitoId: 'h1').toJson());
      expect((c.esCheckin, c.habitoId, c.plantilla), (true, 'h1', null));
    });
  });
}
