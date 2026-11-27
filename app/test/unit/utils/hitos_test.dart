import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/gen/app_localizations.dart';
import 'package:kaizen/ui/hoy/consejos.dart';
import 'package:kaizen/utils/hitos.dart';

void main() {
  group('NivelRacha (doc. 05)', () {
    test('los cortes: 0 · 1–6 · 7–29 · 30–65 · 66–99 · 100+', () {
      final casos = {
        0: NivelRacha.sinRacha,
        -2: NivelRacha.sinRacha,
        1: NivelRacha.chispa,
        6: NivelRacha.chispa,
        7: NivelRacha.llama,
        29: NivelRacha.llama,
        30: NivelRacha.llamaConAro,
        65: NivelRacha.llamaConAro,
        66: NivelRacha.formado,
        99: NivelRacha.formado,
        100: NivelRacha.emblema,
        400: NivelRacha.emblema,
      };
      casos.forEach((dias, nivel) => expect(NivelRacha.deDias(dias), nivel, reason: '$dias días'));
    });
  });

  group('Hitos', () {
    test('el siguiente hito: 7, 30, 66, 100 y luego cada centena', () {
      expect(Hitos.siguiente(0), 7);
      expect(Hitos.siguiente(6), 7);
      expect(Hitos.siguiente(7), 30);
      expect(Hitos.siguiente(34), 66);
      expect(Hitos.siguiente(66), 100);
      expect(Hitos.siguiente(100), 200);
      expect(Hitos.siguiente(250), 300);
    });

    test('cruzado: solo al subir y justo en el hito', () {
      expect(Hitos.cruzado(6, 7), 7);
      expect(Hitos.cruzado(29, 30), 30);
      expect(Hitos.cruzado(65, 66), 66);
      expect(Hitos.cruzado(99, 100), 100);
      expect(Hitos.cruzado(199, 200), 200);
      expect(Hitos.cruzado(7, 8), isNull);
      expect(Hitos.cruzado(8, 7), isNull, reason: 'bajar a 7 (desmarcar) no se celebra');
      expect(Hitos.cruzado(7, 7), isNull);
      expect(Hitos.cruzado(149, 150), isNull);
    });
  });

  group('ConsejosEvidencia', () {
    test('uno distinto cada día y da la vuelta a los 14', () {
      final dia = DateTime.utc(2026, 11, 25);
      final hoy = ConsejosEvidencia.delDia(dia);
      expect(ConsejosEvidencia.delDia(dia.add(const Duration(hours: 20))), hoy, reason: 'mismo día, mismo consejo');
      expect(ConsejosEvidencia.delDia(dia.add(const Duration(days: 1))), (hoy + 1) % ConsejosEvidencia.total);
      expect(ConsejosEvidencia.delDia(dia.add(const Duration(days: ConsejosEvidencia.total))), hoy);
    });

    test('los 14 tienen texto y cita, todos distintos', () {
      final t = lookupAppLocalizations(const Locale('es'));
      final consejos = [for (var i = 0; i < ConsejosEvidencia.total; i++) ConsejosEvidencia.de(t, i)];
      expect(consejos.map((c) => c.texto).toSet(), hasLength(ConsejosEvidencia.total));
      for (final c in consejos) {
        expect(c.texto, isNotEmpty);
        expect(c.cita, matches(RegExp(r'\D+')), reason: 'cada consejo lleva su fuente');
      }
      expect(ConsejosEvidencia.de(t, ConsejosEvidencia.total).texto, consejos.first.texto);
    });
  });
}
