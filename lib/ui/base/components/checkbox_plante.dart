import 'package:flutter/material.dart';

class CheckboxPlante extends StatelessWidget {
  /// See [Checkbox.value]
  final bool? value;

  /// See [Checkbox.onChanged]
  final ValueChanged<bool?>? onChanged;

  const CheckboxPlante({Key? key, required this.value, required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
        scale: 1.334, child: Checkbox(value: value, onChanged: onChanged));
  }
}
