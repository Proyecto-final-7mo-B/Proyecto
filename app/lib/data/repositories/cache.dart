import '../../utils/result.dart';
import '../services/api/errores_api.dart';
import '../sync/sincronizador.dart';

/// Avisa si una petición llegó al servidor (`true`) o falló por red (`false`); lo usa el aviso "Sin conexión".
typedef ReportarRed = void Function(bool llego);

/// Lectura con caché: primero el servidor; si responde, se guarda la copia local. Si falla **por red**, se usa la
/// copia local ([local] devuelve `null` si no hay nada guardado, y entonces se regresa el error original).
Future<Result<T>> leerConCache<T>({
  required Future<Result<T>> Function() remoto,
  required Future<void> Function(T valor) guardar,
  required Future<T?> Function() local,
  ReportarRed? reportar,
}) async {
  final r = await remoto();
  switch (r) {
    case Exito(:final valor):
      reportar?.call(true);
      await guardar(valor);
      return r;
    case Fallo(:final error) when Sincronizador.esDeRed(error):
      reportar?.call(false);
      final copia = await local();
      return copia == null ? r : Result.exito(copia);
    case Fallo():
      reportar?.call(true);
      return r;
  }
}

/// Para las escrituras que exigen servidor (crear o editar un hábito): solo avisa si llegó o no.
Future<Result<T>> escribirEnServidor<T>(Future<Result<T>> Function() remoto, ReportarRed? reportar) async {
  final r = await remoto();
  reportar?.call(r is Exito || !Sincronizador.esDeRed(r.errorONulo ?? const ErrorApp(TipoError.desconocido)));
  return r;
}
