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
          if (d.isBefore(Fechas.soloFecha(h.fechaCreacion)) || !h.frecuencia.programadoEn(d)) {
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
    for (final h in habitos) {
      final nombre = _datos.categoria(h.categoriaId).nombre;
      mejores[nombre] = max(mejores[nombre] ?? 0, _datos.racha(h).maxima);
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
      mejoresRachas: [for (final e in mejores.entries) MejorRacha(categoria: e.key, rachaMaxima: e.value)]
        ..sort((a, b) => b.rachaMaxima.compareTo(a.rachaMaxima)),
      crecimientoMetas: crecimientos.isEmpty
          ? 0
          : _redondear(crecimientos.reduce((a, b) => a + b) / crecimientos.length),
    );
  });
}
