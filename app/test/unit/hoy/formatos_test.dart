import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/domain/models/categoria.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/l10n/gen/app_localizations.dart';
import 'package:kaizen/ui/core/formatos.dart';
import 'package:kaizen/utils/intensidad.dart';
import 'package:kaizen/utils/reloj.dart';

void main() {
  late AppLocalizations t;
  setUpAll(() async => t = await AppLocalizations.delegate.load(const Locale('es')));

  Habito habito({double meta = 2, String unidad = 'L', Frecuencia frecuencia = const Diaria(), int nivel = 1}) =>
      Habito(
        id: 'h1',
        nombre: 'Tomar agua',
        categoria: const Categoria(id: 'cat-salud', clave: 'salud', nombre: 'Salud'),
        subcategoria: const Subcategoria(
          id: 'sub-hidratacion',
          clave: 'hidratacion',
          nombre: 'Hidratación',
          icono: 'water_drop',
        ),
        frecuencia: frecuencia,
        meta: meta,
        unidad: unidad,
        nivel: nivel,
        escaleraActiva: true,
        activo: true,
        racha: const Racha(actual: 0, maxima: 0),
        fechaCreacion: DateTime.utc(2026, 11),
      );

  test('frecuencia en palabras', () {
    expect(textoFrecuencia(const Diaria(), t), 'diario');
    expect(textoFrecuencia(const DiasSemana(127), t), 'diario');
    expect(textoFrecuencia(const DiasSemana(DiasSemana.lunesAViernes), t), 'L-V');
    expect(textoFrecuencia(const DiasSemana(96), t), 'S-D');
    expect(textoFrecuencia(const DiasSemana(1 | 4 | 16), t), 'L, Mi, V');
    expect(textoFrecuencia(const NPorSemana(3), t), '3 por semana');
    expect(textoFrecuencia(const NPorSemana(1), t), '1 vez por semana');
  });

  test('subtítulo del hábito como en el bosquejo', () {
    expect(subtituloHabito(habito(), t), '2 L · diario');
    expect(
      subtituloHabito(habito(meta: 20, unidad: 'min', frecuencia: const DiasSemana(DiasSemana.lunesAViernes)), t),
      '20 min · L-V',
    );
    expect(subtituloHabito(habito(meta: 10, unidad: 'min', nivel: 3), t), '10 min · Nivel 3');
    expect(subtituloHabito(habito(meta: 8.5, unidad: 'min'), t), '8.5 min · diario');
  });

  test('saludo según la hora, con el primer nombre', () {
    expect(saludo(DateTime(2026, 11, 25, 5), 'Daniela Demo', t), 'Buenos días, Daniela');
    expect(saludo(DateTime(2026, 11, 25, 11, 59), 'Daniela', t), 'Buenos días, Daniela');
    expect(saludo(DateTime(2026, 11, 25, 12), 'Daniela', t), 'Buenas tardes, Daniela');
    expect(saludo(DateTime(2026, 11, 25, 18, 59), 'Daniela', t), 'Buenas tardes, Daniela');
    expect(saludo(DateTime(2026, 11, 25, 19), 'Daniela', t), 'Buenas noches, Daniela');
    expect(saludo(DateTime(2026, 11, 25, 4, 59), '  Lucía  Latam ', t), 'Buenas noches, Lucía');
  });

  test('intensidad 0–4 del calendario y la semana', () {
    expect(nivelDeCumplimiento(0), 0);
    expect(nivelDeCumplimiento(-5), 0);
    expect(nivelDeCumplimiento(1), 1);
    expect(nivelDeCumplimiento(34.9), 1);
    expect(nivelDeCumplimiento(35), 2);
    expect(nivelDeCumplimiento(69.9), 2);
    expect(nivelDeCumplimiento(70), 3);
    expect(nivelDeCumplimiento(99.9), 3);
    expect(nivelDeCumplimiento(100), 4);
  });

  test('el reloj del sistema es la hora del dispositivo', () {
    expect(relojDelSistema().difference(DateTime.now()).inSeconds.abs(), lessThan(5));
  });
}
