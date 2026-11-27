// Base en memoria para pruebas y para el modo *fake*. En web no hay `dart:ffi`: ahí se usa la de WebAssembly.
export 'memoria_web.dart' if (dart.library.ffi) 'memoria_nativa.dart';
