import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/utils/fechas.dart';

void main() {
  test('nombres de los meses en español', () {
    expect(Fechas.nombreMes(1), 'Enero');
    expect(Fechas.nombreMes(10), 'Octubre');
    expect(Fechas.nombreMes(12), 'Diciembre');
    expect(() => Fechas.nombreMes(0), throwsRangeError);
    expect(() => Fechas.nombreMes(13), throwsRangeError);
  });

  test('la semana empieza en lunes (L M M J V S D)', () {
    expect(Fechas.inicialesSemana, ['L', 'M', 'M', 'J', 'V', 'S', 'D']);
    expect(Fechas.diasSemana.first, 'lunes');
    expect(Fechas.diasSemana.last, 'domingo');
  });

  test('días de cada mes, con bisiestos', () {
    expect(Fechas.diasDelMes(2026, 10), 31);
    expect(Fechas.diasDelMes(2026, 11), 30);
    expect(Fechas.diasDelMes(2026, 2), 28);
    expect(Fechas.diasDelMes(2028, 2), 29);
    expect(Fechas.diasDelMes(2100, 2), 28);
    expect(Fechas.diasDelMes(2026, 12), 31);
  });

  test('desfase de la cuadrícula: octubre de 2026 empieza en jueves, como en el bosquejo', () {
    expect(Fechas.desfaseLunes(2026, 10), 3);
    expect(Fechas.desfaseLunes(2026, 6), 0); // 1 de junio de 2026 es lunes
    expect(Fechas.desfaseLunes(2026, 11), 6); // 1 de noviembre de 2026 es domingo
  });

  test('día y mes', () {
    expect(Fechas.diaYMes(8, 11), '8 de noviembre');
  });
}
