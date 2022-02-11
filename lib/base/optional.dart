import 'package:flutter/foundation.dart';

@immutable
abstract class Optional<T> {
  T get value;
  bool get isPresent;

  factory Optional.of(T value) {
    return _Present<T>(value);
  }

  factory Optional.empty() {
    return const _Absent();
  }

  @override
  int get hashCode;

  @override
  bool operator ==(Object other);

  @override
  String toString();
}

@immutable
class _Present<T> implements Optional<T> {
  final T _value;

  const _Present(this._value);

  @override
  bool get isPresent => true;

  @override
  T get value => _value;

  @override
  int get hashCode => _value.hashCode;

  @override
  bool operator ==(Object other) => other is Optional && value == other.value;

  @override
  String toString() => value.toString();
}

@immutable
class _Absent<T> implements Optional<T> {
  const _Absent();

  @override
  bool get isPresent => false;

  @override
  T get value => throw StateError('[value] called on absent Optional');

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) => other is _Absent<T>;

  @override
  String toString() => '[Absent Optional]';
}

extension OptionalExt<T> on Optional<T> {
  bool get isNotPresent => !isPresent;
}
