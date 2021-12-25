import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies about loading start after a delay. Doesn't notify at all if
/// loading has ended before the delay.
class DelayedLoadingNotifier {
  final bool firstLoadingInstantNotification;
  final VoidCallback callback;
  final Duration delay;

  var _totalLoadingsCount = 0;
  var _loadingsCount = 0;
  final _timers = <Timer>[];

  bool get isLoading => _loadingsCount > 0;

  DelayedLoadingNotifier(
      {required this.firstLoadingInstantNotification,
      required this.callback,
      required this.delay});

  void onLoadingStart() {
    _totalLoadingsCount += 1;
    final Duration delay;
    if (_totalLoadingsCount == 1 && firstLoadingInstantNotification) {
      delay = Duration.zero;
    } else {
      delay = this.delay;
    }
    late Timer timer;
    timer = Timer(delay, () {
      _onTimer(timer);
    });
    _timers.add(timer);
  }

  void _onTimer(Timer timer) {
    _loadingsCount += 1;
    if (_loadingsCount == 1) {
      callback.call();
    }
  }

  void onLoadingEnd() {
    Timer? timer;
    if (_timers.isNotEmpty) {
      timer = _timers.removeAt(0);
    }
    if (timer != null) {
      if (!timer.isActive) {
        if (_loadingsCount > 0) {
          _loadingsCount -= 1;
          callback.call();
        }
      }
      timer.cancel();
    }
  }
}
