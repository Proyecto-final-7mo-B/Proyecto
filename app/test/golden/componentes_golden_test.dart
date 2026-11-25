@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/widgets/calendario_mes.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/core/widgets/chips_seleccion.dart';
import 'package:kaizen/ui/core/widgets/contador_meta.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/core/widgets/mapa_calor.dart';
import 'package:kaizen/ui/core/widgets/selector_segmentado.dart';
import 'package:kaizen/ui/core/widgets/tarjeta_kaizen.dart';
import 'package:kaizen/ui/core/widgets/tarjeta_kpi.dart';
import 'package:kaizen/ui/dev/galeria_componentes.dart';

import '../helpers/envolver.dart';

/// Imágenes de referencia de los componentes clave, para detectar cambios visuales sin querer.
/// Regenerar (solo si el cambio es intencional): `flutter test --update-goldens --tags golden`.
void main() {
  Future<void> comparar(WidgetTester tester, String nombre, Widget contenido, {double ancho = 358}) async {
    final clave = GlobalKey();
    await montar(
      tester,
      RepaintBoundary(
        key: clave,
        child: Container(width: ancho, color: KaizenColores.fondo, padding: const EdgeInsets.all(16), child: contenido),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byKey(clave), matchesGoldenFile('goldens/$nombre.png'));
  }

  testWidgets('tarjeta "2 de 5"', (tester) async {
    await comparar(tester, 'tarjeta_resumen', const TarjetaResumenDemo(cumplidos: 2, total: 5));
  });

  testWidgets('filas de hábito: cumplido, con cápsula y pendiente', (tester) async {
    await comparar(
      tester,
      'filas_habito',
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilaHabito(
            icono: Icons.water_drop_outlined,
            nombre: 'Tomar agua',
            subtitulo: '2 L · diario',
            racha: 21,
            cumplido: true,
          ),
          SizedBox(height: 8),
          FilaHabito(
            icono: Icons.fitness_center,
            nombre: 'Ejercicio',
            subtitulo: '30 min · diario',
            racha: 8,
            cumplido: true,
            conCapsula: true,
          ),
          SizedBox(height: 8),
          FilaHabito(
            icono: Icons.menu_book_outlined,
            nombre: 'Leer',
            subtitulo: '10 min · Nivel 3',
            racha: 34,
            cumplido: false,
          ),
        ],
      ),
    );
  });

  testWidgets('botones', (tester) async {
    await comparar(
      tester,
      'botones',
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(onPressed: () {}, child: const Text('Guardar hábito')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(onPressed: () {}, child: const Text('Aceptar')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: () {}, child: const Text('Mantener')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock_outline),
            label: const Text('Sellar cápsula'),
          ),
          const SizedBox(height: 8),
          const FilledButton(onPressed: null, child: Text('Deshabilitado')),
          TextButton(onPressed: () {}, child: const Text('¿Olvidaste tu contraseña?')),
        ],
      ),
    );
  });

  testWidgets('calendario de octubre (bosquejo Escritorio 02)', (tester) async {
    await comparar(
      tester,
      'calendario_mes',
      TarjetaKaizen(
        child: CalendarioMes(anio: 2026, mes: 10, hoy: DateTime(2026, 10, 22), niveles: nivelesDemoOctubre),
      ),
    );
  });

  testWidgets('controles del formulario Crear hábito', (tester) async {
    await comparar(
      tester,
      'controles_formulario',
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CampoValidado(
            etiqueta: 'Nombre',
            pista: 'Leer',
            ayuda: 'Empieza pequeño: 5 minutos bastan para crear el hábito.',
          ),
          const SizedBox(height: 16),
          ChipsSeleccion<String>(
            opciones: const [
              (valor: 'a', etiqueta: 'Aprendizaje'),
              (valor: 's', etiqueta: 'Salud'),
              (valor: 'e', etiqueta: 'Ejercicio'),
              (valor: 'z', etiqueta: 'Sueño'),
            ],
            seleccionados: const {'a'},
            onCambio: (_) {},
          ),
          const SizedBox(height: 16),
          SelectorSegmentado<String>(
            opciones: const [
              (valor: 'd', etiqueta: 'Diario'),
              (valor: 'lv', etiqueta: 'L-V'),
              (valor: 'n', etiqueta: 'N por sem.'),
            ],
            seleccionado: 'd',
            onCambio: (_) {},
          ),
          const SizedBox(height: 16),
          ContadorMeta(valor: 5, unidad: 'min', onCambio: (_) {}),
        ],
      ),
    );
  });

  testWidgets('mapa de calor e indicadores (panel de admin)', (tester) async {
    await comparar(
      tester,
      'admin_kpi_mapa_calor',
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TarjetaKpi(valor: '1,204', etiqueta: 'Usuarios activos', variacion: 8),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TarjetaKpi(valor: '76 %', etiqueta: 'Cumplimiento'),
              ),
            ],
          ),
          SizedBox(height: 8),
          TarjetaKaizen(
            child: MapaCalor(
              filas: ['Ejercicio', 'Agua', 'Leer', 'Sueño'],
              columnas: ['L-M', 'J-V', 'S-D'],
              valores: [
                [0.8, 0.8, 0.3],
                [0.1, 0.3, 0.1],
                [0.1, 0.1, 0.3],
                [0.8, 0.3, 0.8],
              ],
            ),
          ),
        ],
      ),
    );
  });
}
