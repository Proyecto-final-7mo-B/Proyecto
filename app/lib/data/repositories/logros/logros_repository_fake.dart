import 'dart:math';

import '../../../domain/models/capsula.dart';
import '../../../domain/models/escalera.dart';
import '../../../domain/models/evidencia.dart';
import '../../../domain/models/frecuencia.dart';
import '../../../domain/models/logro.dart';
import '../../../utils/evidencia.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../fake/datos_demo.dart';
import '../../fake/logros_demo.dart';
import '../progreso/progreso_repository_fake.dart';
import 'logros_repository.dart';

/// Logros en memoria con las mismas reglas que la base (triggers y `sp_otorgar_logros_semanales`):
///
/// - **Racha** 7, 30, 66 y 100: la mejor racha de cualquiera de sus hábitos.
/// - **Racha salvada:** el protector perdonó algún día.
/// - **Primer micro-paso:** aceptó una subida de la Escalera.
/// - **Cápsula abierta:** abrió alguna.
/// - **Plan si-entonces:** un hábito personalizado con intención (los recomendados traen la suya: no cuentan).
/// - **Semana OMS:** 150 min moderados (o equivalentes) en alguna de las 4 semanas ISO anteriores.
/// - **Ritmo ideal:** un hábito activo en la zona óptima, sin cambio de nivel en 28 días y con ≥ 85 % de cumplimiento
///   en los 28 días anteriores a la semana actual.
///
/// Cada logro se obtiene una sola vez: la primera vez que se cumple se anota su fecha y ya no cambia.
class LogrosRepositoryFake implements LogrosRepository {
  LogrosRepositoryFake(this._datos) : _progreso = ProgresoRepositoryFake(_datos);

  final DatosDemo _datos;
  final ProgresoRepositoryFake _progreso;

  /// Usuario → clave → cuándo y con qué hábito.
  final Map<String, Map<String, ({DateTime en, String? habitoId})>> _obtenidos = {};

  @override
  Future<Result<List<Logro>>> listar() => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    final habitos = _datos.habitosDe(u.id).toList();
    final ahora = _datos.ahora;
    final hoy = _datos.hoy;
    final obtenidos = _obtenidos.putIfAbsent(u.id, () => {});

    void otorgar(String clave, {String? habitoId, DateTime? en}) =>
        obtenidos.putIfAbsent(clave, () => (en: en ?? ahora, habitoId: habitoId));

    // Rachas: la mejor de sus hábitos.
    var mejor = 0;
    String? habitoMejor;
    final rachas = {for (final h in habitos) h.id: _datos.racha(h)};
    for (final h in habitos) {
      final r = rachas[h.id]!;
      if (r.maxima > mejor) {
        mejor = r.maxima;
        habitoMejor = h.id;
      }
    }
    for (final l in logrosDemo.where((l) => l.tipo == 'racha')) {
      if (mejor >= l.objetivo) {
        // Cuándo se llegó (aproximado): si la racha sigue, contando hacia atrás desde el último día cumplido.
        final r = rachas[habitoMejor]!;
        // Si la racha ya se rompió, desde la creación del hábito.
        final h = habitos.firstWhere((h) => h.id == habitoMejor);
        final en = r.actual >= l.objetivo && r.ultimaFecha != null
            ? r.ultimaFecha!.subtract(Duration(days: r.actual - l.objetivo))
            : _datos.diaDe(h.fechaCreacion).add(Duration(days: l.objetivo - 1));
        otorgar(l.clave, habitoId: habitoMejor, en: _alMediodia(en, ahora));
      }
    }

    // Racha salvada.
    for (final h in habitos) {
      final protegidos = _datos.diasProtegidos(h);
      if (protegidos.isNotEmpty) {
        otorgar(
          'racha_salvada',
          habitoId: h.id,
          en: _alMediodia(protegidos.reduce((a, b) => a.isAfter(b) ? a : b), ahora),
        );
        break;
      }
    }

    // Primer micro-paso.
    final ids = {for (final h in habitos) h.id};
    for (final s in _datos.sugerencias.values) {
      if (ids.contains(s.habitoId) && s.estado == EstadoSugerencia.aceptada && s.tipo == TipoSugerencia.subir) {
        otorgar('primer_micro_paso', habitoId: s.habitoId);
        break;
      }
    }

    // Cápsula abierta.
    for (final c in _datos.capsulas.values) {
      if (c.usuarioId == u.id && c.estado == EstadoCapsula.abierta) {
        otorgar('capsula_abierta', habitoId: c.habitoId, en: c.abiertaEn);
        break;
      }
    }

    // Plan si-entonces.
    for (final h in habitos) {
      if (h.recomendacionId == null && (h.intencion?.trim().isNotEmpty ?? false)) {
        otorgar(
          'plan_si_entonces',
          habitoId: h.id,
          en: _mayor(h.fechaCreacion, ahora.subtract(const Duration(days: 60))),
        );
        break;
      }
    }

    // Semana OMS: alguna de las 4 semanas anteriores.
    final lunes = Fechas.inicioSemana(hoy);
    for (var k = 4; k >= 1; k--) {
      final semana = lunes.subtract(Duration(days: 7 * k));
      final a = _progreso.actividadSemanal(habitos, semana);
      if (a != null && a.equivalenteModerado >= ProgresoRepositoryFake.omsDesde) {
        // La revisión semanal corre el lunes siguiente.
        otorgar('semana_oms', en: _alMediodia(semana.add(const Duration(days: 7)), ahora));
        break;
      }
    }

    // Ritmo ideal.
    final domingo = lunes.subtract(const Duration(days: 1));
    for (final h in habitos.where((h) => h.activo)) {
      final zona = EvaluadorEvidencia.evaluar(
        _datos.subcategoria(h.subcategoriaId),
        h.unidad,
        h.meta,
        h.frecuencia,
      ).zona;
      final nivel = _datos.niveles[h.id]?.lastOrNull;
      final sinCambio = nivel == null || !nivel.desde.isAfter(domingo.subtract(const Duration(days: 27)));
      if (zona == ZonaEvidencia.optimo && sinCambio && _cumplimiento28(h, domingo) >= 85) {
        otorgar('ritmo_ideal', habitoId: h.id, en: _alMediodia(lunes, ahora));
        break;
      }
    }

    final nombres = {for (final h in habitos) h.id: h.nombre};
    return [
      for (final l in logrosDemo)
        switch (obtenidos[l.clave]) {
          final o? => Logro(
            clave: l.clave,
            nombre: l.nombre,
            descripcion: l.descripcion,
            icono: l.icono,
            tipo: TipoLogro.deJson(l.tipo),
            objetivo: l.objetivo,
            progreso: l.objetivo,
            obtenido: true,
            obtenidoEn: o.en,
            habitoId: o.habitoId,
            habitoNombre: nombres[o.habitoId],
            porque: l.porque,
            fuentes: l.fuentes,
          ),
          null => Logro(
            clave: l.clave,
            nombre: l.nombre,
            descripcion: l.descripcion,
            icono: l.icono,
            tipo: TipoLogro.deJson(l.tipo),
            objetivo: l.objetivo,
            progreso: l.tipo == 'racha' ? min(l.objetivo, mejor) : 0,
            obtenido: false,
            porque: l.porque,
            fuentes: l.fuentes,
          ),
        },
    ];
  });

  /// % de días programados cumplidos en los 28 días que terminan en [hasta] (como `fn_cumplimiento`).
  double _cumplimiento28(HabitoDemo h, DateTime hasta) {
    final regs = _datos.registros[h.id] ?? const {};
    var programados = 0;
    var cumplidos = 0;
    for (var i = 0; i < 28; i++) {
      final d = hasta.subtract(Duration(days: i));
      if (h.frecuencia is! NPorSemana && !h.frecuencia.programadoEn(d)) {
        continue;
      }
      programados++;
      if (regs[d]?.cumplido ?? false) {
        cumplidos++;
      }
    }
    return programados == 0 ? 0 : 100 * cumplidos / programados;
  }

  /// Un día del pasado, a mediodía (UTC); nunca después de [ahora].
  static DateTime _alMediodia(DateTime dia, DateTime ahora) {
    final d = DateTime.utc(dia.year, dia.month, dia.day, 12);
    return d.isAfter(ahora) ? ahora : d;
  }

  static DateTime _mayor(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
}
