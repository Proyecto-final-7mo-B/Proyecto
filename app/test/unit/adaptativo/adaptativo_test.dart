import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/gen/app_localizations.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/breakpoints.dart';
import 'package:kaizen/ui/core/adaptativo/busqueda.dart';
import 'package:kaizen/ui/core/adaptativo/destinos.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';

void main() {
  final t = lookupAppLocalizations(const Locale('es'));

  test('breakpoints: < 600 compacto · 600–1199 medio · ≥ 1200 amplio', () {
    expect(TamanoPantalla.deAncho(320), TamanoPantalla.compacto);
    expect(TamanoPantalla.deAncho(599.9), TamanoPantalla.compacto);
    expect(TamanoPantalla.deAncho(600), TamanoPantalla.medio);
    expect(TamanoPantalla.deAncho(1199), TamanoPantalla.medio);
    expect(TamanoPantalla.deAncho(1200), TamanoPantalla.amplio);
    expect(TamanoPantalla.deAncho(2560), TamanoPantalla.amplio);
  });

  test('plataforma según el sistema', () {
    expect(Plataforma.desde(esWeb: true, sistema: TargetPlatform.android), Plataforma.web);
    expect(Plataforma.desde(esWeb: false, sistema: TargetPlatform.android), Plataforma.movil);
    expect(Plataforma.desde(esWeb: false, sistema: TargetPlatform.iOS), Plataforma.movil);
    expect(Plataforma.desde(esWeb: false, sistema: TargetPlatform.linux), Plataforma.escritorio);
    expect(Plataforma.desde(esWeb: false, sistema: TargetPlatform.windows), Plataforma.escritorio);
    expect(Plataforma.desde(esWeb: false, sistema: TargetPlatform.macOS), Plataforma.escritorio);
    expect(Plataforma.movil.permiteAdmin, isFalse);
    expect(Plataforma.web.permiteAdmin, isTrue);
    expect(Plataforma.movil.tieneTeclado, isFalse);
    expect(Plataforma.escritorio.tieneTeclado, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(Plataforma.actual(), Plataforma.escritorio);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(Plataforma.actual(), Plataforma.movil);
    debugDefaultTargetPlatformOverride = null;
  });

  group('destinos', () {
    List<String> rutas(Plataforma p, {bool admin = false, bool compacto = false}) =>
        destinosDe(t: t, plataforma: p, esAdmin: admin, compacto: compacto).map((d) => d.ruta).toList();

    test('barra inferior: Hoy · Hábitos · Progreso · Lab · Perfil (sin admin aunque sea admin)', () {
      expect(rutas(Plataforma.movil, compacto: true, admin: true), [
        Rutas.hoy,
        Rutas.habitos,
        Rutas.progreso,
        Rutas.laboratorio,
        Rutas.perfil,
      ]);
      final etiquetas = destinosDe(
        t: t,
        plataforma: Plataforma.movil,
        esAdmin: false,
        compacto: true,
      ).map((d) => d.etiqueta);
      expect(etiquetas, ['Hoy', 'Hábitos', 'Progreso', 'Lab', 'Perfil']);
    });

    test('riel y barra superior: 8 secciones (con Logros y Acerca de) y Admin solo para admin fuera de móvil', () {
      expect(rutas(Plataforma.escritorio), hasLength(8));
      expect(rutas(Plataforma.escritorio).last, Rutas.acerca);
      expect(rutas(Plataforma.escritorio)[6], Rutas.logros);
      expect(rutas(Plataforma.web), contains(Rutas.logros));
      expect(rutas(Plataforma.web), contains(Rutas.acerca));
      expect(rutas(Plataforma.escritorio), isNot(contains(Rutas.admin)));
      expect(rutas(Plataforma.escritorio, admin: true).last, Rutas.admin);
      expect(rutas(Plataforma.web, admin: true).last, Rutas.admin);
      expect(rutas(Plataforma.movil, admin: true), isNot(contains(Rutas.admin)), reason: 'tableta Android');
    });

    test('la escalera usa el ícono dibujado', () {
      final escalera = destinosDe(
        t: t,
        plataforma: Plataforma.web,
        esAdmin: false,
        compacto: false,
      ).firstWhere((d) => d.ruta == Rutas.escalera);
      expect(escalera.icono, isNull);
      expect(escalera, const Destino(ruta: Rutas.escalera, etiqueta: 'Escalera'));
      expect(escalera.hashCode, const Destino(ruta: Rutas.escalera, etiqueta: 'Escalera').hashCode);
    });

    test('destino elegido según la ruta (incluye subrutas)', () {
      final d = destinosDe(t: t, plataforma: Plataforma.escritorio, esAdmin: true, compacto: false);
      expect(indiceSeleccionado(d, '/hoy'), 0);
      expect(indiceSeleccionado(d, '/habitos/abc/editar'), 1);
      expect(indiceSeleccionado(d, '/logros'), 6);
      expect(indiceSeleccionado(d, '/acerca'), 7);
      expect(indiceSeleccionado(d, '/admin/indicadores'), 8);
      expect(indiceSeleccionado(d, '/perfil'), isNull, reason: 'el perfil no está en el riel');
      final m = destinosDe(t: t, plataforma: Plataforma.movil, esAdmin: false, compacto: true);
      expect(indiceSeleccionado(m, '/perfil/privacidad'), 4);
      expect(indiceSeleccionado(m, '/escalera'), isNull);
    });
  });

  test('la búsqueda filtra sin importar mayúsculas ni acentos', () {
    final opciones = destinosDe(t: t, plataforma: Plataforma.escritorio, esAdmin: false, compacto: false);
    expect(Busqueda.filtrar(opciones, 'HAB').map((d) => d.etiqueta), ['Hábitos']);
    expect(Busqueda.filtrar(opciones, 'capsu').map((d) => d.etiqueta), ['Cápsulas']);
    expect(Busqueda.filtrar(opciones, '  '), opciones);
    expect(Busqueda.filtrar(opciones, 'xyz'), isEmpty);
  });
}
