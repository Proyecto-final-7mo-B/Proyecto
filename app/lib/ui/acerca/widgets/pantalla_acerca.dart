import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/categorias/categorias_repository.dart';
import '../../../domain/models/categoria.dart';
import '../../../domain/models/recomendacion.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../../utils/hitos.dart';
import '../../core/apariencia_habito.dart';
import '../../core/formatos.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/boton_volver.dart';
import '../../core/widgets/chips_seleccion.dart';
import '../../core/widgets/encabezado_pantalla.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../../habitos/widgets/panel_evidencia.dart';
import '../view_models/acerca_viewmodel.dart';

/// `/acerca` (decisiones del 27-nov): "Acerca de Kaizen", una sección del riel de escritorio y de la barra superior
/// de web. En el teléfono se abre desde Nuevo hábito y desde el detalle del hábito ("¿En qué nos basamos?").
///
/// - Portada: por qué hacemos Kaizen y tres cifras (66 días, rangos, fuentes).
/// - Cómo funciona: formación de hábitos, creación, Escalera, rachas y colores, en tarjetas con ícono.
/// - Rangos recomendados: una tarjeta por categoría, con su color, de `GET /categorias`.
/// - Fuentes: filtro por tema y tarjetas que se abren, con su nivel de confianza, de `GET /fuentes`.
class PantallaAcerca extends StatefulWidget {
  const PantallaAcerca({super.key});

  /// Ancho máximo del contenido, para que se lea cómodo en escritorio.
  static const double anchoLectura = 960;

  /// Desde este ancho: encabezado de escritorio y "Cómo funciona" en dos columnas.
  static const double anchoEscritorio = 760;

  @override
  State<PantallaAcerca> createState() => _PantallaAcercaState();
}

class _PantallaAcercaState extends State<PantallaAcerca> {
  late final AcercaViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AcercaViewModel(categorias: context.read<CategoriasRepository>());
    _vm.cargar.ejecutar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  static String nombreTema(String tema, AppLocalizations t) => switch (tema) {
    'formacion' => t.temaFormacion,
    'actividad' => t.temaActividad,
    'salud' => t.temaSalud,
    'educacion' => t.temaEducacion,
    'bienestar' => t.temaBienestar,
    'color' => t.temaColor,
    _ => t.temaNotificaciones,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, limites) {
        final ancho = limites.maxWidth >= PantallaAcerca.anchoEscritorio;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: PantallaAcerca.anchoLectura),
            child: ListenableBuilder(
              listenable: Listenable.merge([_vm, _vm.cargar]),
              builder: (context, _) => ListView(
                padding: ancho
                    ? const EdgeInsets.fromLTRB(KaizenMedidas.e32, 28, KaizenMedidas.e32, KaizenMedidas.e32)
                    : const EdgeInsets.fromLTRB(KaizenMedidas.e20, KaizenMedidas.e24, KaizenMedidas.e20, KaizenMedidas.e32),
                children: [
                  if (ancho)
                    EncabezadoPantalla(titulo: t.tituloAcerca, subtitulo: t.subtituloAcerca)
                  else
                    EncabezadoInterno(titulo: t.tituloAcerca, subtitulo: t.subtituloAcerca, respaldo: Rutas.hoy),
                  const SizedBox(height: KaizenMedidas.e20),
                  PortadaAcerca(rangos: _vm.totalRangos, fuentes: _vm.fuentes.length),
                  const SizedBox(height: KaizenMedidas.e24),
                  _Seccion(texto: t.acercaComoFunciona),
                  const SizedBox(height: KaizenMedidas.e12),
                  _ComoFunciona(dosColumnas: ancho),
                  if (_vm.cargar.ejecutando && _vm.fuentes.isEmpty)
                    const Padding(padding: EdgeInsets.all(KaizenMedidas.e24), child: EstadoCargando())
                  else if (_vm.cargar.error != null && _vm.fuentes.isEmpty && _vm.categorias.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: KaizenMedidas.e24),
                      child: TarjetaKaizen(
                        child: EstadoError(mensaje: t.acercaSinDatos, onReintentar: _vm.cargar.ejecutar),
                      ),
                    ),
                  if (_vm.categorias.isNotEmpty) ...[
                    const SizedBox(height: KaizenMedidas.e24),
                    _Seccion(texto: t.acercaRangosTitulo),
                    const SizedBox(height: KaizenMedidas.e4),
                    Text(t.acercaRangosIntro, style: texto.bodyMedium),
                    for (final c in _vm.categorias) ...[
                      const SizedBox(height: KaizenMedidas.e12),
                      TarjetaRangosCategoria(categoria: c),
                    ],
                  ],
                  if (_vm.fuentes.isNotEmpty) ...[
                    const SizedBox(height: KaizenMedidas.e24),
                    _Seccion(texto: t.acercaFuentesTitulo),
                    const SizedBox(height: KaizenMedidas.e4),
                    Text(t.acercaFuentesIntro, style: texto.bodyMedium),
                    const SizedBox(height: KaizenMedidas.e12),
                    ChipsSeleccion<String>(
                      opciones: [
                        (valor: '', etiqueta: t.acercaTodas),
                        for (final tema in AcercaViewModel.temas)
                          if (_vm.fuentes.any((f) => f.tema == tema)) (valor: tema, etiqueta: nombreTema(tema, t)),
                      ],
                      seleccionados: {_vm.tema ?? ''},
                      onCambio: (s) => _vm.tema = (s.firstOrNull ?? '').isEmpty ? null : s.first,
                    ),
                    const SizedBox(height: KaizenMedidas.e8),
                    Text(t.acercaFuentesConteo(_vm.fuentesFiltradas.length), style: texto.bodySmall),
                    for (final f in _vm.fuentesFiltradas) ...[
                      const SizedBox(height: KaizenMedidas.e8),
                      TarjetaFuente(fuente: f, tema: nombreTema(f.tema, t)),
                    ],
                  ],
                  const SizedBox(height: KaizenMedidas.e24),
                  Text(t.acercaAviso, style: texto.bodySmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: Text(texto, style: Theme.of(context).textTheme.titleLarge));
}

/// Portada: el porqué de Kaizen sobre marino y tres cifras que resumen la base científica.
class PortadaAcerca extends StatelessWidget {
  const PortadaAcerca({required this.rangos, required this.fuentes, super.key});

  /// `0` = aún no cargan (no se muestra esa cifra).
  final int rangos;
  final int fuentes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final cifras = [
      ('${Hitos.habitoFormado}', t.acercaDato66, KaizenIconos.hito),
      if (rangos > 0) ('$rangos', t.acercaDatoRangos, Icons.straighten),
      if (fuentes > 0) ('$fuentes', t.acercaDatoFuentes, Icons.menu_book_outlined),
    ];
    return TarjetaKaizen(
      estilo: EstiloTarjeta.destacada,
      relleno: const EdgeInsets.all(KaizenMedidas.e24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(KaizenIconos.consejo, color: KaizenColores.tealSobreMarino),
              const SizedBox(width: KaizenMedidas.e8),
              Expanded(
                child: Text(t.acercaHeroTitulo, style: texto.headlineSmall!.copyWith(color: KaizenColores.superficie)),
              ),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e12),
          Text(t.acercaPorQue, style: texto.bodyMedium!.copyWith(color: KaizenColores.textoSobreMarino)),
          const SizedBox(height: KaizenMedidas.e20),
          Wrap(
            spacing: KaizenMedidas.e12,
            runSpacing: KaizenMedidas.e12,
            children: [
              for (final (numero, etiqueta, icono) in cifras)
                Semantics(
                  label: '$numero $etiqueta',
                  child: ExcludeSemantics(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
                      padding: const EdgeInsets.all(KaizenMedidas.e12),
                      decoration: const BoxDecoration(
                        color: KaizenColores.marino700,
                        borderRadius: KaizenMedidas.bordeControl,
                      ),
                      child: Row(
                        children: [
                          Icon(icono, color: KaizenColores.tealSobreMarino, size: 22),
                          const SizedBox(width: KaizenMedidas.e12),
                          Text(numero, style: texto.headlineMedium!.copyWith(color: KaizenColores.superficie)),
                          const SizedBox(width: KaizenMedidas.e8),
                          Flexible(
                            child: Text(etiqueta, style: texto.bodySmall!.copyWith(color: KaizenColores.superficie)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Cómo funciona": seis tarjetas con ícono (dos columnas en escritorio).
class _ComoFunciona extends StatelessWidget {
  const _ComoFunciona({required this.dosColumnas});

  final bool dosColumnas;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final tarjetas = [
      (t.acercaFormacionTitulo, t.acercaFormacion, KaizenIconos.hito, KaizenColores.rachaDorada),
      (t.acercaCreacionTitulo, t.acercaCreacion, KaizenIconos.agregar, KaizenColores.verdeProgreso),
      (t.acercaEscaleraTitulo, t.acercaEscalera, Icons.stairs_outlined, KaizenColores.azul600),
      (t.acercaRachasTitulo, t.acercaRachas, KaizenIconos.protector, KaizenColores.naranjaRacha),
      (t.acercaColoresTitulo, t.acercaColores, Icons.palette_outlined, KaizenColores.tealBienestar),
      (t.acercaQueEsTitulo, t.acercaQueEs, KaizenIconos.consejo, KaizenColores.marino800),
    ];
    return LayoutBuilder(
      builder: (context, limites) {
        final lado = dosColumnas ? (limites.maxWidth - KaizenMedidas.e12) / 2 : limites.maxWidth;
        return Wrap(
          spacing: KaizenMedidas.e12,
          runSpacing: KaizenMedidas.e12,
          children: [
            for (final (titulo, cuerpo, icono, color) in tarjetas)
              SizedBox(
                width: lado,
                child: TarjetaKaizen(
                  relleno: const EdgeInsets.all(KaizenMedidas.e20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: KaizenColores.fondoDe(color), shape: BoxShape.circle),
                        child: Icon(icono, color: color, size: 22),
                      ),
                      const SizedBox(height: KaizenMedidas.e12),
                      Semantics(header: true, child: Text(titulo, style: texto.titleMedium)),
                      const SizedBox(height: KaizenMedidas.e8),
                      Text(cuerpo, style: texto.bodyMedium),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Pastilla de confianza: verde (alta), ámbar (media) o gris (baja), siempre con su texto.
class PastillaConfianza extends StatelessWidget {
  const PastillaConfianza({required this.confianza, super.key});

  final Confianza confianza;

  static Color colorDe(Confianza c) => switch (c) {
    Confianza.alta => KaizenColores.verdeProgreso,
    Confianza.media => KaizenColores.rachaChispa,
    Confianza.baja => KaizenColores.rachaSinRacha,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = colorDe(confianza);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e8, vertical: 2),
      decoration: BoxDecoration(color: KaizenColores.fondoDe(color), borderRadius: BorderRadius.circular(999)),
      child: Text(
        PanelEvidencia.confianzaDe(confianza, t),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Los rangos de una categoría: encabezado con su color e ícono y una fila por subcategoría.
class TarjetaRangosCategoria extends StatelessWidget {
  const TarjetaRangosCategoria({required this.categoria, super.key});

  final Categoria categoria;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final color = colorDeCategoria(categoria);
    return TarjetaKaizen(
      relleno: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e20, vertical: KaizenMedidas.e12),
            decoration: BoxDecoration(
              color: KaizenColores.fondoDe(color),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(KaizenIconos.porNombre(categoria.icono), color: color),
                const SizedBox(width: KaizenMedidas.e8),
                Semantics(header: true, child: Text(categoria.nombre, style: texto.titleMedium)),
              ],
            ),
          ),
          for (final s in categoria.subcategorias)
            Padding(
              padding: const EdgeInsets.fromLTRB(KaizenMedidas.e20, KaizenMedidas.e12, KaizenMedidas.e20, 0),
              child: MergeSemantics(child: _FilaRango(subcategoria: s, categoria: categoria, t: t)),
            ),
          const SizedBox(height: KaizenMedidas.e16),
        ],
      ),
    );
  }
}

class _FilaRango extends StatelessWidget {
  const _FilaRango({required this.subcategoria, required this.categoria, required this.t});

  final Subcategoria subcategoria;
  final Categoria categoria;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final r = subcategoria.referencia;
    final color = colorDeCategoria(categoria);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(iconoDeSubcategoria(subcategoria, categoria: categoria), size: 18, color: color),
        ),
        const SizedBox(width: KaizenMedidas.e8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: KaizenMedidas.e8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(subcategoria.nombre, style: texto.labelLarge),
                  if (r != null) PastillaConfianza(confianza: r.confianza),
                ],
              ),
              if (r == null)
                Text(t.acercaSinRango, style: texto.bodySmall)
              else ...[
                Text(
                  [
                    t.acercaRango(
                      numero(r.optimoDesde),
                      numero(r.optimoHasta),
                      r.unidadBase,
                      r.periodo == PeriodoReferencia.dia ? t.acercaPorDia : t.acercaPorSemana,
                    ),
                    if (r.maximo case final m?) t.acercaMaximo(numero(m), r.unidadBase),
                  ].join(' · '),
                  style: texto.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                ),
                Text('${r.cita} · ${r.fuentes}', style: texto.bodySmall!.copyWith(color: KaizenColores.textoSecundario)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Una fuente: clave, tema y confianza arriba, la referencia y, al abrirla, lo que la app toma de ella, el enlace y
/// cómo se verificó. El texto se puede seleccionar para copiar el enlace.
class TarjetaFuente extends StatelessWidget {
  const TarjetaFuente({required this.fuente, required this.tema, super.key});

  final FuenteCientifica fuente;
  final String tema;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final f = fuente;
    return Material(
      color: KaizenColores.superficie,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: KaizenMedidas.bordeTarjeta,
        side: BorderSide(color: KaizenColores.borde),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(f.clave),
          tilePadding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e16, vertical: KaizenMedidas.e4),
          childrenPadding: const EdgeInsets.fromLTRB(KaizenMedidas.e16, 0, KaizenMedidas.e16, KaizenMedidas.e16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: KaizenMedidas.e8,
                runSpacing: KaizenMedidas.e4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e8, vertical: 2),
                    decoration: BoxDecoration(color: KaizenColores.marino800, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      f.clave,
                      style: texto.labelSmall!.copyWith(color: KaizenColores.superficie, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(tema, style: texto.labelSmall!.copyWith(color: KaizenColores.textoSecundario)),
                  PastillaConfianza(confianza: AcercaViewModel.nivelDe(f.confianza)),
                ],
              ),
              const SizedBox(height: KaizenMedidas.e8),
              Text(f.referencia, style: texto.bodySmall!.copyWith(color: KaizenColores.texto)),
            ],
          ),
          children: [
            SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.dato, style: texto.bodyMedium),
                  const SizedBox(height: KaizenMedidas.e8),
                  Text(f.enlace, style: texto.bodySmall!.copyWith(color: KaizenColores.azul600)),
                  const SizedBox(height: KaizenMedidas.e4),
                  Text(t.acercaConfianza(f.confianza), style: texto.labelSmall),
                  Text(t.acercaVerificada(f.verificada), style: texto.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
