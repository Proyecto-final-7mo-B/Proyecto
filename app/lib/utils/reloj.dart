/// De dónde sale "ahora". La app usa el del dispositivo; las pruebas fijan uno para que "hoy" no cambie cada día.
typedef Reloj = DateTime Function();

/// El reloj real del dispositivo.
DateTime relojDelSistema() => DateTime.now();
