import '../../../domain/models/escalera.dart';
import '../../../utils/result.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'escalera_repository.dart';

class EscaleraRepositoryFake implements EscaleraRepository {
  EscaleraRepositoryFake(this._datos);

  final DatosDemo _datos;

  @override
  Future<Result<List<Sugerencia>>> sugerencias() => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    return [
      for (final s in _datos.sugerencias.values)
        if (s.estado == EstadoSugerencia.pendiente && _datos.habitos[s.habitoId]?.usuarioId == u.id) s,
    ];
  });

  @override
  Future<Result<RespuestaSugerencia>> responder(String id, {required bool aceptar}) => _datos.ejecutar(() {
    final s = _datos.sugerencias[id];
    if (s == null) {
      throw DatosDemo.noEncontrado();
    }
    final h = _datos.habitoPropio(s.habitoId);
    if (s.estado != EstadoSugerencia.pendiente) {
      throw DatosDemo.error(TipoError.sugerenciaResuelta, 409, 'La sugerencia ya se resolvió');
    }
    final estado = aceptar ? EstadoSugerencia.aceptada : EstadoSugerencia.rechazada;
    _datos.sugerencias[id] = Sugerencia(
      id: s.id,
      habitoId: s.habitoId,
      habitoNombre: s.habitoNombre,
      tipo: s.tipo,
      metaActual: s.metaActual,
      metaPropuesta: s.metaPropuesta,
      cumplimiento14d: s.cumplimiento14d,
      estado: estado,
      creadaEn: s.creadaEn,
      resueltaEn: _datos.ahora,
    );
    if (!aceptar) {
      return const RespuestaSugerencia(estado: EstadoSugerencia.rechazada);
    }
    // Aceptar: sube (o baja) de nivel y cambia la meta.
    final niveles = _datos.niveles.putIfAbsent(h.id, () => []);
    if (niveles.isNotEmpty) {
      final ultimo = niveles.removeLast();
      niveles.add(Nivel(nivel: ultimo.nivel, meta: ultimo.meta, desde: ultimo.desde, hasta: _datos.hoy));
    }
    h
      ..nivel += 1
      ..meta = s.metaPropuesta;
    niveles.add(Nivel(nivel: h.nivel, meta: h.meta, desde: _datos.hoy));
    return RespuestaSugerencia(estado: estado, nivel: h.nivel, metaNueva: h.meta);
  });
}
