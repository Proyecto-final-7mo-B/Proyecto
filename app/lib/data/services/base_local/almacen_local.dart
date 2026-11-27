import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../domain/models/categoria.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/fechas.dart';
import 'base_local.dart';

/// Lo que los repositorios guardan y leen de la base local. Aquí está todo el SQL: los repositorios no conocen drift.
class AlmacenLocal {
  AlmacenLocal(this.base);

  final BaseLocal base;

  static const String _marcaHabitos = 'habitos_guardados';

  // ───────────────────────── Categorías ─────────────────────────

  Future<void> guardarCategorias(List<Categoria> lista) => base.transaction(() async {
    await base.delete(base.categorias).go();
    await base.batch(
      (b) => b.insertAll(base.categorias, [
        for (final (i, c) in lista.indexed)
          CategoriasCompanion.insert(
            id: c.id,
            nombre: c.nombre,
            activa: Value(c.activa),
            datos: jsonEncode(c.toJson()),
            orden: i,
          ),
      ]),
    );
  });

  /// El catálogo guardado, en el orden en que llegó, con sus subcategorías, unidades y referencias.
  Future<List<Categoria>> categorias() async {
    final filas = await (base.select(base.categorias)..orderBy([(c) => OrderingTerm.asc(c.orden)])).get();
    return [for (final f in filas) Categoria.fromJson(jsonDecode(f.datos) as Map<String, dynamic>)];
  }

  // ───────────────────────── Hábitos ─────────────────────────

  /// Guarda la lista de `GET /habitos`. Con [incluyeArchivados] reemplaza todos; si no, solo los activos (los
  /// archivados guardados antes se quedan).
  Future<void> guardarHabitos(List<Habito> lista, {required bool incluyeArchivados}) => base.transaction(() async {
    final borrar = base.delete(base.habitos);
    if (!incluyeArchivados) {
      borrar.where((h) => h.activo.equals(true));
    }
    await borrar.go();
    for (final h in lista) {
      await guardarHabito(h);
    }
    await base
        .into(base.marcas)
        .insertOnConflictUpdate(MarcasCompanion.insert(clave: _marcaHabitos, valor: DateTime.now().toIso8601String()));
  });

  Future<void> guardarHabito(Habito h) => base
      .into(base.habitos)
      .insertOnConflictUpdate(
        HabitosCompanion.insert(id: h.id, datos: jsonEncode(h.toJson()), activo: h.activo, guardadoEn: DateTime.now()),
      );

  /// `true` si la lista de hábitos ya se guardó alguna vez (aunque haya estado vacía).
  Future<bool> hayHabitosGuardados() async =>
      await (base.select(base.marcas)..where((m) => m.clave.equals(_marcaHabitos))).getSingleOrNull() != null;

  Future<List<Habito>> habitos({bool incluyeArchivados = false}) async {
    final consulta = base.select(base.habitos);
    if (!incluyeArchivados) {
      consulta.where((h) => h.activo.equals(true));
    }
    // Como `GET /habitos` (v1.6): por prioridad y después por nombre.
    return [for (final f in await consulta.get()) _habito(f)]..sort((a, b) {
      final p = a.prioridad.compareTo(b.prioridad);
      return p != 0 ? p : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
  }

  Future<Habito?> habito(String id) async {
    final f = await (base.select(base.habitos)..where((h) => h.id.equals(id))).getSingleOrNull();
    return f == null ? null : _habito(f);
  }

  static Habito _habito(FilaHabito f) => Habito.fromJson(jsonDecode(f.datos) as Map<String, dynamic>);

  // ───────────────────────── Check-ins ─────────────────────────

  /// Guarda check-ins del servidor. Un solo check-in por hábito y día: el nuevo reemplaza al anterior.
  Future<void> guardarRegistros(List<Registro> lista) => base.transaction(() async {
    for (final r in lista) {
      await _guardarRegistro(r);
    }
  });

  Future<void> _guardarRegistro(Registro r) async {
    final fecha = Fechas.iso(r.fecha);
    await (base.delete(
      base.registros,
    )..where((x) => x.id.equals(r.id) | (x.habitoId.equals(r.habitoId) & x.fecha.equals(fecha)))).go();
    await base
        .into(base.registros)
        .insert(
          RegistrosCompanion.insert(
            id: r.id,
            habitoId: r.habitoId,
            fecha: fecha,
            cumplido: r.cumplido,
            valor: Value(r.valor),
            origen: r.origen.name,
            registradoEn: Value(r.registradoEn),
          ),
        );
  }

  Future<List<Registro>> registros(String habitoId, {required DateTime desde, required DateTime hasta}) async {
    final filas =
        await (base.select(base.registros)
              ..where(
                (r) =>
                    r.habitoId.equals(habitoId) &
                    r.fecha.isBiggerOrEqualValue(Fechas.iso(desde)) &
                    r.fecha.isSmallerOrEqualValue(Fechas.iso(hasta)),
              )
              ..orderBy([(r) => OrderingTerm.asc(r.fecha)]))
            .get();
    return [for (final f in filas) _registro(f)];
  }

  Future<Registro?> registro(String habitoId, DateTime fecha) async {
    final f = await (base.select(
      base.registros,
    )..where((r) => r.habitoId.equals(habitoId) & r.fecha.equals(Fechas.iso(fecha)))).getSingleOrNull();
    return f == null ? null : _registro(f);
  }

  static Registro _registro(FilaRegistro f) => Registro(
    id: f.id,
    habitoId: f.habitoId,
    fecha: DateTime.parse('${f.fecha}T00:00:00Z'),
    cumplido: f.cumplido,
    valor: f.valor,
    origen: OrigenRegistro.values.byName(f.origen),
    registradoEn: f.registradoEn,
  );

  // ───────────────────────── Cola sin conexión ─────────────────────────

  /// **Guardar + encolar en una sola transacción** (diseño §7.5): o quedan los dos o ninguno. Devuelve el check-in
  /// que había ese día (para regresarlo si el servidor rechaza el nuevo).
  Future<Registro?> guardarYEncolar(NuevoRegistro r) => base.transaction(() async {
    final anterior = await registro(r.habitoId, r.fecha);
    await _guardarRegistro(
      Registro(id: r.id, habitoId: r.habitoId, fecha: r.fecha, cumplido: r.cumplido, valor: r.valor, origen: r.origen),
    );
    final fecha = Fechas.iso(r.fecha);
    // Uno por hábito y día: si ya había otro pendiente ese día, el nuevo lo reemplaza (gana el último).
    await (base.delete(
      base.colaPendientes,
    )..where((p) => p.id.equals(r.id) | (p.habitoId.equals(r.habitoId) & p.fecha.equals(fecha)))).go();
    await base
        .into(base.colaPendientes)
        .insert(
          ColaPendientesCompanion.insert(
            id: r.id,
            habitoId: r.habitoId,
            fecha: fecha,
            cumplido: r.cumplido,
            valor: Value(r.valor),
            creadoEn: DateTime.now(),
          ),
        );
    return anterior;
  });

  /// El servidor rechazó el check-in al momento: se quita de la cola y se regresa el que había (o ninguno).
  Future<void> deshacer(NuevoRegistro r, Registro? anterior) => base.transaction(() async {
    await desencolar(r.id);
    await (base.delete(base.registros)..where((x) => x.id.equals(r.id))).go();
    if (anterior != null) {
      await _guardarRegistro(anterior);
    }
  });

  Future<void> desencolar(String id) => (base.delete(base.colaPendientes)..where((p) => p.id.equals(id))).go();

  /// Los que faltan por enviar (sin los rechazados), del más viejo al más nuevo, como los pide `POST /registros/lote`
  /// (`origen: offline` y la fecha local original).
  Future<List<NuevoRegistro>> pendientes({int limite = 100}) async {
    final filas =
        await (base.select(base.colaPendientes)
              ..where((p) => p.rechazado.equals(false))
              ..orderBy([(p) => OrderingTerm.asc(p.creadoEn)])
              ..limit(limite))
            .get();
    return [
      for (final f in filas)
        NuevoRegistro(
          id: f.id,
          habitoId: f.habitoId,
          fecha: DateTime.parse('${f.fecha}T00:00:00Z'),
          cumplido: f.cumplido,
          valor: f.valor,
          origen: OrigenRegistro.offline,
        ),
    ];
  }

  /// Pendiente (sin enviar) de [habitoId] en [fecha], si hay.
  Future<NuevoRegistro?> pendienteDe(String habitoId, DateTime fecha) async {
    final f =
        await (base.select(base.colaPendientes)..where(
              (p) => p.habitoId.equals(habitoId) & p.fecha.equals(Fechas.iso(fecha)) & p.rechazado.equals(false),
            ))
            .getSingleOrNull();
    return f == null
        ? null
        : NuevoRegistro(
            id: f.id,
            habitoId: f.habitoId,
            fecha: fecha,
            cumplido: f.cumplido,
            valor: f.valor,
            origen: OrigenRegistro.offline,
          );
  }

  /// Rechazado por el servidor: se marca con su motivo y ya no se reintenta. Su check-in local se quita.
  Future<void> marcarRechazado(String id, String motivo) => base.transaction(() async {
    await (base.update(base.colaPendientes)..where((p) => p.id.equals(id))).write(
      ColaPendientesCompanion(rechazado: const Value(true), ultimoError: Value(motivo)),
    );
    await (base.delete(base.registros)..where((r) => r.id.equals(id))).go();
  });

  /// El envío falló (sin red o error del servidor): se suma un intento y se guarda el motivo.
  Future<void> anotarIntento(Iterable<String> ids, String motivo) => base.transaction(() async {
    for (final id in ids) {
      await base.customUpdate(
        'UPDATE cola_pendientes SET intentos = intentos + 1, ultimo_error = ? WHERE id = ?',
        variables: [Variable.withString(motivo), Variable.withString(id)],
        updates: {base.colaPendientes},
      );
    }
  });

  /// Cuántos faltan por enviar y cuántos rechazó el servidor; se actualiza solo con cada cambio de la cola.
  Stream<({int pendientes, int rechazados})> observarCola() => base
      .select(base.colaPendientes)
      .watch()
      .map(
        (filas) =>
            (pendientes: filas.where((f) => !f.rechazado).length, rechazados: filas.where((f) => f.rechazado).length),
      );

  // ───────────────────────── Estado de hoy sin conexión ─────────────────────────

  /// Aplica a [h] el check-in local de [fecha] (pendiente o guardado sin conexión): `hoy` y la racha **estimada**.
  ///
  /// La racha del servidor ya incluye lo que el servidor sabía; aquí solo se suma o resta la diferencia con el
  /// check-in local. Al sincronizar, el servidor manda la racha real.
  static Habito conCheckinLocal(
    Habito h, {
    required DateTime fecha,
    required bool cumplido,
    String? id,
    double? valor,
  }) {
    final hoyServidor = h.hoy?.fecha == fecha ? h.hoy : null;
    final servidorCumplido = hoyServidor?.cumplido ?? (h.racha.ultimaFecha == fecha);
    final delta = (cumplido ? 1 : 0) - (servidorCumplido ? 1 : 0);
    final actual = max(0, h.racha.actual + delta);
    return h.copyWith(
      racha: Racha(
        actual: actual,
        maxima: max(h.racha.maxima, actual),
        ultimaFecha: cumplido ? fecha : (h.racha.ultimaFecha == fecha ? null : h.racha.ultimaFecha),
      ),
      hoy: HoyHabito(
        fecha: fecha,
        programado: hoyServidor?.programado ?? h.frecuencia.programadoEn(fecha),
        registro: RegistroDeHoy(id: id ?? hoyServidor?.registro?.id ?? '', cumplido: cumplido, valor: valor),
      ),
    );
  }

  /// El check-in llegó al servidor: la copia del hábito toma la racha real y el estado de ese día, para que una
  /// estimación posterior sin conexión no lo cuente dos veces.
  Future<void> confirmarCheckin(NuevoRegistro r, int rachaActual) async {
    final h = await habito(r.habitoId);
    if (h == null) {
      return;
    }
    final base = conCheckinLocal(h, fecha: r.fecha, cumplido: r.cumplido, id: r.id, valor: r.valor);
    await guardarHabito(
      base.copyWith(
        racha: Racha(
          actual: rachaActual,
          maxima: max(base.racha.maxima, rachaActual),
          ultimaFecha: base.racha.ultimaFecha,
        ),
        hoy: h.hoy?.fecha == r.fecha ? base.hoy : h.hoy,
      ),
    );
  }

  // ───────────────────────── Recordatorios ─────────────────────────

  Future<void> guardarRecordatorio(String habitoId, int hora, int minuto) => base
      .into(base.recordatorios)
      .insertOnConflictUpdate(RecordatoriosCompanion.insert(habitoId: habitoId, hora: hora, minuto: minuto));

  Future<void> quitarRecordatorio(String habitoId) =>
      (base.delete(base.recordatorios)..where((r) => r.habitoId.equals(habitoId))).go();

  Future<({int hora, int minuto})?> recordatorio(String habitoId) async {
    final f = await (base.select(base.recordatorios)..where((r) => r.habitoId.equals(habitoId))).getSingleOrNull();
    return f == null ? null : (hora: f.hora, minuto: f.minuto);
  }

  // ───────────────────────── Sesión ─────────────────────────

  Future<void> borrarTodo() => base.borrarTodo();
}
