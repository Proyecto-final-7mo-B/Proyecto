import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../core/tema/colores.dart';
import '../core/tema/iconos.dart';
import '../core/tema/medidas.dart';
import '../core/widgets/anillo_progreso.dart';
import '../core/widgets/aviso_kaizen.dart';
import '../core/widgets/banner_sin_conexion.dart';
import '../core/widgets/barra_progreso.dart';
import '../core/widgets/barra_semana.dart';
import '../core/widgets/calendario_mes.dart';
import '../core/widgets/campo_validado.dart';
import '../core/widgets/chips_seleccion.dart';
import '../core/widgets/contador_meta.dart';
import '../core/widgets/dialogo_confirmacion.dart';
import '../core/widgets/estados.dart';
import '../core/widgets/fila_habito.dart';
import '../core/widgets/icono_escalera.dart';
import '../core/widgets/indicador_racha.dart';
import '../core/widgets/logo_kaizen.dart';
import '../core/widgets/mapa_calor.dart';
import '../core/widgets/selector_segmentado.dart';
import '../core/widgets/tarjeta_kaizen.dart';
import '../core/widgets/tarjeta_kpi.dart';

/// Galería de todos los componentes del sistema de diseño, para compararlos con los bosquejos.
/// Ruta `/dev/componentes`, que solo existe en depuración (botón "Ver componentes" en la pantalla de entrada).
class GaleriaComponentes extends StatefulWidget {
  const GaleriaComponentes({super.key});

  @override
  State<GaleriaComponentes> createState() => _GaleriaComponentesState();
}

class _GaleriaComponentesState extends State<GaleriaComponentes> {
  final Set<String> _cumplidos = {'Tomar agua', 'Ejercicio'};
  String _frecuencia = 'diario';
  Set<String> _categoria = {'Aprendizaje'};
  Set<int> _dias = {1, 2, 3, 4, 5};
  num _meta = 5;
  bool _escalera = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.galeriaComponentes)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(KaizenMedidas.e20),
            children: [
              _seccion('Marca', const [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    LogoKaizen(lado: 44),
                    LogoKaizen(conNombre: true),
                    _FondoOscuro(child: LogoKaizen(sobreOscuro: true, conNombre: true)),
                    IconoEscalera(tamano: 28, color: KaizenColores.marino800),
                  ],
                ),
              ]),
              _seccion('Paleta', [const _Paleta()]),
              _seccion('Tipografía · Plus Jakarta Sans', [const _Tipografia()]),
              _seccion('Botones', [
                FilledButton(onPressed: () {}, child: const Text('Guardar hábito')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(onPressed: () {}, child: const Text('Aceptar')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(onPressed: () {}, child: const Text('Mantener')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(KaizenIconos.candado),
                      label: const Text('Sellar cápsula'),
                    ),
                    TextButton(onPressed: () {}, child: const Text('¿Olvidaste tu contraseña?')),
                  ],
                ),
                const SizedBox(height: 12),
                const FilledButton(onPressed: null, child: Text('Deshabilitado')),
              ]),
              _seccion('Tarjetas', [
                const TarjetaResumenDemo(cumplidos: 2, total: 5),
                const SizedBox(height: 12),
                TarjetaKaizen(
                  estilo: EstiloTarjeta.suave,
                  onTap: () {},
                  child: const Row(
                    children: [
                      IconoEscalera(),
                      SizedBox(width: 12),
                      Expanded(child: Text('Leer: ¿subir de 10 a 12 min?')),
                      Icon(KaizenIconos.siguiente),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: TarjetaKpi(valor: '1,204', etiqueta: 'Usuarios activos', variacion: 8),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TarjetaKpi(valor: '76 %', etiqueta: 'Cumplimiento global', variacion: -2.5),
                    ),
                  ],
                ),
              ]),
              _seccion('Fila de hábito (toca el círculo)', [
                for (final (icono, nombre, subtitulo, racha, capsula) in const [
                  (Icons.water_drop_outlined, 'Tomar agua', '2 L · diario', 21, false),
                  (Icons.fitness_center, 'Ejercicio', '30 min · diario', 8, true),
                  (Icons.menu_book_outlined, 'Leer', '10 min · Nivel 3', 34, false),
                ]) ...[
                  FilaHabito(
                    icono: icono,
                    nombre: nombre,
                    subtitulo: subtitulo,
                    racha: racha,
                    conCapsula: capsula,
                    cumplido: _cumplidos.contains(nombre),
                    onCheck: () => setState(
                      () => _cumplidos.contains(nombre) ? _cumplidos.remove(nombre) : _cumplidos.add(nombre),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ]),
              _seccion('Racha, anillo y barras', [
                const Row(
                  children: [
                    IndicadorRacha(dias: 21),
                    SizedBox(width: 24),
                    IndicadorRacha(dias: 8, conCapsula: true),
                    SizedBox(width: 24),
                    AnilloProgreso(
                      valor: 14 / 21,
                      child: Text('14/21', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Los seis niveles de la racha (doc. 05): 0 · chispa · llama · aro · formado · emblema.
                Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    for (final dias in const [0, 3, 8, 34, 70, 120]) IndicadorRacha(dias: dias, tamano: 18),
                    const IndicadorRacha(dias: 12, protegida: true, tamano: 18),
                  ],
                ),
                const SizedBox(height: 16),
                const BarraProgreso(valor: 14 / 21, color: KaizenColores.naranjaRacha),
                const SizedBox(height: 16),
                const BarraSemana(niveles: [2, 1, 0, 0, 2, 1, null]),
              ]),
              _seccion('Calendario del mes', [
                TarjetaKaizen(
                  child: CalendarioMes(
                    anio: 2026,
                    mes: 10,
                    hoy: DateTime(2026, 10, 22),
                    niveles: nivelesDemoOctubre,
                    onDia: (_) {},
                  ),
                ),
              ]),
              _seccion('Mapa de calor (I5)', [
                const TarjetaKaizen(
                  child: MapaCalor(
                    filas: ['Ejercicio', 'Agua', 'Leer', 'Sueño'],
                    columnas: ['L-M', 'J-V', 'S-D'],
                    valores: [
                      [0.8, 0.8, 0.3],
                      [0.1, 0.3, 0.1],
                      [0.1, 0.1, 0.3],
                      [0.8, 0.3, null],
                    ],
                  ),
                ),
              ]),
              _seccion('Controles de formulario', [
                const CampoValidado(
                  etiqueta: 'Nombre',
                  pista: 'Leer',
                  ayuda: 'Empieza pequeño: 5 minutos bastan para crear el hábito.',
                ),
                const SizedBox(height: 16),
                const CampoValidado(etiqueta: 'Contraseña', contrasena: true),
                const SizedBox(height: 16),
                Text('Categoría', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ChipsSeleccion<String>(
                  opciones: const [
                    (valor: 'Aprendizaje', etiqueta: 'Aprendizaje'),
                    (valor: 'Salud', etiqueta: 'Salud'),
                    (valor: 'Ejercicio', etiqueta: 'Ejercicio'),
                    (valor: 'Sueño', etiqueta: 'Sueño'),
                  ],
                  seleccionados: _categoria,
                  onCambio: (v) => setState(() => _categoria = v),
                ),
                const SizedBox(height: 16),
                Text('Frecuencia', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SelectorSegmentado<String>(
                  opciones: const [
                    (valor: 'diario', etiqueta: 'Diario'),
                    (valor: 'lv', etiqueta: 'L-V'),
                    (valor: 'n', etiqueta: 'N por sem.'),
                  ],
                  seleccionado: _frecuencia,
                  onCambio: (v) => setState(() => _frecuencia = v),
                ),
                const SizedBox(height: 16),
                ChipsSeleccion<int>(
                  multiple: true,
                  opciones: [for (var d = 1; d <= 7; d++) (valor: d, etiqueta: 'LMMJVSD'[d - 1])],
                  seleccionados: _dias,
                  onCambio: (v) => setState(() => _dias = v),
                ),
                const SizedBox(height: 16),
                Text('Meta inicial', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ContadorMeta(valor: _meta, unidad: 'min', onCambio: (v) => setState(() => _meta = v)),
                const SizedBox(height: 16),
                TarjetaKaizen(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const IconoEscalera(),
                    title: const Text('Escalera Kaizen'),
                    subtitle: const Text('Sube la meta en micro-pasos'),
                    value: _escalera,
                    onChanged: (v) => setState(() => _escalera = v),
                  ),
                ),
              ]),
              _seccion('Avisos', [
                const AvisoKaizen(texto: 'La foto solo se agrega desde Android, con cámara o galería.'),
                const SizedBox(height: 12),
                const ClipRRect(borderRadius: KaizenMedidas.bordeControl, child: BannerSinConexion(pendientes: 3)),
              ]),
              _seccion('Estados', [
                const SizedBox(height: 120, child: EstadoCargando()),
                const EstadoVacio(titulo: 'Aún no tienes hábitos', mensaje: 'Empieza con uno pequeño.'),
                EstadoError(onReintentar: () {}),
              ]),
              _seccion('Diálogo', [
                OutlinedButton(
                  onPressed: () => DialogoConfirmacion.mostrar(
                    context,
                    titulo: '¿Archivar “Leer”?',
                    mensaje: 'Se conserva su historial. Puedes verlo en archivados.',
                    textoConfirmar: 'Archivar',
                    peligroso: true,
                  ),
                  child: const Text('Abrir diálogo de confirmación'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> hijos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KaizenMedidas.e32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: KaizenMedidas.e12),
          ...hijos,
        ],
      ),
    );
  }
}

/// Niveles de octubre de 2026 copiados del bosquejo "Escritorio 02 Inicio".
const Map<int, int> nivelesDemoOctubre = {
  1: 2, 2: 1, 3: 2, 4: 1, 5: 2, 6: 1, 7: 2, 8: 1, 9: 4, 10: 2, 11: 0, 12: 2, 13: 3, 14: 2, 15: 3, 16: 2, //
  17: 3, 18: 2, 19: 3, 20: 3, 21: 4, 22: 0, 23: 3, 24: 4, 25: 3, 26: 3, 27: 4, 28: 3, 29: 3, 30: 4, 31: 3,
};

/// La tarjeta "2 de 5" de Hoy armada con los componentes (la real llega en el Paso 6).
class TarjetaResumenDemo extends StatelessWidget {
  const TarjetaResumenDemo({required this.cumplidos, required this.total, super.key});

  final int cumplidos;
  final int total;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      estilo: EstiloTarjeta.destacada,
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$cumplidos de $total', style: texto.displayMedium!.copyWith(color: KaizenColores.superficie)),
              const SizedBox(width: KaizenMedidas.e16),
              Expanded(
                child: Text(
                  'hábitos de hoy',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texto.bodyMedium!.copyWith(color: KaizenColores.textoSobreMarino),
                ),
              ),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e16),
          BarraProgreso(valor: total == 0 ? 0 : cumplidos / total, sobreOscuro: true),
          const SizedBox(height: KaizenMedidas.e16),
          const BarraSemana(niveles: [3, 2, 0, 0, 3, 2, 0], sobreOscuro: true),
        ],
      ),
    );
  }
}

class _FondoOscuro extends StatelessWidget {
  const _FondoOscuro({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(color: KaizenColores.marino900, borderRadius: KaizenMedidas.bordeControl),
    child: child,
  );
}

class _Paleta extends StatelessWidget {
  const _Paleta();

  static const List<(String, Color)> colores = [
    ('marino900', KaizenColores.marino900),
    ('marino800 · primario', KaizenColores.marino800),
    ('marino700', KaizenColores.marino700),
    ('azul600', KaizenColores.azul600),
    ('azul400', KaizenColores.azul400),
    ('azul200', KaizenColores.azul200),
    ('azul100', KaizenColores.azul100),
    ('azul50', KaizenColores.azul50),
    ('fondo', KaizenColores.fondo),
    ('borde', KaizenColores.borde),
    ('bordeCampo', KaizenColores.bordeCampo),
    ('bordeControl', KaizenColores.bordeControl),
    ('textoSecundario', KaizenColores.textoSecundario),
    ('naranjaRacha · acento', KaizenColores.naranjaRacha),
    ('naranjaClaro', KaizenColores.naranjaClaro),
    ('avisoFondo', KaizenColores.avisoFondo),
    ('error', KaizenColores.error),
  ];

  static String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (nombre, color) in colores)
          SizedBox(
            width: 160,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: KaizenMedidas.bordeCelda,
                    border: Border.all(color: KaizenColores.borde),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: texto.labelSmall, overflow: TextOverflow.ellipsis),
                      Text(hex(color), style: texto.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tipografia extends StatelessWidget {
  const _Tipografia();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kaizen', style: t.displayLarge),
        Text('2 de 5', style: t.displayMedium),
        Text('Hoy', style: t.headlineLarge),
        Text('10 → 12 min', style: t.headlineSmall),
        Text('Tomar agua', style: t.titleMedium),
        Text('Nombre', style: t.titleSmall),
        Text('Cuerpo de texto para explicaciones y mensajes.', style: t.bodyMedium),
        Text('2 L · diario', style: t.bodySmall),
        Text('L  M  M  J  V  S  D', style: t.labelSmall),
      ],
    );
  }
}
