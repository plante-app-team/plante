import 'package:flutter/widgets.dart';
import 'package:plante/ui/base/app_lifecycle_watcher.dart';

class FakeAppLifecycleWatcher implements AppLifecycleWatcher {
  final _observers = <AppLifecycleObserver>[];

  @override
  void addObserver(AppLifecycleObserver observer) {
    _observers.add(observer);
  }

  @override
  void removeObserver(AppLifecycleObserver observer) {
    _observers.remove(observer);
  }

  void changeAppStateTo(AppLifecycleState state) {
    _observers.forEach((observer) {
      observer.onAppStateChange(state);
    });
  }
}
