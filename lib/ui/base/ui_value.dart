import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/base/base.dart';

/// A wrapper around Riverpod's [StateProvider].
/// It's has 2 purposes:
/// 1. To be less verbose when the values is changed, obtained and watched.
/// 2. To allow the value to be accessed without
/// a [WidgetRef] (by the [cachedVal] property).
class UIValue<T> extends UIValueBase<T> {
  UIValue(T initialValue, WidgetRef ref) : super(initialValue, ref);

  /// Should never be called during **Widget.build** (including
  /// **didChangeDependencies**).
  /// [UIValue] is implemented by the Riverpod library, and it
  /// _hates_ it when values managed by it are set from while widgets are
  /// being built.
  void setValue(T val) {
    final valueChanged = _cachedValue != val;
    _cachedValue = val;
    _ref.read(_stateProvider.state).state = val;
    if (valueChanged) {
      for (final observer in _observers) {
        observer.call(val);
      }
    }
  }

  UIValueBase<T> unmodifiable() => this;
}

/// Immutable base of [UIValue].
class UIValueBase<T> {
  final WidgetRef _ref;
  final _observers = <ArgCallback<T>>[];
  final StateProvider<T> _stateProvider;
  T _cachedValue;

  UIValueBase(T initialValue, WidgetRef ref)
      : _ref = ref,
        _stateProvider = StateProvider<T>((ref) => initialValue),
        _cachedValue = initialValue;

  T get cachedVal => _cachedValue;

  T watch(WidgetRef ref) {
    // NOTE: we intentionally don't use [_ref] here, because
    // it would mean that entire _ref's widget would update
    // each time the value changes, but we want the caller to
    // decide what widget they want to get updated on changes.
    return ref.watch(_stateProvider.state).state;
  }

  void callOnChanges(ArgCallback<T> callback) {
    _observers.add(callback);
  }

  void unregisterCallback(ArgCallback<T> callback) {
    _observers.remove(callback);
  }
}
