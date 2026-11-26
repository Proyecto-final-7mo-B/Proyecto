import '../../../domain/models/usuario.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../../utils/validadores.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'cuenta_repository.dart';

class CuentaRepositoryFake implements CuentaRepository {
  CuentaRepositoryFake(this._datos);

  final DatosDemo _datos;

  @override
  Future<Result<Cuenta>> obtener() => _datos.ejecutar(() => _datos.usuarioDeSesion().aCuenta());

  @override
  Future<Result<Cuenta>> cambiarNombre(String nombre) => _datos.ejecutar(() {
    if (Validadores.nombreUsuario(nombre) != null) {
      throw DatosDemo.validacion({'nombre': '1 a 80 caracteres'});
    }
    return (_datos.usuarioDeSesion()..nombre = nombre.trim()).aCuenta();
  });

  @override
  Future<Result<void>> cambiarContrasena({required String actual, required String nueva}) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    if (u.contrasena != actual) {
      throw DatosDemo.error(TipoError.credencialesInvalidas, 401, 'Contraseña actual incorrecta');
    }
    if (Validadores.contrasena(nueva, correo: u.email) != null) {
      throw DatosDemo.validacion({'nueva': 'De 18 a 128 caracteres y distinta del correo'});
    }
    u.contrasena = nueva;
    // Revoca las demás sesiones; la actual sigue.
    final actuales = _datos.renovacionesVigentes.entries.where((e) => e.value == u.id).map((e) => e.key).toList();
    for (final t in actuales.take(actuales.length > 1 ? actuales.length - 1 : 0)) {
      _datos.renovacionesVigentes.remove(t);
    }
  });

  @override
  Future<Result<ResultadoConsentimiento>> cambiarConsentimiento({required bool senales}) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    var borradas = 0;
    if (senales) {
      u
        ..consentimientoSenales = true
        ..consentimientoSenalesEn = _datos.ahora;
    } else {
      borradas = _datos.senales.remove(u.id)?.length ?? 0;
      u
        ..consentimientoSenales = false
        ..consentimientoSenalesEn = null;
    }
    return ResultadoConsentimiento(senales: senales, senalesBorradas: borradas);
  });

  @override
  Future<Result<Map<String, dynamic>>> exportarDatos() => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    final habitos = _datos.habitosDe(u.id).toList();
    return {
      'cuenta': u.aCuenta().toJson(),
      'habitos': [for (final h in habitos) _datos.aHabito(h, _datos.hoy).toJson()],
      'registros': [
        for (final h in habitos)
          for (final r in (_datos.registros[h.id] ?? const {}).values) r.toJson(),
      ],
      'niveles': {
        for (final h in habitos) h.id: [for (final n in _datos.niveles[h.id] ?? const []) n.toJson()],
      },
      'sugerencias': [
        for (final s in _datos.sugerencias.values)
          if (habitos.any((h) => h.id == s.habitoId)) s.toJson(),
      ],
      'senales': [for (final s in (_datos.senales[u.id] ?? const {}).values) s.toJson()],
      'capsulas': [
        for (final c in _datos.capsulas.values)
          if (c.usuarioId == u.id)
            {
              ..._datos.aCapsula(c).toJson(),
              // Solo el mensaje de las abiertas.
              if (c.abiertaEn != null) 'mensaje': c.mensaje,
            },
      ],
      'exportado_en': Fechas.iso(_datos.hoy),
    };
  });

  @override
  Future<Result<void>> eliminar({required String contrasena}) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    if (u.contrasena != contrasena) {
      throw DatosDemo.error(TipoError.credencialesInvalidas, 401, 'Contraseña incorrecta');
    }
    for (final h in _datos.habitosDe(u.id).toList()) {
      _datos.habitos.remove(h.id);
      _datos.registros.remove(h.id);
      _datos.niveles.remove(h.id);
      _datos.sugerencias.removeWhere((_, s) => s.habitoId == h.id);
    }
    _datos.capsulas.removeWhere((_, c) => c.usuarioId == u.id);
    _datos.senales.remove(u.id);
    _datos.revocarSesiones(u.id);
    _datos.usuarios.remove(u.id);
  });
}
