import '../../../domain/models/laboratorio.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'laboratorio_repository.dart';

class LaboratorioRepositoryFake implements LaboratorioRepository {
  LaboratorioRepositoryFake(this._datos);

  final DatosDemo _datos;

  @override
  Future<Result<Perspectivas>> perspectivas({String? semana}) => _datos.ejecutar(() {
    final u = _datos.usuarioDeSesion();
    if (!_datos.analiticaDisponible) {
      throw DatosDemo.error(TipoError.analiticaNoDisponible, 503, 'La analítica no está disponible');
    }
    final laSemana = semana ?? Fechas.semanaIso(_datos.hoy.subtract(const Duration(days: 7)));
    final senales = _datos.senales[u.id]?.length ?? 0;
    if (senales < 14) {
      return Perspectivas(semana: laSemana, datosSuficientes: false, perspectivas: const []);
    }
    HabitoReferido? habito(String nombre) {
      final h = _datos.habitosDe(u.id).where((h) => h.nombre == nombre).firstOrNull;
      return h == null ? null : HabitoReferido(id: h.id, nombre: h.nombre);
    }

    final ejercicio = habito('Ejercicio');
    final ingles = habito('Estudiar inglés');
    return Perspectivas(
      semana: laSemana,
      datosSuficientes: true,
      generadoEn: _datos.hoy.add(const Duration(hours: 9)),
      perspectivas: [
        Perspectiva(
          tipo: TipoPerspectiva.asociacion,
          categoria: 'Ejercicio',
          variable: 'energia',
          delta: 0.8,
          diasCon: 9,
          diasSin: 8,
          habitos: [?ejercicio],
          texto: 'Los días que cumples tus hábitos de Ejercicio, tu energía promedio es 0.8 puntos mayor',
        ),
        const Perspectiva(
          tipo: TipoPerspectiva.franjaHoraria,
          categoria: 'Lectura',
          franja: 'noche',
          texto: 'Cumples más tus hábitos de Lectura cuando los registras en la noche',
        ),
        Perspectiva(
          tipo: TipoPerspectiva.riesgoAbandono,
          categoria: 'Aprendizaje',
          cumplimiento7d: 40,
          pendiente14d: -2.5,
          habitos: [?ingles],
          texto: 'Tu constancia en Aprendizaje bajó esta semana: un paso más pequeño puede ayudar',
        ),
      ],
    );
  });
}
