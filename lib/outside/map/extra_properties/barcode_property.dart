import 'package:flutter/foundation.dart';
import 'package:plante/base/pair.dart';

@immutable
class BarcodeProperty<T> {
  final Pair<String, T> _impl;
  String get barcode => _impl.first;
  T get val => _impl.second;

  factory BarcodeProperty(String barcode, T val) =>
      BarcodeProperty._(Pair(barcode, val));
  const BarcodeProperty._(Pair<String, T> pair) : _impl = pair;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is BarcodeProperty && _impl == other._impl;
  }

  @override
  int get hashCode => _impl.hashCode;

  @override
  String toString() => _impl.toString();
}
