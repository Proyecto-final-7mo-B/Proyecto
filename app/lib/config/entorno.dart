/// Configuración que llega al compilar con `--dart-define` (nunca secretos: solo direcciones y modos).
///
/// ```bash
/// flutter run --dart-define=KAIZEN_FUENTE=fake
/// flutter run --dart-define=KAIZEN_FUENTE=api --dart-define=API_BASE_URL=http://localhost:8000/api/v1
/// ```
library;

/// De dónde salen los datos de la app.
enum FuenteDatos {
  /// Repositorios en memoria con los mismos JSON del contrato (desarrollo y pruebas, sin red).
  fake,

  /// La API REST real.
  api;

  /// Interpreta el valor de `KAIZEN_FUENTE`. Cualquier valor desconocido usa la API:
  /// así un build de producción nunca queda con datos de prueba por error.
  static FuenteDatos desde(String valor) => switch (valor.trim().toLowerCase()) {
    'fake' => FuenteDatos.fake,
    _ => FuenteDatos.api,
  };
}

/// URL de la API en producción (Nginx en nodo1).
const String apiProduccion = 'https://proyecto-kaizen.northcentralus.cloudapp.azure.com/api/v1';

/// Valores tal como llegan de `--dart-define` (constantes de compilación).
const String _fuenteDefinida = String.fromEnvironment('KAIZEN_FUENTE', defaultValue: 'api');
const String _apiDefinida = String.fromEnvironment('API_BASE_URL', defaultValue: apiProduccion);
const String _zonaDefinida = String.fromEnvironment('KAIZEN_ZONA_DEFECTO', defaultValue: 'America/Mexico_City');

/// Configuración efectiva de la app.
class Entorno {
  const Entorno({required this.fuente, required this.apiBaseUrl, required this.zonaHorariaDefecto});

  /// La que se usa al ejecutar la app.
  factory Entorno.actual() =>
      Entorno.desdeValores(fuente: _fuenteDefinida, apiBaseUrl: _apiDefinida, zonaHorariaDefecto: _zonaDefinida);

  /// Construye la configuración a partir de valores en texto (se usa en las pruebas).
  factory Entorno.desdeValores({
    required String fuente,
    required String apiBaseUrl,
    required String zonaHorariaDefecto,
  }) {
    final url = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Entorno(
      fuente: FuenteDatos.desde(fuente),
      apiBaseUrl: url.isEmpty ? apiProduccion : url,
      zonaHorariaDefecto: zonaHorariaDefecto.trim().isEmpty ? 'America/Mexico_City' : zonaHorariaDefecto.trim(),
    );
  }

  final FuenteDatos fuente;

  /// Sin `/` al final: los repositorios agregan la ruta (`$apiBaseUrl/habitos`).
  final String apiBaseUrl;

  /// Zona IANA que se usa si el dispositivo no reporta la suya (contrato §1.1).
  final String zonaHorariaDefecto;

  bool get usaFakes => fuente == FuenteDatos.fake;
}
