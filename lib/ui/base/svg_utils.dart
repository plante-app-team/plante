import 'package:flutter/material.dart';

extension ColorExt on Color? {
  ColorFilter toColorFilter() =>
      ColorFilter.mode(this ?? Colors.transparent, BlendMode.srcIn);
}
