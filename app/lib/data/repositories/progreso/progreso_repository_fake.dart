import 'dart:math';

import '../../../domain/models/progreso.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../fake/datos_demo.dart';
import 'progreso_repository.dart';

class ProgresoRepositoryFake implements ProgresoRepository {
  ProgresoRepositoryFake(this._datos);

  final DatosDemo _datos;

  static (DateTime, DateTime) rango(Periodo periodo, DateTime fecha) => switch (periodo) {
    Periodo.semana => (Fechas.inicioSemana(fecha), Fechas.inicioSemana(fecha).add(const Duration(days: 6))),
    Periodo.mes => (DateTime.utc(fecha.year, fecha.month), DateTime.utc(fecha.year, fecha.month + 1, 0)),
    Periodo.anio => (DateTime.utc(fecha.year), DateTime.utc(fecha.year, 12, 31)),
  };

  static double _redondear(double x) => (x * 100).roundToDouble() / 100;

  /// Recomendación semanal de la OMS 2020 para actividad moderada (F11); igual que `sp_otorgar_logros_semanales`.
  static const double omsDesde = 150;
  static const double omsHasta = 300;
  static const String citaOms = 'OMS 2020: 150–300 min/semana';

  /// `actividad_semanal` (contrato §6.7): semana ISO de [fecha]; `coalesce(valor, meta) × factor` de los check-ins
  /// cumplidos de `aerobico_moderado` y `vigoroso`; 1 min vigoroso = 2 moderados. `null` sin hábitos aeróbicos.
  ActividadSemanal? actividadSemanal(List<HabitoDemo> habitos, DateTime fecha) {
    final lunes = Fechas.inicioSemana(fecha);
    var moderados = 0.0;
    var vigorosos = 0.0;
    var hay = false;
    for (final h in habitos) {
      final sub = _datos.subcategoria(h.subcategoriaId);
      final factor = sub.unidad(h.unidad)?.factorABase;
      if ((sub.clave != 'aerobico_moderado' && sub.clave != 'vigoroso') || factor == null) {
        continue;
      }
      hay = true;
      for (var i = 0; i < 7; i++) {
        final r = _datos.registros[h.id]?[lunes.add(Duration(days: i))];
        if (r == null || !r.cumplido) {
          continue;
        }
        final minutos = (r.valor ?? h.meta) * factor;
        if (sub.clave == 'vigoroso') {
          vigorosos += minutos;
        } else {
          moderados += minutos;
        }
      }
    }
    if (!hay) {
      return null;
    }
    return ActividadSemanal(
      semana: Fechas.semanaIso(fecha),
      minutosModerados: _redondear(moderados),
      minutosVigorosos: _redondear(vigorosos),
      equivalenteModerado: _redondear(moderados + 2 * vigorosos),
      recomendadoDesde: omsDesde,
      recomendadoHasta: omsHasta,
      cita: citaOms,
    );
  }

  @override
  Future<Result<Progreso>> obtener(Periodo periodo, {required DateTime fecha}) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    final habitos = _datos.habitosDe(u.id).where((h) => h.activo).toList();
    final (desde, fin) = rango(periodo, fecha);
    final hasta = fin.isAfter(fecha) ? fecha : fin;

    double cumplimientoEntre(DateTime a, DateTime b, {List<ProgresoDia>? dias}) {
      var programados = 0;
      var cumplidos = 0;
      for (var d = a; !d.isAfter(b); d = d.add(const Duration(days: 1))) {
        var p = 0;
        var c = 0;
        for (final h in habitos) {
          if (d.isBefore(_datos.diaDe(h.fechaCreacion)) || !h.frecuencia.programadoEn(d)) {
            continue;
          }
          p++;
          if (_datos.registros[h.id]?[d]?.cumplido ?? false) {
            c++;
          }
        }
        programados += p;
        cumplidos += c;
        dias?.add(
          ProgresoDia(fecha: d, programados: p, cumplidos: c, cumplimiento: p == 0 ? 0 : _redondear(100 * c / p)),
        );
      }
      return programados == 0 ? 0 : _redondear(100 * cumplidos / programados);
    }

    final porDia = <ProgresoDia>[];
    final actual = cumplimientoEntre(desde, hasta, dias: porDia);
    final largo = hasta.difference(desde).inDays;
    final anterior = cumplimientoEntre(
      desde.subtract(Duration(days: largo + 1)),
      desde.subtract(const Duration(days: 1)),
    );

    final mejores = <String, int>{};
    final claves = <String, String>{};
    for (final h in habitos) {
      final categoria = _datos.categoria(h.categoriaId);
      mejores[categoria.nombre] = max(mejores[categoria.nombre] ?? 0, _datos.racha(h).maxima);
      claves[categoria.nombre] = categoria.clave;
    }
    final crecimientos = [
      for (final h in habitos)
        if ((_datos.niveles[h.id] ?? const []).isNotEmpty) 100 * (h.meta / _datos.niveles[h.id]!.first.meta - 1),
    ];

    return Progreso(
      periodo: periodo,
      desde: desde,
      hasta: fin,
      cumplimiento: actual,
      variacion: _redondear(actual - anterior),
      habitosActivos: habitos.length,
      porDia: porDia,
      porHabito: [
        for (final h in habitos)
          ProgresoHabito(
            habitoId: h.id,
            nombre: h.nombre,
            cumplimiento: () {
              var p = 0;
              var c = 0;
              for (var d = desde; !d.isAfter(hasta); d = d.add(const Duration(days: 1))) {
                if (h.frecuencia.programadoEn(d)) {
                  p++;
                  if (_datos.registros[h.id]?[d]?.cumplido ?? false) c++;
                }
              }
              return p == 0 ? 0.0 : _redondear(100 * c / p);
            }(),
          ),
      ],
      mejoresRachas: [
        for (final e in mejores.entries)
          MejorRacha(categoria: e.key, categoriaClave: claves[e.key]!, rachaMaxima: e.value),
      ]
        ..sort((a, b) => b.rachaMaxima.compareTo(a.rachaMaxima)),
      crecimientoMetas: crecimientos.isEmpty
          ? 0
          : _redondear(crecimientos.reduce((a, b) => a + b) / crecimientos.length),
      actividadSemanal: actividadSemanal(habitos, fecha),
    );
  });
}
