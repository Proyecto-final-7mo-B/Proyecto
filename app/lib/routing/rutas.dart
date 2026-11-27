/// Rutas de la app (las mismas en móvil, escritorio y web). En web se ven en la barra de direcciones.
abstract final class Rutas {
  // Sin sesión
  static const String login = '/login';
  static const String restablecer = '/restablecer';

  // Con sesión
  static const String hoy = '/hoy';
  static const String habitos = '/habitos';
  static const String nuevoHabito = '/habitos/nuevo';
  static const String progreso = '/progreso';
  static const String miSemana = '/progreso/semana';
  static const String escalera = '/escalera';
  static const String laboratorio = '/laboratorio';
  static const String capsulas = '/capsulas';
  static const String nuevaCapsula = '/capsulas/nueva';
  static const String perfil = '/perfil';
  static const String privacidad = '/perfil/privacidad';

  // Solo rol admin, y nunca en Android ni iOS
  static const String admin = '/admin';
  static const String indicadores = '/admin/indicadores';

  // Solo en depuración
  static const String componentes = '/dev/componentes';

  /// Pantallas que se abren sin sesión.
  static const Set<String> publicas = {login, restablecer};

  static String habito(String id) => '$habitos/${Uri.encodeComponent(id)}';
  static String editarHabito(String id) => '${habito(id)}/editar';
  static String escaleraHabito(String id) => '${habito(id)}/escalera';

  /// `/capsulas/nueva?habito=<id>`: al crear un hábito con cápsula se abre esta pantalla (Paso 7).
  /// Con [objetivo] (7, 21 o 66) la pantalla de cápsula ya trae elegida la racha que se escogió al crear el hábito.
  static String nuevaCapsulaDe(String habitoId, {int? objetivo}) =>
      Uri(path: nuevaCapsula, queryParameters: {'habito': habitoId, 'objetivo': ?objetivo?.toString()}).toString();

  /// `/login?desde=/habitos/123`: a dónde volver después de entrar.
  static String loginDesde(String destino) => Uri(path: login, queryParameters: {'desde': destino}).toString();

  /// `true` si [ruta] es igual a [base] o está dentro de ella (`/habitos/1` está dentro de `/habitos`).
  static bool dentroDe(String ruta, String base) => ruta == base || ruta.startsWith('$base/');
}
