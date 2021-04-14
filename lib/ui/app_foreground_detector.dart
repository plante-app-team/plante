import 'package:flutter/widgets.dart';

class AppForegroundDetector extends WidgetsBindingObserver {
  final Function() foregroundCallback;

  AppForegroundDetector(this.foregroundCallback);

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await foregroundCallback.call();
    }
  }
}
