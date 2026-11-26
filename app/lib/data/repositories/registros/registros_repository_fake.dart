import '../../../domain/models/problema.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/result.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'registros_repository.dart';

class RegistrosRepositoryFake implements RegistrosRepository {
  RegistrosRepositoryFake(this._datos);

  final DatosDemo _datos;

  ResultadoCheckin _registrar(NuevoRegistro r) {
    final h = _datos.habitoPropio(r.habitoId);
    if (!h.activo) {
      throw DatosDemo.error(TipoError.habitoArchivado, 409, 'El hábito está archivado');
    }
    final creacion = DateTime.utc(h.fechaCreacion.year, h.fechaCreacion.month, h.fechaCreacion.day);
    if (r.fecha.isBefore(creacion) || r.fecha.isAfter(_datos.hoy.add(const Duration(days: 1)))) {
      throw DatosDemo.error(TipoError.fechaFueraDeRango, 422, 'Fecha no válida');
    }
    // UNIQUE (habito, fecha): reenviar el mismo día reemplaza (gana el último).
    _datos.registros.putIfAbsent(h.id, () => {})[r.fecha] = Registro(
      id: r.id,
      habitoId: h.id,
      fecha: r.fecha,
      cumplido: r.cumplido,
      valor: r.valor,
      origen: r.origen,
      registradoEn: _datos.ahora,
    );
    final racha = _datos.racha(h);
    if (racha.maxima > h.maximaHistorica) {
      h.maximaHistorica = racha.maxima;
    }
    return ResultadoCheckin(id: r.id, rachaActual: racha.actual);
  }

  @override
  Future<Result<ResultadoCheckin>> registrar(NuevoRegistro registro) => _datos.ejecutar(() => _registrar(registro));

  @override
  Future<Result<ResultadoLote>> registrarLote(List<NuevoRegistro> registros) => _datos.ejecutar(() {
    if (registros.length > 100) {
      throw DatosDemo.validacion({'registros': 'Máximo 100 por lote'});
    }
    _datos.usuarioDeSesion();
    return ResultadoLote(resultados: [for (final r in registros) _uno(r)]);
  });

  /// Cada elemento se procesa aparte (en la API, un SAVEPOINT por elemento).
  ElementoLote _uno(NuevoRegistro r) {
    try {
      final res = _registrar(r);
      return ElementoLote(id: r.id, estado: EstadoElementoLote.aceptado, rachaActual: res.rachaActual);
    } on ErrorApp catch (e) {
      final p = e.problema;
      return ElementoLote(
        id: r.id,
        estado: EstadoElementoLote.rechazado,
        error: p == null ? null : Problema(type: p.type, title: p.title, status: p.status),
      );
    }
  }
}
