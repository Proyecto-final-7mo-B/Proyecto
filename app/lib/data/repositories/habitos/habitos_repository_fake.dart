import '../../../domain/models/categoria.dart';
import '../../../domain/models/escalera.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/result.dart';
import '../../../utils/validadores.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'habitos_repository.dart';

class HabitosRepositoryFake implements HabitosRepository {
  HabitosRepositoryFake(this._datos);

  final DatosDemo _datos;

  void _validarFecha(DateTime fecha) {
    if (fecha.difference(_datos.hoy).inDays.abs() > 1) {
      throw DatosDemo.error(TipoError.fechaFueraDeRango, 422, 'Fecha no válida');
    }
  }

  @override
  Future<Result<List<Habito>>> listar({required DateTime fecha, bool archivados = false}) => _datos.ejecutar(() {
    _validarFecha(fecha);
    final u = _datos.usuarioDeSesion();
    // Como la API (v1.6): por prioridad y después por nombre.
    return [
      for (final h in _datos.habitosDe(u.id))
        if (h.activo || archivados) _datos.aHabito(h, fecha),
    ]..sort(_orden);
  });

  static int _orden(Habito a, Habito b) {
    final p = a.prioridad.compareTo(b.prioridad);
    return p != 0 ? p : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
  }

  /// La subcategoría debe existir y estar activa (KZ017); la unidad, ser una de las suyas (KZ016).
  Subcategoria _subcategoriaActiva(String id) {
    final sub = _datos.categorias.subcategoria(id);
    if (sub == null || !sub.activa) {
      throw DatosDemo.error(TipoError.subcategoriaInactiva, 422, 'La subcategoría no está disponible');
    }
    return sub;
  }

  static UnidadPermitida _unidadPermitida(Subcategoria sub, String unidad) {
    final u = sub.unidad(unidad.trim());
    if (u == null) {
      throw DatosDemo.error(TipoError.unidadNoPermitida, 422, 'La unidad no está permitida para esta subcategoría');
    }
    return u;
  }

  @override
  Future<Result<Habito>> obtener(String id, {required DateTime fecha}) => _datos.ejecutar(() {
    _validarFecha(fecha);
    return _datos.aHabito(_datos.habitoPropio(id), fecha);
  });

  @override
  Future<Result<Habito>> crear(NuevoHabito n) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    final campos = <String, String>{};
    if (Validadores.nombreHabito(n.nombre) != null) campos['nombre'] = '1 a 60 caracteres';
    if (Validadores.unidad(n.unidad) != null) campos['unidad'] = '1 a 20 caracteres';
    if (Validadores.meta('${n.meta}') != null) campos['meta'] = 'Mayor que 0, con hasta 2 decimales';
    if (Validadores.intencion(n.intencion) != null) campos['intencion'] = '1 a 120 caracteres';
    if (!Prioridad.todas.contains(n.prioridad)) campos['prioridad'] = '1, 2 o 3';
    if (campos.isNotEmpty) {
      throw DatosDemo.validacion(campos);
    }
    final sub = _subcategoriaActiva(n.subcategoriaId);
    final unidad = _unidadPermitida(sub, n.unidad);
    if (n.meta < unidad.minimo || n.meta > unidad.maximo) {
      throw DatosDemo.validacion({'meta': 'Entre ${unidad.minimo} y ${unidad.maximo} ${unidad.unidad}'});
    }
    final h = HabitoDemo(
      id: _datos.nuevoId(),
      usuarioId: u.id,
      nombre: n.nombre.trim(),
      unidad: n.unidad.trim(),
      meta: n.meta,
      nivel: 1,
      subcategoriaId: sub.id,
      categoriaId: _datos.categorias.categoriaDe(sub.id)!.id,
      prioridad: n.prioridad,
      intencion: n.intencion?.trim(),
      frecuencia: n.frecuencia,
      escaleraActiva: n.escaleraActiva,
      activo: true,
      fechaCreacion: _datos.ahora,
    );
    _datos.habitos[h.id] = h;
    _datos.niveles[h.id] = [Nivel(nivel: 1, meta: n.meta, desde: _datos.hoy)];
    return _datos.aHabito(h, _datos.hoy);
  });

  @override
  Future<Result<Habito>> actualizar(String id, CambiosHabito c) => _datos.ejecutar(() {
    final h = _datos.habitoPropio(id);
    if (c.subcategoriaId != null || c.unidad != null) {
      final sub = c.subcategoriaId == null
          ? _datos.subcategoria(h.subcategoriaId)
          : _subcategoriaActiva(c.subcategoriaId!);
      _unidadPermitida(sub, c.unidad ?? h.unidad);
      h
        ..subcategoriaId = sub.id
        ..categoriaId = _datos.categorias.categoriaDe(sub.id)!.id;
    }
    if (c.prioridad != null) {
      if (!Prioridad.todas.contains(c.prioridad)) {
        throw DatosDemo.validacion({'prioridad': '1, 2 o 3'});
      }
      h.prioridad = c.prioridad!;
    }
    if (c.intencion != null || c.quitarIntencion) {
      if (Validadores.intencion(c.intencion) != null) {
        throw DatosDemo.validacion({'intencion': '1 a 120 caracteres'});
      }
      h.intencion = c.intencion?.trim();
    }
    if (c.nombre != null) {
      if (Validadores.nombreHabito(c.nombre) != null) {
        throw DatosDemo.validacion({'nombre': '1 a 60 caracteres'});
      }
      h.nombre = c.nombre!.trim();
    }
    if (c.unidad != null) {
      h.unidad = c.unidad!.trim();
    }
    final apagaEscalera = c.escaleraActiva == false || c.activo == false;
    if (c.escaleraActiva != null) {
      h.escaleraActiva = c.escaleraActiva!;
    }
    if (c.activo != null) {
      h.activo = c.activo!;
    }
    if (apagaEscalera) {
      // Igual que la base: la sugerencia pendiente expira.
      for (final s in _datos.sugerencias.values.toList()) {
        if (s.habitoId == h.id && s.estado == EstadoSugerencia.pendiente) {
          _datos.sugerencias[s.id] = Sugerencia(
            id: s.id,
            habitoId: s.habitoId,
            habitoNombre: s.habitoNombre,
            tipo: s.tipo,
            metaActual: s.metaActual,
            metaPropuesta: s.metaPropuesta,
            cumplimiento14d: s.cumplimiento14d,
            motivo: s.motivo,
            cita: s.cita,
            estado: EstadoSugerencia.expirada,
            creadaEn: s.creadaEn,
            resueltaEn: _datos.ahora,
          );
        }
      }
    }
    return _datos.aHabito(h, _datos.hoy);
  });

  @override
  Future<Result<List<Registro>>> registros(String id, {required DateTime desde, required DateTime hasta}) =>
      _datos.ejecutar(() {
        if (Validadores.rangoFechas(desde, hasta) != null) {
          throw DatosDemo.validacion({'desde': 'Rango de máximo 366 días'});
        }
        final h = _datos.habitoPropio(id);
        final lista = [
          for (final r in (_datos.registros[h.id] ?? const <DateTime, Registro>{}).values)
            if (!r.fecha.isBefore(desde) && !r.fecha.isAfter(hasta)) r,
        ]..sort((a, b) => a.fecha.compareTo(b.fecha));
        return lista;
      });

  @override
  Future<Result<EscaleraHabito>> escalera(String id) => _datos.ejecutar(() {
    final h = _datos.habitoPropio(id);
    final pendiente = _datos.sugerencias.values
        .where((s) => s.habitoId == h.id && s.estado == EstadoSugerencia.pendiente)
        .firstOrNull;
    return EscaleraHabito(
      habitoId: h.id,
      escaleraActiva: h.escaleraActiva,
      nivelActual: h.nivel,
      metaActual: h.meta,
      unidad: h.unidad,
      niveles: List.of(_datos.niveles[h.id] ?? const []),
      sugerenciaPendiente: pendiente == null
          ? null
          : SugerenciaPendiente(
              id: pendiente.id,
              tipo: pendiente.tipo,
              metaPropuesta: pendiente.metaPropuesta,
              cumplimiento14d: pendiente.cumplimiento14d,
              motivo: pendiente.motivo,
            ),
      historial: [
        for (final s in _datos.sugerencias.values)
          if (s.habitoId == h.id && s.estado != EstadoSugerencia.pendiente)
            CambioEscalera(
              fecha: s.resueltaEn ?? s.creadaEn,
              tipo: s.tipo,
              de: s.metaActual,
              a: s.metaPropuesta,
              estado: s.estado,
            ),
      ],
    );
  });
}
