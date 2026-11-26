import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';

/// Campo de texto con la etiqueta en negritas arriba (como "Nombre" en el bosquejo de Crear hábito), texto de ayuda
/// en azul y error en rojo. Con [contrasena], oculta el texto y agrega el botón de mostrar/ocultar.
class CampoValidado extends StatefulWidget {
  const CampoValidado({
    required this.etiqueta,
    this.controller,
    this.validador,
    this.ayuda,
    this.pista,
    this.contrasena = false,
    this.tipoTeclado,
    this.accionTeclado,
    this.autocompletar,
    this.formatos,
    this.maxLineas = 1,
    this.habilitado = true,
    this.onCambio,
    this.onEnviar,
    this.sufijo,
    this.errorServidor,
    this.focusNode,
    super.key,
  });

  final String etiqueta;
  final TextEditingController? controller;

  /// Devuelve el mensaje de error o `null` si el valor es válido (se conectan los validadores del Paso 4).
  final FormFieldValidator<String>? validador;
  final String? ayuda;
  final String? pista;
  final bool contrasena;
  final TextInputType? tipoTeclado;
  final TextInputAction? accionTeclado;
  final Iterable<String>? autocompletar;
  final List<TextInputFormatter>? formatos;
  final int maxLineas;
  final bool habilitado;
  final ValueChanged<String>? onCambio;
  final ValueChanged<String>? onEnviar;

  /// Ícono al final (p. ej., el reloj del recordatorio). Se ignora si es contraseña.
  final Widget? sufijo;

  /// Error que mandó el servidor para este campo (422 con `errores[]`). Se muestra aunque el valor pase la
  /// validación local.
  final String? errorServidor;
  final FocusNode? focusNode;

  @override
  State<CampoValidado> createState() => _CampoValidadoState();
}

class _CampoValidadoState extends State<CampoValidado> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ocultar = widget.contrasena && _oculto;
    final Widget? sufijo = widget.contrasena
        ? IconButton(
            tooltip: _oculto ? t.mostrarContrasena : t.ocultarContrasena,
            icon: Icon(_oculto ? KaizenIconos.verContrasena : KaizenIconos.ocultarContrasena),
            onPressed: () => setState(() => _oculto = !_oculto),
          )
        : widget.sufijo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // La etiqueta visible va arriba; los lectores de pantalla la leen junto con el campo.
        ExcludeSemantics(child: Text(widget.etiqueta, style: Theme.of(context).textTheme.titleSmall)),
        const SizedBox(height: KaizenMedidas.e8),
        Semantics(
          label: widget.etiqueta,
          textField: true,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            forceErrorText: widget.errorServidor,
            validator: widget.validador,
            obscureText: ocultar,
            enableSuggestions: !widget.contrasena,
            autocorrect: !widget.contrasena,
            keyboardType: widget.contrasena ? TextInputType.visiblePassword : widget.tipoTeclado,
            textInputAction: widget.accionTeclado,
            autofillHints: widget.autocompletar,
            inputFormatters: widget.formatos,
            maxLines: widget.contrasena ? 1 : widget.maxLineas,
            enabled: widget.habilitado,
            onChanged: widget.onCambio,
            onFieldSubmitted: widget.onEnviar,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(hintText: widget.pista, helperText: widget.ayuda, suffixIcon: sufijo),
          ),
        ),
      ],
    );
  }
}
