import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/domain/models/frecuencia.dart';

void main() {
  // 23-nov-2026 es lunes; 28 sábado; 29 domingo.
  final lunes = DateTime.utc(2026, 11, 23);
  final viernes = DateTime.utc(2026, 11, 27);
  final sabado = DateTime.utc(2026, 11, 28);
  final domingo = DateTime.utc(2026, 11, 29);

  test('máscara del contrato: lunes = 1 … domingo = 64; L–V = 31', () {
    expect(Frecuencia.bitDe(lunes), 1);
    expect(Frecuencia.bitDe(domingo), 64);
    expect(DiasSemana.mascaraDe([1, 2, 3, 4, 5]), DiasSemana.lunesAViernes);
    expect(DiasSemana.mascaraDe([6, 7]), 96);
    expect(const DiasSemana(31).dias, [1, 2, 3, 4, 5]);
    expect(const DiasSemana(127).dias, hasLength(7));
  });

  test('día programado, igual que fn_dia_programado', () {
    const lv = DiasSemana(31);
    expect(lv.programadoEn(lunes), isTrue);
    expect(lv.programadoEn(viernes), isTrue);
    expect(lv.programadoEn(sabado), isFalse);
    expect(lv.programadoEn(domingo), isFalse);
    expect(const Diaria().programadoEn(domingo), isTrue);
    // "N por semana" no tiene días fijos: la base devuelve false para cualquier día.
    expect(const NPorSemana(3).programadoEn(lunes), isFalse);
  });

  test('JSON de ida y vuelta para los tres tipos', () {
    for (final f in const [Diaria(), DiasSemana(96), NPorSemana(4)]) {
      expect(Frecuencia.fromJson(f.toJson()), f);
      expect(f.toJson()['tipo'], f.tipo);
    }
    expect(Frecuencia.fromJson({'tipo': 'dias_semana', 'dias_semana': 31, 'veces_semana': null}), const DiasSemana(31));
    expect(() => Frecuencia.fromJson({'tipo': 'mensual'}), throwsFormatException);
  });

  test('igualdad y hash por valor', () {
    expect(const DiasSemana(31), const DiasSemana(31));
    expect(const DiasSemana(31).hashCode, const DiasSemana(31).hashCode);
    expect(const DiasSemana(31), isNot(const DiasSemana(30)));
    expect(const NPorSemana(3), isNot(const NPorSemana(2)));
    expect(const NPorSemana(3).hashCode, const NPorSemana(3).hashCode);
    expect(const Diaria().hashCode, const Diaria().hashCode);
  });
}
