import 'package:flutter/foundation.dart';

@immutable
class SizeInt {
  final int width;
  final int height;

  const SizeInt({required this.width, required this.height});

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is SizeInt && width == other.width && height == other.height;
  }

  @override
  int get hashCode {
    return Object.hash(width, height);
  }

  @override
  String toString() {
    return [width, height].toString();
  }
}
