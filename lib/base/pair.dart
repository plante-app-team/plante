import 'package:flutter/foundation.dart';

@immutable
class Pair<F, S> {
  final F first;
  final S second;
  const Pair(this.first, this.second);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is Pair && first == other.first && second == other.second;
  }

  @override
  int get hashCode {
    return _combine(first.hashCode, second.hashCode);
  }

  // https://stackoverflow.com/a/26648915
  int _combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  @override
  String toString() {
    return [first.toString(), second.toString()].toString();
  }
}
