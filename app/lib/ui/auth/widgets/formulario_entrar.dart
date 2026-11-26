import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/fake/datos_demo.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/validadores.dart';
import '../../core/mensajes.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/campo_validado.dart';
import '../../core/widgets/mensaje_error.dart';
import '../view_models/entrar_viewmodel.dart';
import 'dialogo_recuperar.dart';

/// Pestaña "Entrar" (bosquejo 01): correo, contraseña, "¿Olvidaste tu contraseña?" e "Iniciar sesión".
class FormularioEntrar extends StatefulWidget {
  const FormularioEntrar({required this.viewModel, this.cuentasDePrueba = false, super.key});

  final EntrarViewModel viewModel;

  /// Solo en desarrollo con `KAIZEN_FUENTE=fake`: botones que llenan una cuenta del poblador.
  final bool cuentasDePrueba;

  @override
  State<FormularioEntrar> createState() => _FormularioEntrarState();
}

class _FormularioEntrarState extends State<FormularioEntrar> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final comando = widget.viewModel.entrar..limpiar();
    if (!_formulario.currentState!.validate()) {
      return;
    }
    await comando.ejecutar((email: _correo.text, contrasena: _contrasena.text));
    if (comando.completado) {
      TextInput.finishAutofillContext();
    }
  }

  void _llenar(String correo) {
    _correo.text = correo;
    _contrasena.text = DatosDemo.contrasenaDemo;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final comando = widget.viewModel.entrar;
    return AutofillGroup(
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoValidado(
              etiqueta: t.campoCorreo,
              controller: _correo,
              pista: t.pistaCorreo,
              tipoTeclado: TextInputType.emailAddress,
              accionTeclado: TextInputAction.next,
              autocompletar: const [AutofillHints.email, AutofillHints.username],
              validador: validadorDe(Validadores.correo, t),
            ),
            const SizedBox(height: KaizenMedidas.e16),
            CampoValidado(
              etiqueta: t.campoContrasena,
              controller: _contrasena,
              contrasena: true,
              accionTeclado: TextInputAction.done,
              autocompletar: const [AutofillHints.password],
              validador: validadorDe(Validadores.contrasenaParaEntrar, t),
              onEnviar: (_) => _enviar(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => DialogoRecuperar.mostrar(context, correo: _correo.text),
                child: Text(t.olvidasteContrasena),
              ),
            ),
            const SizedBox(height: KaizenMedidas.e4),
            ListenableBuilder(
              listenable: comando,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: comando.ejecutando ? null : _enviar,
                    child: comando.ejecutando
                        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Text(t.iniciarSesion),
                  ),
                  if (comando.error case final error?) ...[
                    const SizedBox(height: KaizenMedidas.e12),
                    MensajeError(mensajeDeError(error, t)),
                  ],
                ],
              ),
            ),
            if (widget.cuentasDePrueba) ...[
              const SizedBox(height: KaizenMedidas.e20),
              Text(t.cuentasDePrueba, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: KaizenMedidas.e8),
              Wrap(
                spacing: KaizenMedidas.e8,
                runSpacing: KaizenMedidas.e8,
                children: [
                  for (final (nombre, correo) in const [
                    ('Daniela', 'demo@kaizen.test'),
                    ('Admin', 'admin@kaizen.test'),
                    ('Lucía (LATAM)', 'latam@kaizen.test'),
                    ('Nico (nuevo)', 'nuevo@kaizen.test'),
                    ('Suspendido', 'suspendido@kaizen.test'),
                  ])
                    ActionChip(label: Text(nombre), onPressed: () => _llenar(correo)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
