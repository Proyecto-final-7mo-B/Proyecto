import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/validadores.dart';
import '../../core/mensajes.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/aviso_kaizen.dart';
import '../../core/widgets/campo_validado.dart';
import '../../core/widgets/mensaje_error.dart';
import '../view_models/recuperar_viewmodel.dart';

/// "¿Olvidaste tu contraseña?": pide el correo y responde **siempre lo mismo**, exista o no la cuenta.
class DialogoRecuperar extends StatefulWidget {
  const DialogoRecuperar({required this.viewModel, this.correoInicial = '', super.key});

  final RecuperarViewModel viewModel;
  final String correoInicial;

  static Future<void> mostrar(BuildContext context, {String correo = ''}) async {
    final vm = RecuperarViewModel(context.read<AuthRepository>());
    await showDialog<void>(
      context: context,
      builder: (_) => DialogoRecuperar(viewModel: vm, correoInicial: correo),
    );
    vm.dispose();
  }

  @override
  State<DialogoRecuperar> createState() => _DialogoRecuperarState();
}

class _DialogoRecuperarState extends State<DialogoRecuperar> {
  final _formulario = GlobalKey<FormState>();
  late final _correo = TextEditingController(text: widget.correoInicial);

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_formulario.currentState!.validate()) {
      await widget.viewModel.enviar.ejecutar(_correo.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final comando = widget.viewModel.enviar;
    return ListenableBuilder(
      listenable: comando,
      builder: (context, _) => AlertDialog(
        title: Text(t.recuperarTitulo),
        content: SizedBox(
          width: 420,
          child: comando.completado
              ? AvisoKaizen(texto: t.recuperarEnviado, icono: Icons.mark_email_read_outlined)
              : Form(
                  key: _formulario,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(t.recuperarTexto),
                      const SizedBox(height: KaizenMedidas.e16),
                      CampoValidado(
                        etiqueta: t.campoCorreo,
                        controller: _correo,
                        pista: t.pistaCorreo,
                        tipoTeclado: TextInputType.emailAddress,
                        validador: validadorDe(Validadores.correo, t),
                        onEnviar: (_) => _enviar(),
                      ),
                      if (comando.error case final error?) ...[
                        const SizedBox(height: KaizenMedidas.e12),
                        MensajeError(mensajeDeError(error, t)),
                      ],
                    ],
                  ),
                ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
            child: Text(comando.completado ? t.cerrar : t.cancelar),
          ),
          if (!comando.completado)
            FilledButton(
              onPressed: comando.ejecutando ? null : _enviar,
              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
              child: Text(t.enviarEnlace),
            ),
        ],
      ),
    );
  }
}
