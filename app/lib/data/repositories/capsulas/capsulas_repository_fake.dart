import '../../../domain/models/capsula.dart';
import '../../../utils/result.dart';
import '../../../utils/validadores.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'capsulas_repository.dart';

class CapsulasRepositoryFake implements CapsulasRepository {
  CapsulasRepositoryFake(this._datos);

  final DatosDemo _datos;

  @override
  Future<Result<Capsula>> crear(NuevaCapsula n) => _datos.ejecutar(() {
    final h = _datos.habitoPropio(n.habitoId);
    final campos = <String, String>{};
    if (Validadores.mensajeCapsula(n.mensaje) != null) campos['mensaje'] = 'De 1 a 4096 bytes';
    if (Validadores.rachaObjetivo(n.rachaObjetivo) != null) campos['racha_objetivo'] = '7, 21 o 66';
    if (campos.isNotEmpty) {
      throw DatosDemo.validacion(campos);
    }
    final c = CapsulaDemo(
      id: _datos.nuevoId(),
      usuarioId: h.usuarioId,
      habitoId: h.id,
      rachaObjetivo: n.rachaObjetivo,
      mensaje: n.mensaje,
      tieneFoto: n.tieneFoto,
      creadaEn: _datos.ahora,
    );
    _datos.capsulas[c.id] = c;
    return _datos.aCapsula(c);
  });

  @override
  Future<Result<List<Capsula>>> listar({EstadoCapsula? estado}) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    return [
      for (final c in _datos.capsulas.values)
        if (c.usuarioId == u.id && (estado == null || c.estado == estado)) _datos.aCapsula(c),
    ];
  });

  @override
  Future<Result<CapsulaAbierta>> abrir(String id) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    final c = _datos.capsulas[id];
    if (c == null || c.usuarioId != u.id) {
      throw DatosDemo.noEncontrado();
    }
    final vista = _datos.aCapsula(c);
    if (!vista.sePuedeAbrir) {
      throw DatosDemo.error(
        TipoError.capsulaSellada,
        409,
        'La cápsula aún está sellada',
        detalle: 'Racha ${vista.progreso} de ${c.rachaObjetivo}',
        extras: {'racha': vista.progreso, 'objetivo': c.rachaObjetivo},
      );
    }
    if (c.estado == EstadoCapsula.sellada) {
      c
        ..estado = EstadoCapsula.abierta
        ..abiertaEn = _datos.ahora;
    }
    return CapsulaAbierta(id: c.id, mensaje: c.mensaje, abiertaEn: c.abiertaEn!);
  });
}
