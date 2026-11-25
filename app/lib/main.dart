import 'package:flutter/material.dart';

import 'app.dart';
import 'config/entorno.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KaizenApp(entorno: Entorno.actual()));
}
