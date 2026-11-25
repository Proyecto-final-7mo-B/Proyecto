import '../ui/core/adaptativo/plataforma.dart';
import 'estado_sesion.dart';
import 'rutas.dart';

/// Decide a dónde redirigir antes de mostrar [ubicacion]. Devuelve `null` si se puede mostrar tal cual.
///
/// Reglas, en orden:
/// 1. `/` → `/hoy`.
/// 2. `/dev/*` solo existe en depuración.
/// 3. Sin sesión, solo `/login` y `/restablecer`; lo demás va a `/login?desde=<ruta>` para volver después.
/// 4. Con sesión, `/login` lleva a `desde` (si es una ruta interna segura) o a `/hoy`.
/// 5. `/admin/*` exige rol admin y **no existe en Android ni iOS**.
String? redirigir({
  required Uri ubicacion,
  required EstadoSesion sesion,
  required Plataforma plataforma,
  required bool herramientasDev,
}) {
  final ruta = ubicacion.path;

  if (ruta.isEmpty || ruta == '/') {
    return Rutas.hoy;
  }

  if (Rutas.dentroDe(ruta, '/dev')) {
    if (herramientasDev) {
      return null;
    }
    return sesion.iniciada ? Rutas.hoy : Rutas.login;
  }

  final esPublica = Rutas.publicas.contains(ruta);
  if (!sesion.iniciada) {
    return esPublica ? null : Rutas.loginDesde(ubicacion.toString());
  }

  if (ruta == Rutas.login) {
    final desde = ubicacion.queryParameters['desde'];
    return destinoSeguro(desde) ?? Rutas.hoy;
  }

  if (Rutas.dentroDe(ruta, Rutas.admin) && (!plataforma.permiteAdmin || !sesion.esAdmin)) {
    return Rutas.hoy;
  }

  return null;
}

/// Acepta solo rutas internas de la app como destino después de entrar. Evita que un enlace
/// `/login?desde=https://otro-sitio` o `//otro-sitio` mande a la persona fuera de Kaizen (redirección abierta).
String? destinoSeguro(String? desde) {
  if (desde == null || desde.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(desde);
  if (uri == null || uri.hasScheme || uri.hasAuthority || !desde.startsWith('/') || desde.startsWith('//')) {
    return null;
  }
  if (Rutas.publicas.contains(uri.path) || desde.contains(r'\')) {
    return null;
  }
  return desde;
}
