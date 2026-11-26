import 'package:flutter/foundation.dart';

import '../../../data/services/servicio_sesion.dart';
import '../../../domain/models/sesion.dart';
import '../../../domain/models/usuario.dart';
import '../../../utils/command.dart';
import '../../../utils/paises_estados.dart';
import '../../../utils/validadores.dart';

/// Pestaña "Crear cuenta": país y estado (el estado solo en México), aviso de privacidad **obligatorio** y
/// consentimiento de señales **opcional y separado**.
class RegistroViewModel extends ChangeNotifier {
  RegistroViewModel(this._sesion, this.catalogo) {
    registrar = Command1<UsuarioToken, SolicitudRegistro>(_sesion.registrar);
  }

  final ServicioSesion _sesion;
  final CatalogoRegiones? catalogo;
  late final Command1<UsuarioToken, SolicitudRegistro> registrar;

  String? _pais;
  String? _estado;
  bool _aceptaAviso = false;
  bool _consienteSenales = false;
  bool _faltaAviso = false;

  String? get pais => _pais;
  String? get estado => _estado;
  bool get aceptaAviso => _aceptaAviso;
  bool get consienteSenales => _consienteSenales;

  /// Se intentó crear la cuenta sin aceptar el aviso.
  bool get faltaAviso => _faltaAviso;

  /// México primero y luego el resto por nombre.
  List<Pais> get paises {
    final lista = List.of(catalogo?.paises ?? const <Pais>[]);
    lista.sort((a, b) {
      if (a.codigo == 'MX') return -1;
      if (b.codigo == 'MX') return 1;
      return a.nombre.compareTo(b.nombre);
    });
    return lista;
  }

  List<EstadoMx> get estados =>
      List.of(catalogo?.estadosMx ?? const <EstadoMx>[])..sort((a, b) => a.nombre.compareTo(b.nombre));

  /// El estado solo se pide en México.
  bool get pideEstado => catalogo?.pais(_pais ?? '')?.requiereEstado ?? _pais == 'MX';

  /// Región que asignará la base (`MX-NORTE`, `MX-CENTRO-SUR` o `LATAM`), o `null` si falta algo.
  String? get region {
    final p = _pais;
    if (p == null || (pideEstado && _estado == null)) {
      return null;
    }
    return catalogo?.regionDe(p, pideEstado ? _estado : null);
  }

  void elegirPais(String? codigo) {
    _pais = codigo;
    if (!pideEstado) {
      _estado = null; // fuera de México el estado va en null
    }
    notifyListeners();
  }

  void elegirEstado(String? codigo) {
    _estado = codigo;
    notifyListeners();
  }

  void cambiarAviso({required bool acepta}) {
    _aceptaAviso = acepta;
    if (acepta) {
      _faltaAviso = false;
    }
    notifyListeners();
  }

  void cambiarConsentimiento({required bool consiente}) {
    _consienteSenales = consiente;
    notifyListeners();
  }

  /// Arma la solicitud si el aviso está aceptado; si no, marca [faltaAviso] y devuelve `null`.
  SolicitudRegistro? solicitud({required String nombre, required String email, required String contrasena}) {
    if (!_aceptaAviso) {
      _faltaAviso = true;
      notifyListeners();
      return null;
    }
    return SolicitudRegistro(
      nombre: nombre.trim(),
      email: Validadores.normalizarCorreo(email),
      contrasena: contrasena,
      pais: _pais!,
      estado: pideEstado ? _estado : null,
      aceptaAviso: true,
      consienteSenales: _consienteSenales,
    );
  }

  @override
  void dispose() {
    registrar.dispose();
    super.dispose();
  }
}
