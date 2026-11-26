import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/services/api/errores_api.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/validadores.dart';
import '../../core/mensajes.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/campo_validado.dart';
import '../../core/widgets/mensaje_error.dart';
import '../view_models/registro_viewmodel.dart';

/// Pestaña "Crear cuenta": nombre, correo, contraseña, país y (solo en México) estado, aviso de privacidad
/// obligatorio y consentimiento de señales opcional. Al crearla, la sesión queda abierta.
class FormularioRegistro extends StatefulWidget {
  const FormularioRegistro({required this.viewModel, super.key});

  final RegistroViewModel viewModel;

  @override
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<FormularioRegistro> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();

  RegistroViewModel get _vm => widget.viewModel;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    _vm.registrar.limpiar();
    final valido = _formulario.currentState!.validate();
    final solicitud = _vm.solicitud(nombre: _nombre.text, email: _correo.text, contrasena: _contrasena.text);
    if (!valido || solicitud == null) {
      return;
    }
    await _vm.registrar.ejecutar(solicitud);
    if (_vm.registrar.completado) {
      TextInput.finishAutofillContext();
    }
  }

  /// Error del servidor para un campo (422 con `errores[]`).
  String? _errorDe(String campo) {
    final error = _vm.registrar.error;
    return error?.tipo == TipoError.validacion ? error!.errorDe(campo) : null;
  }

  Future<void> _verAviso() => showDialog<void>(
    context: context,
    builder: (context) {
      final t = AppLocalizations.of(context);
      return AlertDialog(
        title: Text(t.avisoPrivacidadTitulo),
        content: SizedBox(width: 480, child: Text(t.avisoPrivacidadTexto)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cerrar))],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.registrar]),
      builder: (context, _) => AutofillGroup(
        child: Form(
          key: _formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoValidado(
                etiqueta: t.campoNombre,
                controller: _nombre,
                pista: t.pistaNombre,
                accionTeclado: TextInputAction.next,
                autocompletar: const [AutofillHints.name],
                validador: validadorDe(Validadores.nombreUsuario, t),
                errorServidor: _errorDe('nombre'),
              ),
              const SizedBox(height: KaizenMedidas.e16),
              CampoValidado(
                etiqueta: t.campoCorreo,
                controller: _correo,
                pista: t.pistaCorreo,
                tipoTeclado: TextInputType.emailAddress,
                accionTeclado: TextInputAction.next,
                autocompletar: const [AutofillHints.email],
                validador: validadorDe(Validadores.correo, t),
                errorServidor: _errorDe('email'),
              ),
              const SizedBox(height: KaizenMedidas.e16),
              CampoValidado(
                etiqueta: t.campoContrasena,
                controller: _contrasena,
                contrasena: true,
                ayuda: t.ayudaContrasena,
                autocompletar: const [AutofillHints.newPassword],
                validador: validadorDe((v) => Validadores.contrasena(v, correo: _correo.text), t),
                errorServidor: _errorDe('contrasena'),
              ),
              const SizedBox(height: KaizenMedidas.e16),
              _Selector(
                etiqueta: t.campoPais,
                pista: t.elegirPais,
                valor: _vm.pais,
                opciones: [for (final p in _vm.paises) (p.codigo, p.nombre)],
                onCambio: _vm.elegirPais,
                validador: (v) => v == null ? t.validacionRequerido : null,
              ),
              if (_vm.pideEstado) ...[
                const SizedBox(height: KaizenMedidas.e16),
                _Selector(
                  etiqueta: t.campoEstado,
                  pista: t.elegirEstado,
                  valor: _vm.estado,
                  opciones: [for (final e in _vm.estados) (e.codigo, e.nombre)],
                  onCambio: _vm.elegirEstado,
                  validador: (v) => v == null ? t.validacionRequerido : null,
                ),
              ],
              const SizedBox(height: KaizenMedidas.e12),
              CheckboxListTile(
                value: _vm.aceptaAviso,
                onChanged: (v) => _vm.cambiarAviso(acepta: v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(t.aceptoAviso, style: texto.titleSmall),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _verAviso,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                    child: Text(t.verAviso),
                  ),
                ),
              ),
              if (_vm.faltaAviso) MensajeError(t.debesAceptarAviso),
              CheckboxListTile(
                value: _vm.consienteSenales,
                onChanged: (v) => _vm.cambiarConsentimiento(consiente: v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(t.consientoSenales, style: texto.bodyMedium),
                subtitle: Text(t.consientoSenalesDetalle),
              ),
              const SizedBox(height: KaizenMedidas.e12),
              FilledButton(
                onPressed: _vm.registrar.ejecutando ? null : _enviar,
                child: _vm.registrar.ejecutando
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(t.pestanaCrearCuenta),
              ),
              if (_vm.registrar.error case final error?) ...[
                const SizedBox(height: KaizenMedidas.e12),
                MensajeError(mensajeDeError(error, t)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista desplegable con la etiqueta arriba, como `CampoValidado`.
class _Selector extends StatelessWidget {
  const _Selector({
    required this.etiqueta,
    required this.pista,
    required this.valor,
    required this.opciones,
    required this.onCambio,
    required this.validador,
  });

  final String etiqueta;
  final String pista;
  final String? valor;
  final List<(String, String)> opciones;
  final ValueChanged<String?> onCambio;
  final FormFieldValidator<String> validador;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(etiqueta, style: Theme.of(context).textTheme.titleSmall)),
        const SizedBox(height: KaizenMedidas.e8),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          hint: Text(pista),
          items: [for (final (codigo, nombre) in opciones) DropdownMenuItem(value: codigo, child: Text(nombre))],
          onChanged: onCambio,
          validator: validador,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(semanticCounterText: etiqueta),
        ),
      ],
    );
  }
}
