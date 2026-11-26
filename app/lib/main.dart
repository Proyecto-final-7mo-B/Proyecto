import 'package:flutter/material.dart';

import 'app.dart';
import 'config/dependencias.dart';
import 'config/entorno.dart';
import 'data/services/servicio_sesion.dart';
import 'routing/estado_sesion.dart';
import 'utils/paises_estados.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final entorno = Entorno.actual();
  final catalogo = await CatalogoRegiones.cargar();
  final dependencias = Dependencias.desdeEntorno(entorno, catalogo: catalogo);
  final sesion = EstadoSesion();
  final servicio = ServicioSesion(auth: dependencias.auth, tokens: dependencias.tokens, estado: sesion);
  // Si quedó una sesión guardada, la abre antes de mostrar la primera pantalla (sin red, con el usuario guardado).
  await servicio.restaurar();
  runApp(KaizenApp(entorno: entorno, dependencias: dependencias, sesion: sesion, servicioSesion: servicio));
}
