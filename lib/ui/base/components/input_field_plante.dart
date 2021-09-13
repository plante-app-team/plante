import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class InputFieldPlante extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool? showCursor;
  final bool readOnly;

  /// [focusNode] and [focusChangeCallback] are mutually exclusive.
  final FocusNode? focusNode;

  /// [focusNode] and [focusChangeCallback] are mutually exclusive.
  final ArgCallback<bool>? focusChangeCallback;

  const InputFieldPlante(
      {Key? key,
      this.label,
      this.hint,
      this.textCapitalization = TextCapitalization.sentences,
      this.controller,
      this.keyboardType,
      this.inputFormatters,
      this.showCursor,
      this.readOnly = false,
      this.focusNode,
      this.focusChangeCallback})
      : super(key: key);

  @override
  _InputFieldPlanteState createState() => _InputFieldPlanteState();
}

class _InputFieldPlanteState extends State<InputFieldPlante> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null && widget.focusChangeCallback != null) {
      throw ArgumentError('[focusNode] and [focusChangeCallback] are '
          'mutually exclusive');
    }
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
    }
    _focusNode.addListener(() {
      widget.focusChangeCallback?.call(_focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 46,
        child: TextField(
          key: widget.key,
          textCapitalization: widget.textCapitalization,
          style: TextStyles.input,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyles.inputLabel,
            hintText: widget.hint,
            contentPadding: const EdgeInsets.only(left: 22, right: 22),
            hintStyle: TextStyles.inputHint,
            enabledBorder: const OutlineInputBorder(
              gapPadding: 2,
              borderSide: BorderSide(color: Color.fromARGB(255, 28, 32, 44)),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: const OutlineInputBorder(
              gapPadding: 2,
              borderSide: BorderSide(color: ColorsPlante.primary, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          controller: widget.controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          showCursor: widget.showCursor,
        ));
  }
}
