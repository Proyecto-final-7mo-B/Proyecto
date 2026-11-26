import 'package:flutter/material.dart';

import 'app.dart';
import 'config/dependencias.dart';
import 'config/entorno.dart';
import 'utils/paises_estados.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final entorno = Entorno.actual();
  final catalogo = await CatalogoRegiones.cargar();
  final dependencias = Dependencias.desdeEntorno(entorno, catalogo: catalogo);
  runApp(KaizenApp(entorno: entorno, dependencias: dependencias));
}
