import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A wrapper around Riverpod's [StateProvider].
/// It's has 2 purposes:
/// 1. To be less verbose when the values is changed, obtained and watched.
/// 2. To allow the value to be accessed without
/// a [WidgetRef] (by the [cachedVal] property).
class UIValueWrapper<T> {
  final StateProvider<T> _stateProvider;
  T _cachedValue;

  UIValueWrapper(T initialValue)
      : _stateProvider = StateProvider<T>((ref) => initialValue),
        _cachedValue = initialValue;

  T get cachedVal => _cachedValue;

  void setValue(T val, WidgetRef ref) {
    _cachedValue = val;
    ref.read(_stateProvider.state).state = val;
  }

  T watch(WidgetRef ref) {
    return ref.watch(_stateProvider.state).state;
  }
}
