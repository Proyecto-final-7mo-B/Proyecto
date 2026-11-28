/// Avisos locales (Paso 10): notificaciones que la app programa en el propio dispositivo. No pasan por la API ni por
/// la base; las preferencias y el historial se guardan solo en el dispositivo (doc. 06 de la investigación).
library;

/// Hora del día (24 h).
typedef Hora = ({int hora, int minuto});

/// "07:30".
String formatoHoraAviso(Hora h) => '${h.hora.toString().padLeft(2, '0')}:${h.minuto.toString().padLeft(2, '0')}';

/// Minutos desde la medianoche.
int minutosDe(Hora h) => h.hora * 60 + h.minuto;

Hora _hora(Object? json, Hora defecto) {
  if (json is Map && json['hora'] is int && json['minuto'] is int) {
    return (hora: json['hora'] as int, minuto: json['minuto'] as int);
  }
  return defecto;
}

Map<String, int> _horaJson(Hora h) => {'hora': h.hora, 'minuto': h.minuto};

enum TipoAviso {
  /// El recordatorio de un hábito, a la hora que eligió el usuario.
  recordatorio,

  /// Un aviso que el usuario programó ("Mis avisos").
  personal,

  /// 20:00 (configurable): racha de 3 o más y el hábito sigue pendiente.
  rachaEnRiesgo,

  /// La Escalera dejó una sugerencia nueva.
  microPaso,

  /// Resumen de la semana (domingo 18:00, configurable).
  resumenSemanal;

  /// Los que decide la app (no el usuario): cuentan para el tope diario y respetan las horas de silencio.
  bool get automatico => this == rachaEnRiesgo || this == microPaso || this == resumenSemanal;
}

/// Un aviso que el usuario programó: hora, días (máscara L=1 … D=64) y su texto.
class AvisoPersonal {
  const AvisoPersonal({
    required this.id,
    required this.hora,
    required this.dias,
    required this.texto,
    this.activo = true,
  });

  factory AvisoPersonal.fromJson(Map<String, dynamic> j) => AvisoPersonal(
    id: j['id'] as String,
    hora: _hora(j['hora'], (hora: 9, minuto: 0)),
    dias: j['dias'] as int? ?? 127,
    texto: j['texto'] as String? ?? '',
    activo: j['activo'] as bool? ?? true,
  );

  final String id;
  final Hora hora;

  /// Bit 0 = lunes … bit 6 = domingo; 127 = todos los días.
  final int dias;
  final String texto;
  final bool activo;

  bool tocaEn(DateTime fecha) => dias & (1 << (fecha.weekday - 1)) != 0;

  AvisoPersonal copyWith({Hora? hora, int? dias, String? texto, bool? activo}) => AvisoPersonal(
    id: id,
    hora: hora ?? this.hora,
    dias: dias ?? this.dias,
    texto: texto ?? this.texto,
    activo: activo ?? this.activo,
  );

  Map<String, dynamic> toJson() => {'id': id, 'hora': _horaJson(hora), 'dias': dias, 'texto': texto, 'activo': activo};
}

/// Lo que el usuario decide de sus avisos. Valores por omisión del doc. 06.
class PreferenciasAvisos {
  const PreferenciasAvisos({
    this.recordatorios = true,
    this.rachaEnRiesgo = true,
    this.horaRachaEnRiesgo = (hora: 20, minuto: 0),
    this.microPaso = true,
    this.resumenSemanal = true,
    this.diaResumen = DateTime.sunday,
    this.horaResumen = (hora: 18, minuto: 0),
    this.silencioDesde = (hora: 22, minuto: 0),
    this.silencioHasta = (hora: 8, minuto: 0),
    this.personales = const [],
  });

  factory PreferenciasAvisos.fromJson(Map<String, dynamic> j) {
    const d = PreferenciasAvisos();
    return PreferenciasAvisos(
      recordatorios: j['recordatorios'] as bool? ?? d.recordatorios,
      rachaEnRiesgo: j['racha_en_riesgo'] as bool? ?? d.rachaEnRiesgo,
      horaRachaEnRiesgo: _hora(j['hora_racha_en_riesgo'], d.horaRachaEnRiesgo),
      microPaso: j['micro_paso'] as bool? ?? d.microPaso,
      resumenSemanal: j['resumen_semanal'] as bool? ?? d.resumenSemanal,
      diaResumen: j['dia_resumen'] as int? ?? d.diaResumen,
      horaResumen: _hora(j['hora_resumen'], d.horaResumen),
      silencioDesde: _hora(j['silencio_desde'], d.silencioDesde),
      silencioHasta: _hora(j['silencio_hasta'], d.silencioHasta),
      personales: [
        for (final a in j['personales'] as List<dynamic>? ?? const [])
          AvisoPersonal.fromJson(a as Map<String, dynamic>),
      ],
    );
  }

  /// Recordatorios de los hábitos (la hora de cada uno se elige en el hábito).
  final bool recordatorios;
  final bool rachaEnRiesgo;
  final Hora horaRachaEnRiesgo;
  final bool microPaso;
  final bool resumenSemanal;

  /// 1 = lunes … 7 = domingo.
  final int diaResumen;
  final Hora horaResumen;

  /// Horas en que la app no manda avisos automáticos (lo que el usuario programa sí llega).
  final Hora silencioDesde;
  final Hora silencioHasta;
  final List<AvisoPersonal> personales;

  /// `true` si [h] cae en las horas de silencio (que pueden cruzar la medianoche).
  bool enSilencio(Hora h) {
    final m = minutosDe(h);
    final desde = minutosDe(silencioDesde);
    final hasta = minutosDe(silencioHasta);
    if (desde == hasta) {
      return false;
    }
    return desde < hasta ? m >= desde && m < hasta : m >= desde || m < hasta;
  }

  PreferenciasAvisos copyWith({
    bool? recordatorios,
    bool? rachaEnRiesgo,
    Hora? horaRachaEnRiesgo,
    bool? microPaso,
    bool? resumenSemanal,
    int? diaResumen,
    Hora? horaResumen,
    Hora? silencioDesde,
    Hora? silencioHasta,
    List<AvisoPersonal>? personales,
  }) => PreferenciasAvisos(
    recordatorios: recordatorios ?? this.recordatorios,
    rachaEnRiesgo: rachaEnRiesgo ?? this.rachaEnRiesgo,
    horaRachaEnRiesgo: horaRachaEnRiesgo ?? this.horaRachaEnRiesgo,
    microPaso: microPaso ?? this.microPaso,
    resumenSemanal: resumenSemanal ?? this.resumenSemanal,
    diaResumen: diaResumen ?? this.diaResumen,
    horaResumen: horaResumen ?? this.horaResumen,
    silencioDesde: silencioDesde ?? this.silencioDesde,
    silencioHasta: silencioHasta ?? this.silencioHasta,
    personales: personales ?? this.personales,
  );

  Map<String, dynamic> toJson() => {
    'recordatorios': recordatorios,
    'racha_en_riesgo': rachaEnRiesgo,
    'hora_racha_en_riesgo': _horaJson(horaRachaEnRiesgo),
    'micro_paso': microPaso,
    'resumen_semanal': resumenSemanal,
    'dia_resumen': diaResumen,
    'hora_resumen': _horaJson(horaResumen),
    'silencio_desde': _horaJson(silencioDesde),
    'silencio_hasta': _horaJson(silencioHasta),
    'personales': [for (final a in personales) a.toJson()],
  };
}

/// Un aviso listo para el sistema.
class AvisoProgramado {
  const AvisoProgramado({
    required this.id,
    required this.cuando,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    this.habitoId,
    this.plantilla = 0,
    this.sugerenciaId,
  });

  /// Id del sistema (entero de 32 bits).
  final int id;

  /// Hora local del dispositivo.
  final DateTime cuando;
  final TipoAviso tipo;
  final String titulo;
  final String cuerpo;
  final String? habitoId;

  /// Qué texto de su tipo se usó (para no repetir los últimos 3).
  final int plantilla;
  final String? sugerenciaId;
}

/// Lo que se recuerda de los avisos para adaptar los siguientes: qué se programó y cuándo hubo check-in.
class EventoAviso {
  const EventoAviso({required this.cuando, this.tipo, this.habitoId, this.plantilla, this.sugerenciaId});

  /// Un check-in (cumplido) de [habitoId].
  const EventoAviso.checkin({required this.cuando, required String this.habitoId})
    : tipo = null,
      plantilla = null,
      sugerenciaId = null;

  factory EventoAviso.desdeAviso(AvisoProgramado a) => EventoAviso(
    cuando: a.cuando,
    tipo: a.tipo,
    habitoId: a.habitoId,
    plantilla: a.plantilla,
    sugerenciaId: a.sugerenciaId,
  );

  factory EventoAviso.fromJson(Map<String, dynamic> j) => EventoAviso(
    cuando: DateTime.parse(j['cuando'] as String),
    tipo: switch (j['tipo']) {
      final String t => TipoAviso.values.byName(t),
      _ => null,
    },
    habitoId: j['habito'] as String?,
    plantilla: j['plantilla'] as int?,
    sugerenciaId: j['sugerencia'] as String?,
  );

  final DateTime cuando;

  /// `null` = check-in.
  final TipoAviso? tipo;
  final String? habitoId;
  final int? plantilla;
  final String? sugerenciaId;

  bool get esCheckin => tipo == null;

  Map<String, dynamic> toJson() => {
    'cuando': cuando.toIso8601String(),
    'tipo': ?tipo?.name,
    'habito': ?habitoId,
    'plantilla': ?plantilla,
    'sugerencia': ?sugerenciaId,
  };
}
