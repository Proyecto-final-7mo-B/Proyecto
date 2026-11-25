/// Límites del contrato de la API v1.4 (§4). Son los mismos que hace cumplir la base de datos:
/// si la app los valida antes, el usuario ve el error sin esperar al servidor.
library;

abstract final class Limites {
  static const int nombreUsuarioMin = 1;
  static const int nombreUsuarioMax = 80;
  static const int contrasenaMin = 12;
  static const int contrasenaMax = 128;
  static const int nombreHabitoMin = 1;
  static const int nombreHabitoMax = 60;
  static const int unidadMin = 1;
  static const int unidadMax = 20;
  static const int mascaraDiasMin = 1; // lunes = 1 … domingo = 64
  static const int mascaraDiasMax = 127;
  static const int mascaraLunesAViernes = 31;
  static const int vecesSemanaMin = 1;
  static const int vecesSemanaMax = 7;
  static const int escalaMin = 1; // ánimo y energía
  static const int escalaMax = 5;
  static const int mensajeCapsulaMaxBytes = 4096;
  static const List<int> rachasObjetivo = [7, 21, 66];
  static const int categoriaMin = 2;
  static const int categoriaMax = 40;
  static const int motivoSuspensionMin = 3;
  static const int motivoSuspensionMax = 200;
  static const int historialMaxDias = 366;
  static const int loteMaxRegistros = 100;
  static const int porPaginaMax = 100;
}

/// Tiempos de la sesión (contrato §2.1).
abstract final class Sesion {
  static const Duration vidaAcceso = Duration(minutes: 15);
  static const Duration vidaRenovacion = Duration(days: 7);
}
