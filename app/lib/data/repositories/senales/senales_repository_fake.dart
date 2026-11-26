import '../../../domain/models/laboratorio.dart';
import '../../../utils/result.dart';
import '../../../utils/validadores.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'senales_repository.dart';

class SenalesRepositoryFake implements SenalesRepository {
  SenalesRepositoryFake(this._datos);

  final DatosDemo _datos;

  @override
  Future<Result<Senal>> guardar(Senal senal) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    if (!u.consentimientoSenales) {
      throw DatosDemo.error(TipoError.consentimientoRequerido, 403, 'Falta el consentimiento de señales');
    }
    if (Validadores.animoEnergia(senal.animo) != null || Validadores.animoEnergia(senal.energia) != null) {
      throw DatosDemo.validacion({'animo': 'Enteros de 1 a 5'});
    }
    _datos.senales.putIfAbsent(u.id, () => {})[senal.fecha] = senal;
    return senal;
  });

  @override
  Future<Result<List<Senal>>> listar({required DateTime desde, required DateTime hasta}) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    return [
      for (final s in (_datos.senales[u.id] ?? const <DateTime, Senal>{}).values)
        if (!s.fecha.isBefore(desde) && !s.fecha.isAfter(hasta)) s,
    ]..sort((a, b) => a.fecha.compareTo(b.fecha));
  });
}
