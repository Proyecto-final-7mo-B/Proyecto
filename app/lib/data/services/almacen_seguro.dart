import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dónde se guarda el token de renovación (y el usuario de la sesión, para abrir la app sin red).
///
/// - Android: Keystore · iOS/macOS: Keychain · Linux: libsecret · Windows: Credential Manager.
/// - **Web: solo en memoria** (contrato §2.1): al recargar la página hay que volver a entrar.
abstract interface class AlmacenSeguro {
  Future<String?> leer(String clave);
  Future<void> escribir(String clave, String valor);
  Future<void> borrar(String clave);
}

/// El almacén que corresponde a la plataforma.
AlmacenSeguro crearAlmacenSeguro() => kIsWeb ? AlmacenEnMemoria() : AlmacenSeguroNativo();

class AlmacenSeguroNativo implements AlmacenSeguro {
  AlmacenSeguroNativo([FlutterSecureStorage? almacen]) : _almacen = almacen ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacen;

  @override
  Future<String?> leer(String clave) => _almacen.read(key: clave);

  @override
  Future<void> escribir(String clave, String valor) => _almacen.write(key: clave, value: valor);

  @override
  Future<void> borrar(String clave) => _almacen.delete(key: clave);
}

/// Solo en memoria: web y pruebas.
class AlmacenEnMemoria implements AlmacenSeguro {
  final Map<String, String> _valores = {};

  @override
  Future<String?> leer(String clave) async => _valores[clave];

  @override
  Future<void> escribir(String clave, String valor) async => _valores[clave] = valor;

  @override
  Future<void> borrar(String clave) async => _valores.remove(clave);
}
