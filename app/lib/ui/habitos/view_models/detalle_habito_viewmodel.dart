import 'package:flutter/foundation.dart';

import '../../../config/constantes.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../domain/models/escalera.dart';
import '../../../domain/models/categoria.dart';
import '../../../domain/models/evidencia.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/command.dart';
import '../../../utils/fechas.dart';
import '../../../utils/reloj.dart';
import '../../../utils/result.dart';
import 'estadisticas_habito.dart';

/// `/habitos/:id` (bosquejo 04): racha actual y mejor, calendario del mes con su %, historial y, en escritorio,
/// cumplimiento de 30 días, tendencia por semana y nivel de la Escalera.
///
/// Trae el último año de check-ins de una vez (`GET /habitos/{id}/registros`, máximo 366 días), así cambiar de mes
/// no vuelve a llamar a la API. La Escalera es opcional: si falla, no se muestra su tarjeta.
class DetalleHabitoViewModel extends ChangeNotifier {
  DetalleHabitoViewModel({required HabitosRepository habitos, required this.habitoId, Reloj reloj = relojDelSistema})
    : _repoHabitos = habitos,
      _relojDetalle = reloj {
    cargar = Command0<void>(_cargar);
    reactivar = Command0<Habito>(_reactivar);
  }

  final HabitosRepository _repoHabitos;
  final Reloj _relojDetalle;
  final String habitoId;

  late final Command0<void> cargar;

  /// Un hábito archivado se puede volver a activar (`PATCH {"activo": true}`).
  late final Command0<Habito> reactivar;

  /// Renglones del historial.
  static const int renglonesHistorial = 7;

  /// Semanas de la tendencia.
  static const int semanasTendencia = 12;

  Habito? _habito;
  Map<DateTime, Registro> _registros = const {};
  EscaleraHabito? _escalera;
  late DateTime _mes = _primeroDeMes(hoy);

  DateTime get hoy => Fechas.soloFecha(_relojDetalle());
  Habito? get habito => _habito;
  EscaleraHabito? get escalera => _escalera;

  /// Primer día del mes que muestra el calendario.
  DateTime get mes => _mes;

  /// Desde dónde hay datos: un año atrás o la fecha de creación, lo que sea más reciente.
  DateTime get _inicioDatos {
    final haceUnAnio = hoy.subtract(const Duration(days: Limites.historialMaxDias - 1));
    final creado = Fechas.soloFecha(_habito?.fechaCreacion ?? haceUnAnio);
    return creado.isAfter(haceUnAnio) ? creado : haceUnAnio;
  }

  bool get puedeRetroceder => _mes.isAfter(_primeroDeMes(_inicioDatos));
  bool get puedeAvanzar => _mes.isBefore(_primeroDeMes(hoy));

  void mesAnterior() {
    if (puedeRetroceder) {
      _mes = DateTime.utc(_mes.year, _mes.month - 1);
      notifyListeners();
    }
  }

  void mesSiguiente() {
    if (puedeAvanzar) {
      _mes = DateTime.utc(_mes.year, _mes.month + 1);
      notifyListeners();
    }
  }

  static DateTime _primeroDeMes(DateTime d) => DateTime.utc(d.year, d.month);

  // ───────────────────────── Cálculos ─────────────────────────

  /// Último día que cuenta para los porcentajes: hoy solo si ya tiene check-in (si no, el día no ha terminado y
  /// contarlo como fallido haría "caer" el mes, los 30 días y la semana actual).
  DateTime get ultimoDiaContable => _registros.containsKey(hoy) ? hoy : hoy.subtract(const Duration(days: 1));

  Map<int, int> get nivelesMes =>
      EstadisticasHabito.nivelesMes(registros: _registros, anio: _mes.year, mes: _mes.month, meta: _habito?.meta ?? 1);

  /// % del mes que se ve (hasta hoy si es el mes actual).
  double? get cumplimientoMes {
    final h = _habito;
    if (h == null) {
      return null;
    }
    final fin = DateTime.utc(_mes.year, _mes.month + 1, 0);
    return EstadisticasHabito.cumplimiento(
      frecuencia: h.frecuencia,
      registros: _registros,
      desde: _mes,
      hasta: fin.isAfter(ultimoDiaContable) ? ultimoDiaContable : fin,
      creado: h.fechaCreacion,
    );
  }

  /// % de los últimos 30 días.
  double? get cumplimiento30 => _cumplimientoEntre(29, 0);

  /// Diferencia contra los 30 días anteriores (puntos porcentuales); `null` si el hábito no existía.
  double? get variacion30 {
    final actual = cumplimiento30;
    final antes = _cumplimientoEntre(59, 30);
    return actual == null || antes == null ? null : (actual - antes).roundToDouble();
  }

  /// % entre [desdeHace] y [hastaHace] días antes del último día contable; `null` si el hábito aún no existía al
  /// final de ese periodo.
  double? _cumplimientoEntre(int desdeHace, int hastaHace) {
    final h = _habito;
    if (h == null) {
      return null;
    }
    final fin = ultimoDiaContable.subtract(Duration(days: hastaHace));
    if (Fechas.soloFecha(h.fechaCreacion).isAfter(fin)) {
      return null;
    }
    return EstadisticasHabito.cumplimiento(
      frecuencia: h.frecuencia,
      registros: _registros,
      desde: ultimoDiaContable.subtract(Duration(days: desdeHace)),
      hasta: fin,
      creado: h.fechaCreacion,
    );
  }

  List<double> get tendencia {
    final h = _habito;
    return h == null
        ? const []
        : EstadisticasHabito.tendencia(
            frecuencia: h.frecuencia,
            registros: _registros,
            hoy: ultimoDiaContable,
            creado: h.fechaCreacion,
            semanas: semanasTendencia,
          );
  }

  /// Los check-ins más recientes primero.
  List<Registro> get historial {
    final lista = _registros.values.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista.take(renglonesHistorial).toList();
  }

  /// Niveles proyectados (como mucho 2), como la Escalera v2: +10 % al paso de la unidad sin pasar del óptimo de la
  /// evidencia. Si la meta ya está en el óptimo o arriba (o es un límite que se reduce), no hay proyección.
  List<double> get _proyectados {
    final h = _habito;
    final meta = _escalera?.metaActual ?? h?.meta;
    if (h == null || meta == null) {
      return const [];
    }
    final ev = h.evaluacion;
    if (ev == null) {
      return EstadisticasHabito.proyeccion(meta);
    }
    if (ev.sentido == SentidoHabito.reducir ||
        !(ev.zona == ZonaEvidencia.bajo || ev.zona == ZonaEvidencia.sinReferencia)) {
      return const [];
    }
    return EstadisticasHabito.proyeccionConEvidencia(
      meta,
      paso: ev.paso,
      techo: ev.zona == ZonaEvidencia.bajo ? ev.optimoHasta : null,
      cuantos: 2,
    );
  }

  /// "Nivel 3 de 5": el actual más los proyectados (contrato §6.4).
  int get totalNiveles => (_escalera?.nivelActual ?? _habito?.nivel ?? 1) + _proyectados.length;

  /// La meta del siguiente micro-paso: la sugerencia pendiente o, si no hay, el primer nivel proyectado. `null` si la
  /// Escalera está apagada o si ya no hay que subir ("ritmo ideal").
  double? get siguienteMeta {
    final e = _escalera;
    if (e == null || !e.escaleraActiva) {
      return null;
    }
    return e.sugerenciaPendiente?.metaPropuesta ?? _proyectados.firstOrNull;
  }

  // ───────────────────────── Carga ─────────────────────────

  Future<Result<void>> _cargar() async {
    final dia = hoy;
    final resultados = await Future.wait<Result<Object?>>([
      _repoHabitos.obtener(habitoId, fecha: dia),
      _repoHabitos.registros(
        habitoId,
        desde: dia.subtract(const Duration(days: Limites.historialMaxDias - 1)),
        hasta: dia,
      ),
      _repoHabitos.escalera(habitoId),
    ]);
    for (final r in resultados.take(2)) {
      if (r case Fallo(:final error)) {
        return Result.fallo(error);
      }
    }
    _habito = resultados[0].valorONulo! as Habito;
    final registros = resultados[1].valorONulo! as List<Registro>;
    _registros = {for (final r in registros) Fechas.soloFecha(r.fecha): r};
    _escalera = resultados[2].valorONulo as EscaleraHabito?;
    notifyListeners();
    return const Result.exito(null);
  }

  Future<Result<Habito>> _reactivar() async {
    final r = await _repoHabitos.actualizar(habitoId, const CambiosHabito(activo: true));
    if (r case Exito(valor: final h)) {
      _habito = h;
      notifyListeners();
    }
    return r;
  }

  @override
  void dispose() {
    cargar.dispose();
    reactivar.dispose();
    super.dispose();
  }
}
