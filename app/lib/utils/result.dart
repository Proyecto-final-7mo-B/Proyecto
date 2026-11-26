import '../data/services/api/errores_api.dart';

/// Resultado de una operación que puede fallar, **sin lanzar excepciones entre capas**: los repositorios devuelven
/// `Result` y los ViewModels revisan si es [Exito] o [Fallo].
///
/// ```dart
/// switch (await repo.listar()) {
///   case Exito(:final valor): ...
///   case Fallo(:final error): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.exito(T valor) = Exito<T>;
  const factory Result.fallo(ErrorApp error) = Fallo<T>;

  bool get esExito => this is Exito<T>;

  /// El valor si fue éxito; `null` si falló.
  T? get valorONulo => switch (this) {
    Exito(:final valor) => valor,
    Fallo() => null,
  };

  /// El error si falló; `null` si fue éxito.
  ErrorApp? get errorONulo => switch (this) {
    Exito() => null,
    Fallo(:final error) => error,
  };

  /// Transforma el valor si fue éxito; el error pasa igual.
  Result<R> mapear<R>(R Function(T valor) f) => switch (this) {
    Exito(:final valor) => Result.exito(f(valor)),
    Fallo(:final error) => Result.fallo(error),
  };
}

final class Exito<T> extends Result<T> {
  const Exito(this.valor);

  final T valor;

  @override
  String toString() => 'Exito($valor)';
}

final class Fallo<T> extends Result<T> {
  const Fallo(this.error);

  final ErrorApp error;

  @override
  String toString() => 'Fallo(${error.tipo.name})';
}
