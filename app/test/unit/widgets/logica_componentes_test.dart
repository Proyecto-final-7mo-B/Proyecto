import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/widgets/anillo_progreso.dart';
import 'package:kaizen/ui/core/widgets/barra_progreso.dart';
import 'package:kaizen/ui/core/widgets/barra_semana.dart';
import 'package:kaizen/ui/core/widgets/calendario_mes.dart';
import 'package:kaizen/ui/core/widgets/chips_seleccion.dart';
import 'package:kaizen/ui/core/widgets/contador_meta.dart';
import 'package:kaizen/ui/core/widgets/mapa_calor.dart';
import 'package:kaizen/ui/core/widgets/tarjeta_kaizen.dart';
import 'package:kaizen/ui/core/widgets/tarjeta_kpi.dart';

/// Lógica pura de los componentes (sin dibujar).
void main() {
  group('ChipsSeleccion.alTocar', () {
    const opciones = [
      (valor: 7, etiqueta: '7 días'),
      (valor: 21, etiqueta: '21 días'),
      (valor: 66, etiqueta: '66 días'),
    ];
    ChipsSeleccion<int> chips(Set<int> sel, {bool multiple = false, bool vacio = false}) => ChipsSeleccion<int>(
      opciones: opciones,
      seleccionados: sel,
      onCambio: (_) {},
      multiple: multiple,
      permitirVacio: vacio,
    );

    test('una sola: tocar otra la reemplaza', () => expect(chips({7}).alTocar(21), {21}));
    test('una sola: tocar la elegida no la quita (sin vacío)', () => expect(chips({7}).alTocar(7), {7}));
    test('una sola con vacío: tocar la elegida la quita', () => expect(chips({7}, vacio: true).alTocar(7), <int>{}));
    test('varias: agrega y quita', () {
      expect(chips({7}, multiple: true).alTocar(21), {7, 21});
      expect(chips({7, 21}, multiple: true).alTocar(7), {21});
    });
    test('varias: no deja quitar la última (días de la semana nunca vacíos)', () {
      expect(chips({7}, multiple: true).alTocar(7), {7});
      expect(chips({7}, multiple: true, vacio: true).alTocar(7), <int>{});
    });
  });

  group('formatos', () {
    test('meta sin ".0" y con decimales de la Escalera (+10 %)', () {
      expect(ContadorMeta.formatoNumero(5), '5');
      expect(ContadorMeta.formatoNumero(5.0), '5');
      expect(ContadorMeta.formatoNumero(8.5), '8.5');
      expect(ContadorMeta.formatoNumero(16.5), '16.5');
      expect(ContadorMeta.formatoNumero(10.25), '10.25');
    });

    test('variación de un KPI con signo y color', () {
      expect(TarjetaKpi.formatoVariacion(8), '+8 %');
      expect(TarjetaKpi.formatoVariacion(-2.5), '−2.5 %');
      expect(TarjetaKpi.formatoVariacion(0), '0 %');
      expect(TarjetaKpi.colorVariacion(8), KaizenColores.azul600);
      expect(TarjetaKpi.colorVariacion(-1), KaizenColores.error);
    });

    test('valor del mapa de calor con signo', () {
      expect(MapaCalor.formatoConSigno(0.8), '+0.8');
      expect(MapaCalor.formatoConSigno(-0.34), '−0.3');
      expect(MapaCalor.formatoConSigno(0), '0.0');
    });
  });

  group('niveles e intensidad', () {
    test('mapa de calor: valor → nivel 0–4 dentro del rango', () {
      const mapa = MapaCalor(filas: [], columnas: [], valores: []);
      expect(mapa.nivelDe(-1), 0);
      expect(mapa.nivelDe(0), 2);
      expect(mapa.nivelDe(1), 4);
      expect(mapa.nivelDe(0.8), 4);
      expect(mapa.nivelDe(0.3), 3);
      expect(mapa.nivelDe(5), 4, reason: 'fuera de rango se recorta');
      const roto = MapaCalor(filas: [], columnas: [], valores: [], minimo: 1, maximo: 1);
      expect(roto.nivelDe(1), 0, reason: 'rango vacío no divide entre cero');
    });

    test('calendario: día sin dato = nivel 0; recorta a 0–4', () {
      const cal = CalendarioMes(anio: 2026, mes: 10, niveles: {1: 3, 2: 9, 3: -1});
      expect(cal.nivelDe(1), 3);
      expect(cal.nivelDe(2), 4);
      expect(cal.nivelDe(3), 0);
      expect(cal.nivelDe(15), 0);
    });

    test('semana: escala propia sobre la tarjeta oscura; null en blanco', () {
      const clara = BarraSemana(niveles: [0, 1, 2, 3, 4, null, null]);
      const oscura = BarraSemana(niveles: [0, 1, 2, 3, 4, null, null], sobreOscuro: true);
      expect(clara.colorDe(4), KaizenColores.marino800);
      expect(oscura.colorDe(4), KaizenColores.azul600, reason: 'marino800 no se vería sobre marino800');
      expect(oscura.colorDe(0), KaizenColores.superficie);
      expect(clara.colorDe(null), KaizenColores.superficie);
    });

    test('barras y anillo recortan el progreso a 0–1 (y NaN = 0)', () {
      expect(const BarraProgreso(valor: 1.7).valorRecortado, 1);
      expect(const BarraProgreso(valor: -0.2).valorRecortado, 0);
      expect(const BarraProgreso(valor: double.nan).valorRecortado, 0);
      expect(const AnilloProgreso(valor: 2).valorRecortado, 1);
      expect(const BarraProgreso(valor: 0.5, sobreOscuro: true).colorBarra, KaizenColores.superficie);
      expect(const BarraProgreso(valor: 0.5, sobreOscuro: true).colorPista, KaizenColores.marino700);
    });

    test('estilos de tarjeta', () {
      expect(const TarjetaKaizen(child: SizedBox()).colorFondo, KaizenColores.superficie);
      expect(
        const TarjetaKaizen(estilo: EstiloTarjeta.destacada, child: SizedBox()).colorFondo,
        KaizenColores.marino800,
      );
      expect(const TarjetaKaizen(estilo: EstiloTarjeta.suave, child: SizedBox()).colorFondo, KaizenColores.azul100);
    });
  });
}
