import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/services/api/errores_api.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../../utils/validadores.dart';
import '../../core/mensajes.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/aviso_kaizen.dart';
import '../../core/widgets/campo_validado.dart';
import '../../core/widgets/logo_kaizen.dart';
import '../../core/widgets/mensaje_error.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../view_models/restablecer_viewmodel.dart';
import 'dialogo_recuperar.dart';

/// `/restablecer?token=…`: el enlace del correo (vigente 15 min, de un solo uso). Nunca muestra el token.
class PantallaRestablecer extends StatefulWidget {
  const PantallaRestablecer({required this.token, super.key});

  final String? token;

  @override
  State<PantallaRestablecer> createState() => _PantallaRestablecerState();
}

class _PantallaRestablecerState extends State<PantallaRestablecer> {
  late final RestablecerViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = RestablecerViewModel(context.read<AuthRepository>(), widget.token);
  }

  final _formulario = GlobalKey<FormState>();
  final _nueva = TextEditingController();
  final _confirmacion = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _nueva.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    _vm.guardar.limpiar();
    if (_formulario.currentState!.validate()) {
      await _vm.guardar.ejecutar(_nueva.text);
    }
  }

  Widget _enlaceInvalido(AppLocalizations t) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MensajeError(t.errorEnlaceInvalido),
      const SizedBox(height: KaizenMedidas.e16),
      FilledButton(onPressed: () => DialogoRecuperar.mostrar(context), child: Text(t.pedirOtroEnlace)),
      const SizedBox(height: KaizenMedidas.e8),
      OutlinedButton(onPressed: () => context.go(Rutas.login), child: Text(t.irAEntrar)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KaizenMedidas.e24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: LogoKaizen(lado: 56)),
                  const SizedBox(height: KaizenMedidas.e24),
                  TarjetaKaizen(
                    relleno: const EdgeInsets.all(KaizenMedidas.e24),
                    child: ListenableBuilder(
                      listenable: _vm.guardar,
                      builder: (context, _) {
                        final comando = _vm.guardar;
                        final error = comando.error;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(header: true, child: Text(t.tituloRestablecer, style: texto.headlineSmall)),
                            const SizedBox(height: KaizenMedidas.e12),
                            if (!_vm.tieneToken || error?.tipo == TipoError.enlaceInvalido)
                              _enlaceInvalido(t)
                            else if (comando.completado) ...[
                              AvisoKaizen(texto: t.contrasenaRestablecida, icono: Icons.check_circle_outline),
                              const SizedBox(height: KaizenMedidas.e16),
                              FilledButton(onPressed: () => context.go(Rutas.login), child: Text(t.irAEntrar)),
                            ] else
                              Form(
                                key: _formulario,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(t.restablecerTexto, style: texto.bodyMedium),
                                    const SizedBox(height: KaizenMedidas.e16),
                                    CampoValidado(
                                      etiqueta: t.nuevaContrasena,
                                      controller: _nueva,
                                      contrasena: true,
                                      ayuda: t.ayudaContrasena,
                                      autocompletar: const [AutofillHints.newPassword],
                                      validador: validadorDe(Validadores.contrasena, t),
                                      errorServidor: error?.errorDe('nueva'),
                                    ),
                                    const SizedBox(height: KaizenMedidas.e16),
                                    CampoValidado(
                                      etiqueta: t.confirmarContrasena,
                                      controller: _confirmacion,
                                      contrasena: true,
                                      validador: validadorDe((v) => Validadores.confirmacion(v, _nueva.text), t),
                                      onEnviar: (_) => _guardar(),
                                    ),
                                    const SizedBox(height: KaizenMedidas.e20),
                                    FilledButton(
                                      onPressed: comando.ejecutando ? null : _guardar,
                                      child: Text(t.guardarContrasena),
                                    ),
                                    if (error != null && error.tipo != TipoError.validacion) ...[
                                      const SizedBox(height: KaizenMedidas.e12),
                                      MensajeError(mensajeDeError(error, t)),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
