import 'dart:async';
import 'package:plante/base/base.dart';

/// Waits for [delay] before calling the underlying [wrapped] callback.
/// If the [call] function is called before [delay] again, then a timer inside
/// starts from 0 and [delay] is being waited again.
/// After the [delay] the [wrapped] callback is called only
/// 1 time, with latest provided arg.
class DelayedLossyArgCallback<T> {
  final Duration delay;
  final ArgCallback<T> wrapped;
  final bool enabledInTests;

  Timer? _timer;
  T? _arg;

  DelayedLossyArgCallback(this.delay, this.wrapped,
      {this.enabledInTests = false});

  void call(T arg) {
    if (isInTests() && !enabledInTests) {
      // Tests hate timers
      wrapped.call(arg);
      return;
    }
    _arg = arg;
    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      wrapped.call(_arg as T);
    });
  }
}
