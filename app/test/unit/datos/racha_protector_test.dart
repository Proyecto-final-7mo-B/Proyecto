// El protector de racha del modo fake da lo mismo que fn_rachas (db/cambios/pruebas_evidencia.sql, sección 4).
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/utils/fechas.dart';

void main() {
  // Miércoles 25-nov-2026: el lunes de hace dos semanas es el 9-nov.
  final ahora = DateTime.utc(2026, 11, 25, 15, 30);
  late DatosDemo datos;
  final lunes = DateTime.utc(2026, 11, 9);

  setUp(() => datos = DatosDemo(reloj: () => ahora));

  HabitoDemo habito() {
    final sub = datos.subcategoriaPorClave('pasos');
    final h = HabitoDemo(
      id: datos.nuevoId(),
      usuarioId: 'u-demo',
      nombre: 'Pasos',
      unidad: 'pasos',
      meta: 8000,
      nivel: 1,
      subcategoriaId: sub.id,
      categoriaId: datos.categorias.firstWhere((c) => c.clave == 'ejercicio').id,
      frecuencia: const Diaria(),
      escaleraActiva: true,
      activo: true,
      fechaCreacion: DateTime.utc(2026, 10, 15),
    );
    datos.habitos[h.id] = h;
    return h;
  }

  /// Cumple los días [0, 13] desde el lunes, salvo los de [faltan]. Hasta el martes 24 (ayer) y hoy (miércoles) sin
  /// check-in todavía.
  void registrar(HabitoDemo h, {required Set<int> faltan, int hasta = 15}) {
    final regs = datos.registros.putIfAbsent(h.id, () => {});
    for (var i = 0; i <= hasta; i++) {
      if (faltan.contains(i)) {
        continue;
      }
      final d = lunes.add(Duration(days: i));
      regs[d] = Registro(
        id: datos.nuevoId(),
        habitoId: h.id,
        fecha: d,
        cumplido: true,
        valor: 8000,
        origen: OrigenRegistro.manual,
        registradoEn: d,
      );
    }
  }

  test('una falla en la semana: la racha sigue (no suma ese día)', () {
    final h = habito();
    registrar(h, faltan: {2});
    expect(datos.racha(h).actual, 15, reason: '16 días (9 al 24) menos el miércoles protegido');
  });

  test('dos fallas en la misma semana: la racha se rompe en la segunda', () {
    final h = habito();
    registrar(h, faltan: {2, 4});
    expect(datos.racha(h).actual, 11, reason: 'desde el sábado 14 hasta el martes 24');
  });

  test('una falla en cada semana: se perdonan las dos', () {
    final h = habito();
    registrar(h, faltan: {2, 9});
    expect(datos.racha(h).actual, 14);
  });

  test('protegida esta semana: un día sin registro en la semana actual', () {
    final h = habito();
    registrar(h, faltan: {15}); // martes 24 (ayer)
    final r = datos.racha(h);
    expect(r.actual, 15);
    expect(r.protegidaEstaSemana, isTrue);
    expect(Fechas.inicioSemana(datos.hoy), DateTime.utc(2026, 11, 23));
    expect(datos.racha(habito()..nombre = 'otro').protegidaEstaSemana, isFalse);
  });

  test('las rachas de demo se conservan con el protector (dos fallas en la misma semana antes de cada racha)', () {
    final demo = {for (final h in datos.habitosDe('u-demo')) h.nombre: datos.racha(h).actual};
    expect(demo['Tomar agua'], 21);
    expect(demo['Ejercicio'], 8);
    expect(demo['Leer'], 34);
    expect(demo['Dormir 7 h'], 2);
  });
}
