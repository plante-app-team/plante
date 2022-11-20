import 'package:flutter/material.dart';

abstract class AppLifecycleObserver {
  void onAppStateChange(AppLifecycleState state);
}

class AppLifecycleWatcher {
  static late _AppLifecycleWatcherImpl _impl;
  static var _inited = false;

  const AppLifecycleWatcher();

  void addObserver(AppLifecycleObserver observer) {
    if (!_inited) {
      // Delayed initialization because WidgetsBinding.instance
      // is not immediately initialized on app startup.
      _impl = _AppLifecycleWatcherImpl();
      _inited = true;
    }
    _impl.addObserver(observer);
  }

  void removeObserver(AppLifecycleObserver observer) {
    _impl.removeObserver(observer);
  }
}

class _AppLifecycleWatcherImpl with WidgetsBindingObserver {
  final _observers = <AppLifecycleObserver>[];

  _AppLifecycleWatcherImpl() {
    WidgetsBinding.instance.addObserver(this);
  }

  void addObserver(AppLifecycleObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(AppLifecycleObserver observer) {
    _observers.remove(observer);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    for (final observer in _observers) {
      observer.onAppStateChange(state);
    }
  }
}
