import 'package:flutter/material.dart';

/// Same as [Radio] but with a scale.
class RadioPlante<T> extends StatelessWidget {
  /// See [Radio.value].
  final T value;

  /// See [Radio.groupValue].
  final T? groupValue;

  /// See [Radio.onChanged].
  final ValueChanged<T?>? onChanged;

  const RadioPlante(
      {Key? key,
      required this.value,
      required this.groupValue,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
        scale: 1.334,
        child: Radio<T>(
            // fillColor: MaterialStateProperty.all(const Color(0xFF979A9C)),
            value: value,
            groupValue: groupValue,
            onChanged: onChanged));
  }
}
