import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/data/services/recordatorios/servicio_recordatorios.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/widgets/calendario_mes.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/core/widgets/contador_meta.dart';
import 'package:kaizen/ui/core/widgets/tarjeta_kpi.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_detalle_habito.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_formulario_habito.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_habitos.dart';
import 'package:kaizen/ui/habitos/widgets/tarjeta_evidencia_habito.dart';
import 'package:kaizen/ui/habitos/widgets/tarjetas_detalle.dart';
import 'package:kaizen/ui/habitos/widgets/vista_previa_habito.dart';

import '../../helpers/app.dart';

const Size escritorio = Size(1440, 900);

/// Datos de Daniela con el reloj fijo y los recordatorios en memoria (los de [recordatorios]).
({Dependencias deps, ServicioRecordatoriosEnMemoria recordatorios}) preparar({bool conRecordatorios = true}) {
  final r = ServicioRecordatoriosEnMemoria(disponible: conRecordatorios);
  return (
    deps: Dependencias.fake(
      datos: DatosDemo(reloj: () => ahoraPrueba),
      recordatorios: r,
    ),
    recordatorios: r,
  );
}

String idDe(Dependencias deps, String nombre) =>
    deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == nombre).id;

/// Toca [f]; si la lista aún no lo construyó, primero desplaza la pantalla.
Future<void> tocar(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    // El Scrollable de la pantalla (el primero dentro de la página), no el de un campo de texto.
    final pantalla = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is PantallaHabitos || w is PantallaFormularioHabito || w is PantallaDetalleHabito,
      ),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(f, 200, scrollable: pantalla.first);
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder campo(String etiqueta) =>
    find.descendant(of: find.widgetWithText(CampoValidado, etiqueta), matching: find.byType(TextField));

void main() {
  group('lista', () {
    testWidgets('activos con su conteo; los archivados en su pestaña', (tester) async {
      final p = preparar();
      p.deps.datosDemo!.habitos[idDe(p.deps, 'Dormir 7 h')]!.activo = false;
      await montarApp(tester, ubicacion: Rutas.habitos, dependencias: p.deps);
      expect(find.byType(PantallaHabitos), findsOneWidget);
      expect(find.text('Activos (4)'), findsOneWidget);
      expect(find.text('Archivados (1)'), findsOneWidget);
      expect(find.byType(FilaHabitoLista), findsNWidgets(4));
      expect(find.text('20 min · L-V'), findsOneWidget);
      await tocar(tester, find.text('Archivados (1)'));
      expect(find.byType(FilaHabitoLista), findsOneWidget);
      expect(find.text('7 h · diario · Archivado'), findsOneWidget);
    });

    testWidgets('sin archivados y sin hábitos: estados vacíos', (tester) async {
      await montarApp(tester, ubicacion: Rutas.habitos, cuentaDemo: 'u-nuevo');
      expect(find.text('Aún no tienes hábitos'), findsOneWidget);
      await tocar(tester, find.text('Archivados (0)'));
      expect(find.text('No tienes hábitos archivados.'), findsOneWidget);
    });

    testWidgets('tocar un hábito abre su detalle', (tester) async {
      await montarApp(tester, ubicacion: Rutas.habitos);
      await tocar(tester, find.text('Leer'));
      expect(find.byType(PantallaDetalleHabito), findsOneWidget);
    });

    testWidgets('si no carga: error y Reintentar', (tester) async {
      final p = preparar();
      p.deps.datosDemo!.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await montarApp(tester, ubicacion: Rutas.habitos, dependencias: p.deps);
      expect(find.text('Sin conexión a internet.'), findsOneWidget);
      await tocar(tester, find.text('Reintentar'));
      expect(find.byType(FilaHabitoLista), findsNWidgets(5));
    });
  });

  group('nuevo hábito (teléfono)', () {
    testWidgets('crear con días, meta, unidad y recordatorio; vuelve a la lista y aparece', (tester) async {
      final p = preparar();
      await montarApp(tester, ubicacion: Rutas.habitos, dependencias: p.deps);
      await tocar(tester, find.byTooltip('Nuevo hábito'));
      expect(find.byType(PantallaFormularioHabito), findsOneWidget);
      expect(find.text('Empieza pequeño: 5 minutos bastan para crear el hábito.'), findsOneWidget);

      await tester.enterText(campo('Nombre'), 'Caminar');
      await tocar(tester, find.text('Ejercicio'));
      await tocar(tester, find.text('Aeróbico moderado'));
      expect(find.text('25 min'), findsOneWidget, reason: 'arranca en el inicio de lo recomendado (OMS)');
      expect(find.text('Dentro de lo recomendado'), findsOneWidget);
      await tocar(tester, find.text('Días'));
      await tocar(tester, find.text('V'));
      expect(find.text('Por debajo de lo recomendado'), findsOneWidget, reason: '25 × 4 = 100 min/semana');
      await tocar(tester, find.descendant(of: find.byType(ContadorMeta), matching: find.byIcon(Icons.add)));
      expect(find.text('30 min'), findsOneWidget, reason: 'sube de 5 en 5 (paso de la unidad)');
      await tocar(tester, find.text('Sin recordatorio'));
      // Selector de hora del sistema: se acepta la hora propuesta (07:30) con su botón de confirmar.
      final dialogo = tester.element(find.byType(Dialog));
      await tester.tap(find.text(MaterialLocalizations.of(dialogo).okButtonLabel));
      await tester.pumpAndSettle();
      expect(find.text('07:30'), findsOneWidget);
      await tocar(tester, find.text('Guardar hábito'));

      expect(find.byType(PantallaHabitos), findsOneWidget);
      expect(find.text('Listo: Caminar ya está en tu lista.'), findsOneWidget);
      expect(find.text('30 min · L, Ma, Mi, J'), findsOneWidget);
      final h = p.deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Caminar');
      expect(h.frecuencia, const DiasSemana(15));
      expect(p.recordatorios.programados[h.id]!.hora, (hora: 7, minuto: 30));
    });

    testWidgets('valida antes de llamar a la API: nombre, categoría y días', (tester) async {
      final p = preparar();
      final antes = p.deps.datosDemo!.habitos.length;
      await montarApp(tester, ubicacion: Rutas.nuevoHabito, dependencias: p.deps);
      await tocar(tester, find.text('Días'));
      for (final d in ['L', 'Ma', 'Mi', 'J', 'V']) {
        await tocar(tester, find.text(d));
      }
      await tocar(tester, find.text('Guardar hábito'));
      expect(find.text('Este campo es obligatorio.'), findsNWidgets(2), reason: 'nombre y categoría');
      await tocar(tester, find.text('Bienestar'));
      expect(find.text('Elige el tipo de hábito.'), findsOneWidget);
      expect(find.text('Elige al menos un día.'), findsOneWidget);
      expect(p.deps.datosDemo!.habitos.length, antes);
    });

    testWidgets('"N por sem." muestra el contador de veces', (tester) async {
      await montarApp(tester, ubicacion: Rutas.nuevoHabito);
      await tocar(tester, find.text('N por sem.'));
      expect(find.text('Veces por semana'), findsOneWidget);
      expect(find.text('3 veces'), findsOneWidget);
    });

    testWidgets('con cápsula: al guardar abre la pantalla de la cápsula de ese hábito', (tester) async {
      final p = preparar();
      await montarApp(tester, ubicacion: Rutas.nuevoHabito, dependencias: p.deps);
      await tester.enterText(campo('Nombre'), 'Meditar');
      await tocar(tester, find.text('Bienestar'));
      await tocar(tester, find.text('Meditación'));
      await tocar(tester, find.text('30 días'));
      await tocar(tester, find.text('Guardar hábito'));
      final h = p.deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Meditar');
      expect(find.text('Nueva cápsula'), findsWidgets);
      expect(find.text(h.id), findsOneWidget, reason: 'la pantalla provisional muestra el hábito de la cápsula');
    });

    testWidgets('si el servidor falla, avisa y se queda en el formulario', (tester) async {
      final p = preparar();
      await montarApp(tester, ubicacion: Rutas.nuevoHabito, dependencias: p.deps);
      await tester.enterText(campo('Nombre'), 'Meditar');
      await tocar(tester, find.text('Bienestar'));
      await tocar(tester, find.text('Meditación'));
      p.deps.datosDemo!.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await tocar(tester, find.text('Guardar hábito'));
      expect(find.text('Sin conexión a internet.'), findsOneWidget);
      expect(find.byType(PantallaFormularioHabito), findsOneWidget);
    });

    testWidgets('un error del servidor en un campo sale junto al campo', (tester) async {
      final p = preparar();
      await montarApp(tester, ubicacion: Rutas.nuevoHabito, dependencias: p.deps);
      await tester.enterText(campo('Nombre'), 'Meditar');
      await tocar(tester, find.text('Bienestar'));
      await tocar(tester, find.text('Meditación'));
      p.deps.datosDemo!.fallarSiguiente(DatosDemo.validacion({'nombre': 'Nombre no permitido'}));
      await tocar(tester, find.text('Guardar hábito'));
      expect(find.text('Nombre no permitido'), findsOneWidget);
    });
  });

  group('nuevo hábito (escritorio)', () {
    testWidgets('vista previa y escalera inicial; sin recordatorio; Cancelar regresa', (tester) async {
      final p = preparar(conRecordatorios: false);
      await montarApp(
        tester,
        plataforma: Plataforma.escritorio,
        tamano: escritorio,
        ubicacion: Rutas.habitos,
        dependencias: p.deps,
      );
      await tocar(tester, find.widgetWithText(FilledButton, 'Nuevo hábito'));
      expect(find.byType(VistaPreviaHabito), findsOneWidget);
      expect(find.text('Un hábito pequeño es un hábito que dura'), findsOneWidget);
      expect(find.text('Recordatorio'), findsNothing);
      await tester.enterText(campo('Nombre'), 'Leer poesía');
      await tester.pumpAndSettle();
      expect(find.text('Leer poesía'), findsNWidgets(2), reason: 'en el campo y en "Así se verá"');
      await tocar(tester, find.text('Educación'));
      await tocar(tester, find.text('Lectura'));
      await tocar(tester, find.descendant(of: find.byType(ContadorMeta), matching: find.byIcon(Icons.remove)));
      expect(find.text('Aquí vas'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget, reason: '25 min es bajo: la escalera proyecta hasta lo recomendado');
      await tocar(tester, find.byType(Switch));
      expect(find.text('Tu escalera inicial'), findsNothing, reason: 'sin Escalera no hay escalera inicial');
      await tocar(tester, find.text('Cancelar'));
      expect(find.byType(PantallaHabitos), findsOneWidget);
    });
  });

  group('evidencia, prioridad e intención (teléfono)', () {
    testWidgets('2 h diarias de ejercicio: "Más de lo recomendado" y "Usar 85 min" lo corrige', (tester) async {
      await montarApp(tester, ubicacion: Rutas.nuevoHabito);
      await tocar(tester, find.text('Ejercicio'));
      await tocar(tester, find.text('Aeróbico moderado'));
      await tocar(tester, find.text('h'));
      for (var i = 0; i < 6; i++) {
        await tocar(tester, find.descendant(of: find.byType(ContadorMeta), matching: find.byIcon(Icons.add)));
      }
      expect(find.text('2 h'), findsOneWidget);
      expect(find.text('Más de lo recomendado'), findsOneWidget);
      expect(find.textContaining('Fuente: OMS 2020'), findsOneWidget);
      expect(find.textContaining('Evidencia sólida'), findsOneWidget);
      await tocar(tester, find.text('Usar 1.25 h'));
      expect(find.text('1.25 h'), findsOneWidget);
      expect(find.text('Más de lo necesario'), findsOneWidget, reason: '525 min/semana: arriba del óptimo, sin pasar de 600');
    });

    testWidgets('sin rango científico (ahorro) lo dice; km sugiere minutos', (tester) async {
      await montarApp(tester, ubicacion: Rutas.nuevoHabito);
      await tocar(tester, find.text('Finanzas'));
      await tocar(tester, find.text('Ahorro'));
      expect(find.text('Sin rango científico: la meta la defines tú.'), findsOneWidget);
      await tocar(tester, find.text('Ejercicio'));
      await tocar(tester, find.text('Aeróbico moderado'));
      await tocar(tester, find.text('km'));
      expect(find.textContaining('usa min para recibir la recomendación'), findsOneWidget);
    });

    testWidgets('prioridad e intención se guardan; el aviso lleva la intención', (tester) async {
      final p = preparar();
      await montarApp(tester, ubicacion: Rutas.nuevoHabito, dependencias: p.deps);
      await tester.enterText(campo('Nombre'), 'Agua');
      await tocar(tester, find.text('Salud'));
      await tocar(tester, find.text('Hidratación'));
      await tocar(tester, find.text('Alta'));
      await tester.enterText(campo('¿Cuándo lo harás?'), 'Después de desayunar');
      await tocar(tester, find.text('Sin recordatorio'));
      final dialogo = tester.element(find.byType(Dialog));
      await tester.tap(find.text(MaterialLocalizations.of(dialogo).okButtonLabel));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Guardar hábito'));
      final h = p.deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Agua');
      expect((h.prioridad, h.intencion, h.unidad, h.meta), (1, 'Después de desayunar', 'L', 1.5));
      expect(p.recordatorios.programados[h.id]!.cuerpo, 'Después de desayunar: Agua');
    });

    testWidgets('intención de más de 120 caracteres no se guarda', (tester) async {
      final p = preparar();
      final antes = p.deps.datosDemo!.habitos.length;
      await montarApp(tester, ubicacion: Rutas.nuevoHabito, dependencias: p.deps);
      await tester.enterText(campo('Nombre'), 'Agua');
      await tocar(tester, find.text('Salud'));
      await tocar(tester, find.text('Hidratación'));
      await tester.enterText(campo('¿Cuándo lo harás?'), 'x' * 121);
      await tocar(tester, find.text('Guardar hábito'));
      expect(p.deps.datosDemo!.habitos.length, antes);
    });
  });

  group('editar', () {
    testWidgets('meta y frecuencia de solo lectura; cambiar el nombre regresa al detalle', (tester) async {
      final p = preparar();
      final leer = idDe(p.deps, 'Leer');
      await montarApp(tester, ubicacion: Rutas.habito(leer), dependencias: p.deps);
      await tocar(tester, find.byTooltip('Editar'));
      expect(find.text('Editar hábito'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('diario'), findsOneWidget);
      expect(find.textContaining('La meta y la frecuencia no se editan'), findsOneWidget);
      expect(find.textContaining('La unidad no cambia'), findsOneWidget);
      expect(find.text('30 días'), findsNothing, reason: 'al editar no se elige cápsula');
      expect(find.text('Por debajo de lo recomendado'), findsOneWidget, reason: 'la evidencia también al editar');
      expect(find.textContaining('Usar '), findsNothing, reason: 'al editar la meta solo cambia con la Escalera');
      await tester.enterText(campo('Nombre'), 'Leer novelas');
      await tocar(tester, find.text('Guardar cambios'));
      expect(find.byType(PantallaDetalleHabito), findsOneWidget);
      expect(find.text('Leer novelas'), findsOneWidget);
      expect(find.text('Cambios guardados.'), findsOneWidget);
    });

    testWidgets('archivar con confirmación; el detalle ofrece reactivarlo', (tester) async {
      final p = preparar();
      final leer = idDe(p.deps, 'Leer');
      await montarApp(tester, ubicacion: Rutas.habito(leer), dependencias: p.deps);
      await tocar(tester, find.byTooltip('Editar'));
      await tocar(tester, find.text('Archivar hábito'));
      expect(find.text('¿Archivar Leer?'), findsOneWidget);
      await tocar(tester, find.text('Archivar'));
      expect(p.deps.datosDemo!.habitos[leer]!.activo, isFalse);
      expect(find.byType(PantallaDetalleHabito), findsOneWidget);
      expect(find.text('Este hábito está archivado: no aparece en Hoy.'), findsOneWidget);
      await tocar(tester, find.text('Reactivar'));
      expect(find.text('Leer está activo de nuevo.'), findsOneWidget);
      expect(find.text('Este hábito está archivado: no aparece en Hoy.'), findsNothing);
    });

    testWidgets('cancelar la confirmación no archiva', (tester) async {
      final p = preparar();
      final leer = idDe(p.deps, 'Leer');
      await montarApp(tester, ubicacion: Rutas.editarHabito(leer), dependencias: p.deps);
      await tocar(tester, find.text('Archivar hábito'));
      await tocar(tester, find.text('Cancelar'));
      expect(p.deps.datosDemo!.habitos[leer]!.activo, isTrue);
    });
  });

  group('detalle', () {
    testWidgets('teléfono: racha, calendario con su % y meses, historial', (tester) async {
      final semantica = tester.ensureSemantics();
      final p = preparar();
      await montarApp(tester, ubicacion: Rutas.habito(idDe(p.deps, 'Leer')), dependencias: p.deps);
      expect(find.text('Lectura · 10 min · diario · Nivel 3'), findsOneWidget);
      expect(find.byType(TarjetaRacha), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Racha actual: 34 días')), findsOneWidget);
      expect(find.byType(TarjetaEvidenciaHabito), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(CalendarioMes),
        200,
        scrollable: find.descendant(of: find.byType(PantallaDetalleHabito), matching: find.byType(Scrollable)).first,
      );
      expect(find.text('Noviembre'), findsOneWidget);
      expect(find.text('100 %'), findsOneWidget);
      expect(find.byType(CalendarioMes), findsOneWidget);
      expect(find.byType(TarjetaKpi), findsNothing, reason: 'los KPI son de escritorio');
      await tocar(tester, find.byTooltip('Mes anterior'));
      expect(find.text('Octubre'), findsOneWidget);
      await tocar(tester, find.byTooltip('Mes siguiente'));
      expect(find.text('Noviembre'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('24 nov · Cumplido'),
        200,
        scrollable: find.descendant(of: find.byType(PantallaDetalleHabito), matching: find.byType(Scrollable)).first,
      );
      expect(find.text('24 nov · Cumplido'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('escritorio: KPIs, tendencia y nivel; "Ver escalera" abre la del hábito', (tester) async {
      final p = preparar();
      await montarApp(
        tester,
        plataforma: Plataforma.escritorio,
        tamano: escritorio,
        ubicacion: Rutas.habito(idDe(p.deps, 'Leer')),
        dependencias: p.deps,
      );
      expect(find.byType(TarjetaKpi), findsNWidgets(3));
      expect(find.text('Racha actual'), findsOneWidget);
      expect(find.text('Cumplimiento 30 días'), findsOneWidget);
      expect(find.byType(TarjetaTendencia), findsOneWidget);
      expect(find.text('Nivel 3 de 5 · 10 min'), findsOneWidget);
      expect(find.text('Siguiente micro-paso: 11 min'), findsOneWidget);
      expect(find.byType(TarjetaEvidenciaHabito), findsOneWidget);
      expect(find.text('Por debajo de lo recomendado'), findsOneWidget);
      expect(find.text('Te faltan 32 días para los 66, la mediana para formar un hábito.'), findsOneWidget);
      expect(find.text('Protector disponible: fallar un día esta semana no rompe tu racha.'), findsOneWidget);
      expect(find.text('Cuándo: Antes de dormir'), findsOneWidget);
      await tocar(tester, find.text('Ver escalera'));
      expect(find.text('Escalera del hábito'), findsWidgets);
    });

    testWidgets('en el óptimo: "Ritmo ideal" en lugar del micro-paso; con 66 días, "Hábito formado"', (tester) async {
      final p = preparar();
      final ejercicio = idDe(p.deps, 'Ejercicio');
      p.deps.datosDemo!.habitos[ejercicio]!.maximaHistorica = 70;
      await montarApp(
        tester,
        plataforma: Plataforma.escritorio,
        tamano: escritorio,
        ubicacion: Rutas.habito(ejercicio),
        dependencias: p.deps,
      );
      expect(find.text('Ritmo ideal según la evidencia.'), findsNWidgets(2), reason: 'en el nivel y en la evidencia');
      expect(find.text('Dentro de lo recomendado'), findsOneWidget);
      expect(find.text('Hábito formado'), findsOneWidget);
    });

    testWidgets('Escalera apagada: lo dice en lugar del micro-paso', (tester) async {
      final p = preparar();
      await montarApp(
        tester,
        plataforma: Plataforma.escritorio,
        tamano: escritorio,
        ubicacion: Rutas.habito(idDe(p.deps, 'Estudiar inglés')),
        dependencias: p.deps,
      );
      expect(find.text('La Escalera está apagada en este hábito: la meta no cambia.'), findsOneWidget);
    });

    testWidgets('un hábito que no existe muestra el error', (tester) async {
      await montarApp(tester, ubicacion: Rutas.habito('no-existe'));
      expect(find.text('No encontrado.'), findsOneWidget);
    });
  });
}
