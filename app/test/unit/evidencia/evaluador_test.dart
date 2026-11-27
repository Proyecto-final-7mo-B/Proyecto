// Pruebas del evaluador de la app con los MISMOS casos que db/cambios/pruebas_evidencia.sql (sección 2):
// la app y la base deben dar la misma zona y la misma meta sugerida.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/fake/catalogo_demo.dart';
import 'package:kaizen/domain/models/categoria.dart';
import 'package:kaizen/domain/models/evidencia.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/ui/habitos/view_models/estadisticas_habito.dart';
import 'package:kaizen/utils/evidencia.dart';

void main() {
  final catalogo = [
    for (final c in jsonDecode(catalogoDemoJson) as List<dynamic>) Categoria.fromJson(c as Map<String, dynamic>),
  ];
  Subcategoria sub(String clave) => catalogo.todasLasSubcategorias.firstWhere((s) => s.clave == clave);

  /// "zona|meta_sugerida", igual que `pg_temp.ev` en las pruebas SQL.
  String ev(String clave, String unidad, double meta, [Frecuencia f = const Diaria()]) {
    final e = EvaluadorEvidencia.evaluar(sub(clave), unidad, meta, f);
    final zona = switch (e.zona) {
      ZonaEvidencia.sinReferencia => 'sin_referencia',
      final z => z.name,
    };
    final s = e.metaSugerida;
    return '$zona|${s == null ? '-' : s.toStringAsFixed(2)}';
  }

  group('zonas (mismos casos que la base)', () {
    test('actividad física (OMS 2020; Lee 2022)', () {
      expect(ev('aerobico_moderado', 'min', 30), 'optimo|-', reason: '210 min/semana');
      expect(ev('aerobico_moderado', 'min', 50), 'alto|-', reason: '350: sin pedir bajar');
      expect(ev('aerobico_moderado', 'min', 120), 'excesivo|85.00', reason: '2 h/día → 600/7 = 85');
      expect(ev('aerobico_moderado', 'h', 3), 'excesivo|1.25');
      expect(ev('aerobico_moderado', 'min', 10), 'bajo|25.00');
      expect(ev('aerobico_moderado', 'min', 45, const NPorSemana(3)), 'bajo|50.00');
      expect(ev('vigoroso', 'min', 60), 'excesivo|40.00');
    });

    test('salud: agua, sueño, azúcar, alcohol y tabaco', () {
      expect(ev('hidratacion', 'vasos', 8), 'optimo|-');
      expect(ev('hidratacion', 'vasos', 20), 'excesivo|16.00');
      expect(ev('sueno', 'h', 11), 'excesivo|10.00');
      expect(ev('sueno', 'h', 6), 'bajo|7.00');
      expect(ev('reducir_alcohol', 'bebidas', 1), 'excesivo|1.00');
      expect(ev('reducir_alcohol', 'bebidas', 1, const NPorSemana(2)), 'optimo|-');
      expect(ev('reducir_azucar', 'g', 40), 'alto|25.00');
      expect(ev('dejar_fumar', 'cigarros', 5), 'alto|1.00');
    });

    test('educación y bienestar', () {
      expect(ev('meditacion', 'min', 60), 'excesivo|45.00');
      expect(ev('lectura', 'páginas', 20), 'bajo|24.00');
      expect(ev('estudio', 'min', 300), 'excesivo|240.00', reason: 'Ericsson: ≈4 h/día');
    });

    test('sin referencia: km y subcategorías sin rango', () {
      expect(ev('aerobico_moderado', 'km', 3), 'sin_referencia|-');
      expect(ev('reducir_pantallas', 'min', 120), 'sin_referencia|-');
      expect(ev('ahorro', 'pesos', 50), 'sin_referencia|-');
    });

    test('rangos por sesión, con la cita y el piso', () {
      final e = EvaluadorEvidencia.evaluar(sub('aerobico_moderado'), 'min', 30, const Diaria());
      expect((e.optimoDesde, e.optimoHasta, e.maximo), (21.43, 42.86, 85.71));
      expect(e.cita, startsWith('OMS 2020'));
      expect(e.confianza, Confianza.alta);
      expect(e.volumen, 210);
      expect(EvaluadorEvidencia.evaluar(sub('sueno'), 'h', 7, const Diaria()).piso, 7);
      expect(EvaluadorEvidencia.evaluar(sub('hidratacion'), 'vasos', 8, const Diaria()).piso, 6);
    });
  });

  group('auxiliares', () {
    test('sesiones por semana', () {
      expect(EvaluadorEvidencia.sesionesSemana(const Diaria()), 7);
      expect(EvaluadorEvidencia.sesionesSemana(const DiasSemana(DiasSemana.lunesAViernes)), 5);
      expect(EvaluadorEvidencia.sesionesSemana(const DiasSemana(96)), 2);
      expect(EvaluadorEvidencia.sesionesSemana(const NPorSemana(3)), 3);
    });

    test('redondeo al paso (fn_redondear_paso), sin errores de punto flotante', () {
      expect(EvaluadorEvidencia.redondearPaso(8.5, 1), 9);
      expect(EvaluadorEvidencia.redondearPaso(21.43, 5, modo: Redondeo.arriba), 25);
      expect(EvaluadorEvidencia.redondearPaso(85.71, 5, modo: Redondeo.abajo), 85);
      expect(EvaluadorEvidencia.redondearPaso(0.3, 0.1, modo: Redondeo.abajo), 0.3);
      expect(EvaluadorEvidencia.redondearPaso(0.3, 0.1, modo: Redondeo.arriba), 0.3);
    });

    test('meta inicial: el inicio de lo recomendado, o el límite en "reducir", dentro de la captura', () {
      final aerobico = sub('aerobico_moderado');
      expect(EvaluadorEvidencia.metaInicial(aerobico, aerobico.unidad('min')!, const Diaria()), 25);
      expect(EvaluadorEvidencia.metaInicial(aerobico, aerobico.unidad('min')!, const NPorSemana(3)), 50);
      expect(EvaluadorEvidencia.metaInicial(aerobico, aerobico.unidad('km')!, const Diaria()), 0.5);
      final azucar = sub('reducir_azucar');
      expect(EvaluadorEvidencia.metaInicial(azucar, azucar.unidad('g')!, const Diaria()), 25);
      final pasos = sub('pasos');
      expect(EvaluadorEvidencia.metaInicial(pasos, pasos.unidad('pasos')!, const Diaria()), 8000);
    });

    test('proyección de la Escalera v2: +10 % al paso, al menos un paso, ≤ +30 %, sin pasar del techo', () {
      expect(EstadisticasHabito.proyeccionConEvidencia(20, paso: 5), [25, 30, 35, 40]);
      expect(EstadisticasHabito.proyeccionConEvidencia(100, paso: 5), [110, 120, 130, 145]);
      expect(EstadisticasHabito.proyeccionConEvidencia(1, paso: 1, cuantos: 2), [2, 3], reason: 'un solo paso');
      expect(EstadisticasHabito.proyeccionConEvidencia(6.75, paso: 0.25, techo: 9), [7.5, 8.25, 9]);
      expect(EstadisticasHabito.proyeccionConEvidencia(9, paso: 0.25, techo: 9), isEmpty);
    });
  });
}
