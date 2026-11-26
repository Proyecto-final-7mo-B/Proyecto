import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/services/servicio_sesion.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../../utils/paises_estados.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/selector_segmentado.dart';
import '../view_models/entrar_viewmodel.dart';
import '../view_models/registro_viewmodel.dart';
import 'formulario_entrar.dart';
import 'formulario_registro.dart';
import 'panel_marca.dart';

enum PestanaEntrada { entrar, crearCuenta }

/// `/login` (bosquejo 01). En pantallas amplias: panel de marca a la izquierda y formulario a la derecha. En el
/// teléfono: encabezado de marca y el formulario en una hoja blanca debajo.
class PantallaEntrar extends StatefulWidget {
  const PantallaEntrar({
    this.pestanaInicial = PestanaEntrada.entrar,
    this.cuentasDePrueba = false,
    this.herramientasDev = false,
    super.key,
  });

  final PestanaEntrada pestanaInicial;

  /// Atajos con las cuentas del poblador (solo en desarrollo con `KAIZEN_FUENTE=fake`).
  final bool cuentasDePrueba;

  /// Enlace a la galería de componentes (solo en depuración).
  final bool herramientasDev;

  /// Ancho desde el que se usan los dos paneles.
  static const double anchoDosPaneles = 900;

  @override
  State<PantallaEntrar> createState() => _PantallaEntrarState();
}

class _PantallaEntrarState extends State<PantallaEntrar> {
  late PestanaEntrada _pestana = widget.pestanaInicial;
  late final EntrarViewModel _entrar;
  late final RegistroViewModel _registro;

  @override
  void initState() {
    super.initState();
    final servicio = context.read<ServicioSesion>();
    _entrar = EntrarViewModel(servicio);
    _registro = RegistroViewModel(servicio, context.read<CatalogoRegiones?>());
  }

  @override
  void dispose() {
    _entrar.dispose();
    _registro.dispose();
    super.dispose();
  }

  Widget _contenido(BuildContext context, {required bool conTitulo}) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (conTitulo) ...[
          Semantics(header: true, child: Text(t.bienvenida, style: texto.headlineLarge)),
          const SizedBox(height: KaizenMedidas.e20),
        ],
        SelectorSegmentado<PestanaEntrada>(
          opciones: [
            (valor: PestanaEntrada.entrar, etiqueta: t.pestanaEntrar),
            (valor: PestanaEntrada.crearCuenta, etiqueta: t.pestanaCrearCuenta),
          ],
          seleccionado: _pestana,
          onCambio: (p) => setState(() => _pestana = p),
        ),
        const SizedBox(height: KaizenMedidas.e20),
        if (_pestana == PestanaEntrada.entrar)
          FormularioEntrar(viewModel: _entrar, cuentasDePrueba: widget.cuentasDePrueba)
        else
          FormularioRegistro(viewModel: _registro),
        // La región la asigna la base a partir del país y el estado; al usuario no se le muestra.
        if (widget.herramientasDev) ...[
          const SizedBox(height: KaizenMedidas.e8),
          TextButton(onPressed: () => context.push(Rutas.componentes), child: Text(t.verComponentes)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho >= PantallaEntrar.anchoDosPaneles) {
      return Scaffold(
        backgroundColor: KaizenColores.superficie,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(child: PanelMarca()),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(KaizenMedidas.e32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _contenido(context, conTitulo: true),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      // Blanco: la hoja del formulario continúa hasta abajo; el encabezado de marca pone su propio azul.
      backgroundColor: KaizenColores.superficie,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PanelMarca(compacto: true),
            Transform.translate(
              offset: const Offset(0, -28),
              // Material (no Container con color) para que las casillas y botones muestren su efecto al tocarlos.
              child: Material(
                color: KaizenColores.superficie,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: Container(
                  constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.6),
                  padding: const EdgeInsets.fromLTRB(
                    KaizenMedidas.e20,
                    KaizenMedidas.e24,
                    KaizenMedidas.e20,
                    KaizenMedidas.e32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: _contenido(context, conTitulo: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
