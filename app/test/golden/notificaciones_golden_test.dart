@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/domain/models/avisos.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';

import '../helpers/app.dart';

/// Notificaciones (Paso 10) con dos avisos propios (22:20 de lunes a viernes y 9:35 el fin de semana) y el
/// recordatorio de Leer a las 21:00.
/// Regenerar (solo si el cambio es intencional): `flutter test --update-goldens --tags golden`.
void main() {
  for (final (nombre, plataforma, tamano) in [
    ('notificaciones_movil', Plataforma.movil, const Size(390, 844)),
    ('notificaciones_escritorio', Plataforma.escritorio, const Size(1440, 900)),
  ]) {
    testWidgets(nombre, (tester) async {
      final deps = dependenciasPrueba();
      final leer = deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer');
      await tester.runAsync(() async {
        await deps.almacenLocal.guardarRecordatorio(leer.id, 21, 0);
        await deps.almacenLocal.guardarJson(
          'avisos_preferencias',
          const PreferenciasAvisos(
            personales: [
              AvisoPersonal(id: 'a', hora: (hora: 22, minuto: 20), dias: 31, texto: 'Prepara la mochila de mañana'),
              AvisoPersonal(id: 'b', hora: (hora: 9, minuto: 35), dias: 96, texto: ''),
            ],
          ).toJson(),
        );
      });
      await montarApp(
        tester,
        plataforma: plataforma,
        tamano: tamano,
        ubicacion: Rutas.notificaciones,
        dependencias: deps,
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre.png'));
    });
  }
}
