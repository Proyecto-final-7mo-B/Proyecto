import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/ui/habitos/view_models/estadisticas_habito.dart';

DateTime d(int dia, [int mes = 11]) => DateTime.utc(2026, mes, dia);

Registro reg(DateTime fecha, {bool cumplido = true, double? valor}) => Registro(
  id: 'r-${fecha.toIso8601String()}',
  habitoId: 'h',
  fecha: fecha,
  cumplido: cumplido,
  valor: valor,
  origen: OrigenRegistro.rapido,
);

Map<DateTime, Registro> regs(Iterable<Registro> lista) => {for (final r in lista) r.fecha: r};

void main() {
  group('cumplimiento', () {
    test('diario: cumplidos ÷ días del periodo', () {
      final r = regs([reg(d(2)), reg(d(3)), reg(d(4), cumplido: false)]);
      // 2 a 5 de noviembre = 4 días, 2 cumplidos.
      expect(
        EstadisticasHabito.cumplimiento(
          frecuencia: const Diaria(),
          registros: r,
          desde: d(2),
          hasta: d(5),
          creado: d(1),
        ),
        50,
      );
    });

    test('días de la semana: solo cuentan los programados (L-V)', () {
      // Semana del lunes 16 al domingo 22: 5 programados; se cumplieron lunes, martes y el sábado (no cuenta).
      final r = regs([reg(d(16)), reg(d(17)), reg(d(21))]);
      expect(
        EstadisticasHabito.cumplimiento(
          frecuencia: const DiasSemana(DiasSemana.lunesAViernes),
          registros: r,
          desde: d(16),
          hasta: d(22),
          creado: d(1),
        ),
        40,
      );
    });

    test('"N por semana": cumplidos ÷ (N × semanas), máximo 100 %', () {
      final semana = regs([reg(d(16)), reg(d(18))]);
      expect(
        EstadisticasHabito.cumplimiento(
          frecuencia: const NPorSemana(4),
          registros: semana,
          desde: d(16),
          hasta: d(22),
          creado: d(1),
        ),
        50,
      );
      final demasiados = regs([for (var i = 16; i <= 22; i++) reg(d(i))]);
      expect(
        EstadisticasHabito.cumplimiento(
          frecuencia: const NPorSemana(3),
          registros: demasiados,
          desde: d(16),
          hasta: d(22),
          creado: d(1),
        ),
        100,
      );
    });

    test('no cuenta los días antes de crear el hábito; null si aún no existía', () {
      final r = regs([reg(d(20)), reg(d(21))]);
      expect(
        EstadisticasHabito.cumplimiento(
          frecuencia: const Diaria(),
          registros: r,
          desde: d(1),
          hasta: d(21),
          creado: d(20),
        ),
        100,
      );
      expect(
        EstadisticasHabito.cumplimiento(
          frecuencia: const Diaria(),
          registros: r,
          desde: d(1),
          hasta: d(10),
          creado: d(20),
        ),
        isNull,
      );
    });

    test('sin días programados en el periodo → null', () {
      expect(
        EstadisticasHabito.cumplimiento(
          frecuencia: const DiasSemana(96), // sábado y domingo
          registros: const {},
          desde: d(16),
          hasta: d(20),
          creado: d(1),
        ),
        isNull,
      );
    });
  });

  test('intensidad del calendario por día', () {
    final r = regs([
      reg(d(1)),
      reg(d(2), valor: 10),
      reg(d(3), valor: 5),
      reg(d(4), valor: 0.5),
      reg(d(5), cumplido: false),
      reg(d(30, 10)),
    ]);
    expect(EstadisticasHabito.nivelesMes(registros: r, anio: 2026, mes: 11, meta: 10), {1: 4, 2: 4, 3: 2, 4: 1, 5: 0});
  });

  test('tendencia: una cifra por semana, de la más antigua a la actual, sin semanas antes de crear', () {
    // Diario, creado el lunes 9; hoy es el miércoles 25.
    final r = regs([
      for (var i = 9; i <= 15; i++) reg(d(i)), // semana 1: 100 %
      for (var i = 16; i <= 18; i++) reg(d(i)), // semana 2: 3 de 7
      reg(d(23)), // semana actual (23 a 25): 1 de 3
    ]);
    final t = EstadisticasHabito.tendencia(frecuencia: const Diaria(), registros: r, hoy: d(25), creado: d(9));
    expect(t, hasLength(3));
    expect(t[0], 100);
    expect(t[1], closeTo(100 * 3 / 7, 1e-9));
    expect(t[2], closeTo(100 / 3, 1e-9));
  });

  test('proyección de la Escalera: +10 % por nivel con 2 decimales', () {
    expect(EstadisticasHabito.proyeccion(10), [11, 12.1]);
    expect(EstadisticasHabito.proyeccion(5, cuantos: 4), [5.5, 6.05, 6.66, 7.33]);
    expect(EstadisticasHabito.proyeccion(2, cuantos: 0), isEmpty);
  });
}
