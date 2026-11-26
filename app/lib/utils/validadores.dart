import 'dart:convert';

/// Por qué un valor no es válido. La pantalla lo convierte en texto con `mensajeValidacion` (ui/core/mensajes.dart).
enum ErrorValidacion {
  requerido,
  muyLargo,
  muyCorto,
  correoInvalido,
  contrasenaCorta,
  contrasenaLarga,
  contrasenaIgualAlCorreo,
  contrasenasDistintas,
  numeroInvalido,
  debeSerMayorACero,
  noNegativo,
  maximoDosDecimales,
  fueraDeRango,
  mensajeMuyLargo,
  rangoFechasInvalido,
}

/// Los mismos límites que hace cumplir la base (contrato §4). Validar antes evita esperar al servidor; **la API
/// vuelve a validar todo**. Cada función devuelve `null` si el valor es válido.
abstract final class Validadores {
  static final RegExp _correo = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Correo normalizado como lo guarda la base: sin espacios a los lados y en minúsculas.
  static String normalizarCorreo(String correo) => correo.trim().toLowerCase();

  static ErrorValidacion? _largo(String? valor, int minimo, int maximo) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) {
      return ErrorValidacion.requerido;
    }
    if (texto.length < minimo) {
      return ErrorValidacion.muyCorto;
    }
    return texto.length > maximo ? ErrorValidacion.muyLargo : null;
  }

  /// Nombre de la persona: 1–80.
  static ErrorValidacion? nombreUsuario(String? valor) => _largo(valor, 1, 80);

  /// Formato `x@y.z`.
  static ErrorValidacion? correo(String? valor) {
    final texto = normalizarCorreo(valor ?? '');
    if (texto.isEmpty) {
      return ErrorValidacion.requerido;
    }
    return _correo.hasMatch(texto) && texto.length <= 254 ? null : ErrorValidacion.correoInvalido;
  }

  /// 12–128 caracteres, sin reglas de composición (ASVS 2.1). No puede ser igual al correo.
  /// La lista de contraseñas comunes la revisa la API.
  static ErrorValidacion? contrasena(String? valor, {String? correo}) {
    final texto = valor ?? '';
    if (texto.isEmpty) {
      return ErrorValidacion.requerido;
    }
    if (texto.length < 12) {
      return ErrorValidacion.contrasenaCorta;
    }
    if (texto.length > 128) {
      return ErrorValidacion.contrasenaLarga;
    }
    if (correo != null && normalizarCorreo(texto) == normalizarCorreo(correo)) {
      return ErrorValidacion.contrasenaIgualAlCorreo;
    }
    return null;
  }

  /// Para entrar solo se exige que no esté vacía (la política se aplica al crearla).
  static ErrorValidacion? contrasenaParaEntrar(String? valor) =>
      (valor ?? '').isEmpty ? ErrorValidacion.requerido : null;

  static ErrorValidacion? confirmacion(String? valor, String original) =>
      (valor ?? '') == original ? null : ErrorValidacion.contrasenasDistintas;

  /// Nombre de hábito: 1–60.
  static ErrorValidacion? nombreHabito(String? valor) => _largo(valor, 1, 60);

  /// Unidad: 1–20.
  static ErrorValidacion? unidad(String? valor) => _largo(valor, 1, 20);

  /// Nombre de categoría: 2–40.
  static ErrorValidacion? nombreCategoria(String? valor) => _largo(valor, 2, 40);

  /// Motivo de suspensión: 3–200.
  static ErrorValidacion? motivoSuspension(String? valor) => _largo(valor, 3, 200);

  static num? _numero(String? valor) => num.tryParse((valor ?? '').trim().replaceAll(',', '.'));

  static bool _dosDecimales(num n) => ((n * 100) - (n * 100).round()).abs() < 1e-9;

  /// Meta: > 0 y hasta 2 decimales.
  static ErrorValidacion? meta(String? valor) {
    if ((valor ?? '').trim().isEmpty) {
      return ErrorValidacion.requerido;
    }
    final n = _numero(valor);
    if (n == null || n.isNaN || n.isInfinite) {
      return ErrorValidacion.numeroInvalido;
    }
    if (n <= 0) {
      return ErrorValidacion.debeSerMayorACero;
    }
    return _dosDecimales(n) ? null : ErrorValidacion.maximoDosDecimales;
  }

  /// Valor de un check-in: opcional, ≥ 0 y hasta 2 decimales.
  static ErrorValidacion? valorRegistro(String? valor) {
    if ((valor ?? '').trim().isEmpty) {
      return null;
    }
    final n = _numero(valor);
    if (n == null || n.isNaN || n.isInfinite) {
      return ErrorValidacion.numeroInvalido;
    }
    if (n < 0) {
      return ErrorValidacion.noNegativo;
    }
    return _dosDecimales(n) ? null : ErrorValidacion.maximoDosDecimales;
  }

  /// Ánimo y energía: enteros 1–5.
  static ErrorValidacion? animoEnergia(int? valor) =>
      valor == null ? ErrorValidacion.requerido : (valor < 1 || valor > 5 ? ErrorValidacion.fueraDeRango : null);

  /// Máscara de días: 1–127.
  static ErrorValidacion? mascaraDias(int? valor) => valor == null || valor < 1 || valor > 127
      ? (valor == null || valor == 0 ? ErrorValidacion.requerido : ErrorValidacion.fueraDeRango)
      : null;

  /// Veces por semana: 1–7.
  static ErrorValidacion? vecesSemana(int? valor) =>
      valor == null ? ErrorValidacion.requerido : (valor < 1 || valor > 7 ? ErrorValidacion.fueraDeRango : null);

  /// Bytes que ocupa un texto en UTF-8 (un emoji ocupa 4).
  static int bytesUtf8(String texto) => utf8.encode(texto).length;

  /// Mensaje de la cápsula: 1 a 4,096 **bytes** en UTF-8.
  static ErrorValidacion? mensajeCapsula(String? valor) {
    final texto = valor ?? '';
    if (texto.trim().isEmpty) {
      return ErrorValidacion.requerido;
    }
    return bytesUtf8(texto) > 4096 ? ErrorValidacion.mensajeMuyLargo : null;
  }

  /// Racha objetivo de la cápsula: 7, 21 o 66.
  static ErrorValidacion? rachaObjetivo(int? valor) =>
      const {7, 21, 66}.contains(valor) ? null : ErrorValidacion.fueraDeRango;

  /// `desde` ≤ `hasta` y máximo 366 días entre ambos.
  static ErrorValidacion? rangoFechas(DateTime desde, DateTime hasta) {
    final dias = hasta.difference(desde).inDays;
    return dias < 0 || dias > 366 ? ErrorValidacion.rangoFechasInvalido : null;
  }
}
