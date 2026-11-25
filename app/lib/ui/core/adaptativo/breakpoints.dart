import 'package:flutter/widgets.dart';

/// Tamaños de pantalla (los de Material 3).
enum TamanoPantalla {
  /// < 600 px: teléfono. Barra inferior.
  compacto,

  /// 600–1199 px: tableta o ventana mediana. Riel lateral angosto.
  medio,

  /// ≥ 1200 px: escritorio. Riel extendido (escritorio) o barra superior (web).
  amplio;

  static const double limiteMedio = 600;
  static const double limiteAmplio = 1200;

  static TamanoPantalla deAncho(double ancho) {
    if (ancho < limiteMedio) {
      return TamanoPantalla.compacto;
    }
    return ancho < limiteAmplio ? TamanoPantalla.medio : TamanoPantalla.amplio;
  }

  static TamanoPantalla de(BuildContext context) => deAncho(MediaQuery.sizeOf(context).width);
}

/// Ancho máximo del contenido en pantallas amplias (bosquejos web: 1200 px centrados).
const double anchoMaximoContenido = 1200;
