import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../data/services/avisos/gestor_avisos.dart';
import '../../../data/services/recordatorios/servicio_recordatorios.dart';
import '../../../domain/models/avisos.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../../utils/fechas.dart';
import '../../../utils/reloj.dart';
import '../../core/apariencia_habito.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/aviso_kaizen.dart';
import '../../core/widgets/boton_volver.dart';
import '../../core/widgets/chips_seleccion.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../view_models/notificaciones_viewmodel.dart';

/// Elige una hora (por omisión, el reloj del sistema).
typedef SelectorHora = Future<Hora?> Function(BuildContext context, Hora inicial);

Future<Hora?> elegirHoraDelSistema(BuildContext context, Hora inicial) async {
  final r = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: inicial.hora, minute: inicial.minuto),
  );
  return r == null ? null : (hora: r.hour, minuto: r.minute);
}

/// `/perfil/notificaciones` (Paso 10): "Mis avisos" (a la hora y los días que el usuario quiera), la hora del
/// recordatorio de cada hábito, los avisos automáticos con su hora, las horas de silencio y los próximos avisos.
/// Todo vive en el dispositivo: no pasa por la API.
class PantallaNotificaciones extends StatefulWidget {
  const PantallaNotificaciones({super.key});

  static const double anchoMaximo = 760;

  /// Desde este ancho, dos columnas: lo que programa el usuario a la izquierda; lo automático a la derecha.
  static const double anchoDosColumnas = 1000;
  static const double anchoMaximoEscritorio = 1200;

  /// Cómo se elige la hora; las pruebas lo cambian para no depender del reloj del sistema.
  @visibleForTesting
  static SelectorHora selectorHora = elegirHoraDelSistema;

  @override
  State<PantallaNotificaciones> createState() => _PantallaNotificacionesState();
}

class _PantallaNotificacionesState extends State<PantallaNotificaciones> {
  late final NotificacionesViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = NotificacionesViewModel(
      avisos: context.read<GestorAvisos>(),
      recordatorios: context.read<ServicioRecordatorios>(),
      habitos: context.read<HabitosRepository>(),
      reloj: context.read<Reloj>(),
    );
    _vm.cargar.ejecutar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<Hora?> _elegirHora(Hora inicial) => PantallaNotificaciones.selectorHora(context, inicial);

  Future<void> _editarAviso([AvisoPersonal? existente]) async {
    final r = await showDialog<({Hora hora, int dias, String texto})>(
      context: context,
      builder: (_) => DialogoAviso(existente: existente),
    );
    if (r == null || !mounted) {
      return;
    }
    if (existente == null) {
      await _vm.agregarAviso(hora: r.hora, dias: r.dias, texto: r.texto);
    } else {
      await _vm.editarAviso(existente.copyWith(hora: r.hora, dias: r.dias, texto: r.texto));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.cargar]),
      builder: (context, _) {
        if (!_vm.cargado) {
          return const EstadoCargando();
        }
        final p = _vm.preferencias;
        final columnaIzquierda = <Widget>[
          // ── Mis avisos
          _Seccion(
            titulo: t.notifMisAvisos,
            detalle: t.notifMisAvisosDetalle,
            icono: KaizenIconos.recordatorio,
            children: [
              if (p.personales.isEmpty) Text(t.notifSinAvisos, style: texto.bodyMedium),
              for (final a in p.personales)
                ListTile(
                  key: ValueKey('aviso-${a.id}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.texto.isEmpty ? t.avisoPersonalTexto : a.texto),
                  subtitle: Text('${formatoHoraAviso(a.hora)} · ${diasDeMascara(a.dias)}'),
                  onTap: () => _editarAviso(a),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: a.activo,
                        onChanged: (v) => _vm.editarAviso(a.copyWith(activo: v)),
                      ),
                      IconButton(
                        tooltip: t.notifQuitar,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _vm.quitarAviso(a.id),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: KaizenMedidas.e8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _editarAviso,
                  icon: const Icon(KaizenIconos.agregar),
                  label: Text(t.notifAgregarAviso),
                ),
              ),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e12),
          // ── Recordatorios de cada hábito
          _Seccion(
            titulo: t.notifRecordatorios,
            detalle: t.notifRecordatoriosDetalle,
            icono: Icons.alarm,
            interruptor: p.recordatorios,
            onInterruptor: _vm.cambiarRecordatorios,
            children: [
              for (final (:habito, :hora) in _vm.habitos)
                ListTile(
                  key: ValueKey('recordatorio-${habito.id}'),
                  contentPadding: EdgeInsets.zero,
                  enabled: p.recordatorios,
                  leading: Icon(habito.icono, color: habito.color),
                  title: Text(habito.nombre),
                  subtitle: Text(hora == null ? t.notifSinRecordatorio : formatoHora(hora)),
                  onTap: () async {
                    final h = await _elegirHora(hora ?? (hora: 9, minuto: 0));
                    if (h != null) {
                      await _vm.ponerRecordatorio(habito, h);
                    }
                  },
                  trailing: hora == null
                      ? Text(t.notifPonerHora, style: texto.labelLarge!.copyWith(color: KaizenColores.azul600))
                      : IconButton(
                          tooltip: t.notifQuitar,
                          icon: const Icon(Icons.alarm_off),
                          onPressed: () => _vm.quitarRecordatorio(habito),
                        ),
                ),
            ],
          ),
        ];
        final columnaDerecha = <Widget>[
          // ── Automáticos
          _Seccion(
            titulo: t.notifAutomaticos,
            detalle: t.notifAutomaticosDetalle,
            icono: Icons.auto_awesome_outlined,
            children: [
              _Automatico(
                titulo: t.notifRachaEnRiesgo,
                detalle: t.notifRachaEnRiesgoDetalle,
                activo: p.rachaEnRiesgo,
                onActivo: _vm.cambiarRachaEnRiesgo,
                hora: p.horaRachaEnRiesgo,
                onHora: () async {
                  if (await _elegirHora(p.horaRachaEnRiesgo) case final h?) {
                    await _vm.cambiarHoraRachaEnRiesgo(h);
                  }
                },
              ),
              _Automatico(
                titulo: t.notifMicroPaso,
                detalle: t.notifMicroPasoDetalle,
                activo: p.microPaso,
                onActivo: _vm.cambiarMicroPaso,
              ),
              _Automatico(
                titulo: t.notifResumen,
                detalle: t.notifResumenDetalle,
                activo: p.resumenSemanal,
                onActivo: _vm.cambiarResumenSemanal,
                hora: p.horaResumen,
                dia: p.diaResumen,
                onDia: _vm.cambiarDiaResumen,
                onHora: () async {
                  if (await _elegirHora(p.horaResumen) case final h?) {
                    await _vm.cambiarHoraResumen(h);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e12),
          // ── Silencio
          _Seccion(
            titulo: t.notifSilencio,
            detalle: t.notifSilencioDetalle,
            icono: Icons.bedtime_outlined,
            children: [
              Wrap(
                spacing: KaizenMedidas.e12,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      if (await _elegirHora(p.silencioDesde) case final h?) {
                        await _vm.cambiarSilencioDesde(h);
                      }
                    },
                    child: Text('${t.notifDesde} ${formatoHoraAviso(p.silencioDesde)}'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      if (await _elegirHora(p.silencioHasta) case final h?) {
                        await _vm.cambiarSilencioHasta(h);
                      }
                    },
                    child: Text('${t.notifHasta} ${formatoHoraAviso(p.silencioHasta)}'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e12),
          // ── Próximos
          _Seccion(
            titulo: t.notifProximos,
            icono: Icons.schedule,
            children: [
              if (_vm.proximos().isEmpty) Text(t.notifSinProximos, style: texto.bodyMedium),
              for (final a in _vm.proximos())
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(a.titulo),
                  subtitle: Text(a.cuerpo),
                  trailing: Text(
                    t.notifCuando(
                      _dia(t, a.cuando, context.read<Reloj>()()),
                      formatoHoraAviso((hora: a.cuando.hour, minuto: a.cuando.minute)),
                    ),
                    style: texto.labelMedium,
                  ),
                ),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e12),
          // ── Cómo funcionan
          _Seccion(
            titulo: t.notifComoFuncionan,
            icono: Icons.info_outline,
            children: [
              for (final r in [t.notifRegla1, t.notifRegla2, t.notifRegla3, t.notifRegla4])
                Padding(
                  padding: const EdgeInsets.only(bottom: KaizenMedidas.e8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(Icons.check, size: 16, color: KaizenColores.verdeProgreso),
                      ),
                      const SizedBox(width: KaizenMedidas.e8),
                      Expanded(child: Text(r, style: texto.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ];
        return LayoutBuilder(
          builder: (context, restricciones) {
            final dosColumnas = restricciones.maxWidth >= PantallaNotificaciones.anchoDosColumnas;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dosColumnas
                      ? PantallaNotificaciones.anchoMaximoEscritorio
                      : PantallaNotificaciones.anchoMaximo,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    KaizenMedidas.e20,
                    KaizenMedidas.e24,
                    KaizenMedidas.e20,
                    KaizenMedidas.e32,
                  ),
                  children: [
                    EncabezadoInterno(
                      titulo: t.tituloNotificaciones,
                      subtitulo: t.subtituloNotificaciones,
                      respaldo: Rutas.perfil,
                    ),
                    const SizedBox(height: KaizenMedidas.e16),
                    if (!_vm.disponible) ...[
                      AvisoKaizen(texto: t.notifNoDisponible),
                      const SizedBox(height: KaizenMedidas.e16),
                    ],
                    if (!_vm.horaExacta) ...[
                      TarjetaKaizen(
                        key: const ValueKey('hora-exacta'),
                        relleno: const EdgeInsets.all(KaizenMedidas.e16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.notifExacta, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: KaizenMedidas.e8),
                            FilledButton.tonalIcon(
                              onPressed: _vm.pedirHoraExacta,
                              icon: const Icon(Icons.alarm_on),
                              label: Text(t.notifPermitirExacta),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KaizenMedidas.e16),
                    ],
                    if (_vm.permisoNegado) ...[
                      AvisoKaizen(texto: t.notifPermisoNegado),
                      const SizedBox(height: KaizenMedidas.e16),
                    ],
                    if (dosColumnas)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: columnaIzquierda),
                          ),
                          const SizedBox(width: KaizenMedidas.e16),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: columnaDerecha),
                          ),
                        ],
                      )
                    else ...[
                      ...columnaIzquierda,
                      const SizedBox(height: KaizenMedidas.e12),
                      ...columnaDerecha,
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.children,
    this.detalle,
    this.interruptor,
    this.onInterruptor,
  });

  final String titulo;
  final String? detalle;
  final IconData icono;
  final List<Widget> children;
  final bool? interruptor;
  final ValueChanged<bool>? onInterruptor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: KaizenColores.tealBienestar),
              const SizedBox(width: KaizenMedidas.e8),
              Expanded(
                child: Semantics(header: true, child: Text(titulo, style: texto.titleMedium)),
              ),
              if (interruptor != null) Switch(value: interruptor!, onChanged: onInterruptor),
            ],
          ),
          if (detalle != null) ...[const SizedBox(height: KaizenMedidas.e4), Text(detalle!, style: texto.bodySmall)],
          const SizedBox(height: KaizenMedidas.e12),
          ...children,
        ],
      ),
    );
  }
}

class _Automatico extends StatelessWidget {
  const _Automatico({
    required this.titulo,
    required this.detalle,
    required this.activo,
    required this.onActivo,
    this.hora,
    this.onHora,
    this.dia,
    this.onDia,
  });

  final String titulo;
  final String detalle;
  final bool activo;
  final ValueChanged<bool> onActivo;
  final Hora? hora;
  final VoidCallback? onHora;
  final int? dia;
  final ValueChanged<int>? onDia;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: KaizenMedidas.e12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: texto.titleSmall),
                    Text(detalle, style: texto.bodySmall),
                  ],
                ),
              ),
              Switch(value: activo, onChanged: onActivo),
            ],
          ),
          if (activo && (hora != null || dia != null))
            Wrap(
              spacing: KaizenMedidas.e8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (dia != null)
                  DropdownButton<int>(
                    value: dia,
                    onChanged: (v) => v == null ? null : onDia?.call(v),
                    items: [
                      for (var d = 1; d <= 7; d++)
                        DropdownMenuItem(value: d, child: Text(_mayuscula(Fechas.diasSemana[d - 1]))),
                    ],
                  ),
                if (hora != null) OutlinedButton(onPressed: onHora, child: Text(formatoHoraAviso(hora!))),
              ],
            ),
        ],
      ),
    );
  }
}

/// Crear o editar un aviso propio: hora (cualquiera: 9:35, 22:20…), días y texto.
class DialogoAviso extends StatefulWidget {
  const DialogoAviso({this.existente, super.key});

  final AvisoPersonal? existente;

  @override
  State<DialogoAviso> createState() => _DialogoAvisoState();
}

class _DialogoAvisoState extends State<DialogoAviso> {
  late Hora _hora = widget.existente?.hora ?? (hora: 9, minuto: 0);
  late Set<int> _dias = {
    for (var b = 0; b < 7; b++)
      if ((widget.existente?.dias ?? 127) & (1 << b) != 0) b,
  };
  late final TextEditingController _texto = TextEditingController(text: widget.existente?.texto ?? '');

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.existente == null ? t.notifAgregarAviso : t.notifEditarAviso),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.notifHora, style: texto.labelLarge),
            const SizedBox(height: KaizenMedidas.e4),
            OutlinedButton.icon(
              key: const ValueKey('hora-aviso'),
              icon: const Icon(Icons.schedule),
              label: Text(formatoHoraAviso(_hora)),
              onPressed: () async {
                final r = await PantallaNotificaciones.selectorHora(context, _hora);
                if (r != null && mounted) {
                  setState(() => _hora = r);
                }
              },
            ),
            const SizedBox(height: KaizenMedidas.e16),
            Text(t.notifDias, style: texto.labelLarge),
            const SizedBox(height: KaizenMedidas.e4),
            ChipsSeleccion<int>(
              multiple: true,
              opciones: [for (var b = 0; b < 7; b++) (valor: b, etiqueta: diasCortos[b])],
              seleccionados: _dias,
              onCambio: (s) => setState(() => _dias = s),
            ),
            const SizedBox(height: KaizenMedidas.e16),
            TextField(
              controller: _texto,
              maxLength: 80,
              decoration: InputDecoration(labelText: t.notifTextoAviso, hintText: t.avisoPersonalTexto),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancelar)),
        FilledButton(
          onPressed: _dias.isEmpty
              ? null
              : () =>
                    Navigator.of(context)
                        .pop((hora: _hora, dias: _dias.fold<int>(0, (m, b) => m | (1 << b)), texto: _texto.text)),
          child: Text(t.notifGuardar),
        ),
      ],
    );
  }
}

String _mayuscula(String s) => '${s[0].toUpperCase()}${s.substring(1)}';

/// "Hoy", "Mañana" o "28 nov".
String _dia(AppLocalizations t, DateTime cuando, DateTime ahora) {
  final dias = DateTime(
    cuando.year,
    cuando.month,
    cuando.day,
  ).difference(DateTime(ahora.year, ahora.month, ahora.day)).inDays;
  return switch (dias) {
    0 => t.notifHoy,
    1 => t.notifManana,
    _ => Fechas.corta(cuando),
  };
}
