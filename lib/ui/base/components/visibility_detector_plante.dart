import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/app_lifecycle_watcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

typedef OnVisibilityChanged = Function(bool visible, bool firstNotification);

/// Wrapper around [VisibilityDetector].
/// Observes VisibilityDetector, app's background-foreground state and
/// supports tests.
class VisibilityDetectorPlante extends StatefulWidget {
  final String keyStr;
  final Widget child;
  final OnVisibilityChanged onVisibilityChanged;
  final AppLifecycleWatcher appLifecycleWatcher;

  VisibilityDetectorPlante(
      {required this.keyStr,
      required this.child,
      required this.onVisibilityChanged,
      this.appLifecycleWatcher = const AppLifecycleWatcher()})
      : super(key: Key(keyStr));

  @override
  _VisibilityDetectorPlanteState createState() =>
      _VisibilityDetectorPlanteState();
}

class _VisibilityDetectorPlanteState extends State<VisibilityDetectorPlante>
    implements AppLifecycleObserver {
  var _latestVisibleFraction = 0.0;
  var _latestAppState = AppLifecycleState.resumed;
  bool get _overallVisibility {
    final visibleByState = [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive
    ].contains(_latestAppState);
    final visibleByFraction = _latestVisibleFraction > 0.0001;
    return visibleByState && visibleByFraction;
  }

  var _notificationsCount = 0;

  @override
  void initState() {
    super.initState();
    if (isInTests()) {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
    } else {
      VisibilityDetectorController.instance.updateInterval =
          const Duration(seconds: 1);
    }
    widget.appLifecycleWatcher.addObserver(this);
  }

  @override
  void dispose() {
    widget.appLifecycleWatcher.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
        key: Key('${widget.keyStr}_wrapped_impl'),
        onVisibilityChanged: (info) {
          _onVisibilityPieceChange(newFraction: info.visibleFraction);
        },
        child: widget.child);
  }

  @override
  void onAppStateChange(AppLifecycleState state) {
    _onVisibilityPieceChange(newState: state);
  }

  void _onVisibilityPieceChange(
      {double? newFraction, AppLifecycleState? newState}) {
    final initialFraction = _latestVisibleFraction;
    final initialState = _latestAppState;
    final initialOverallVisibility = _overallVisibility;

    _latestVisibleFraction = newFraction ?? initialFraction;
    _latestAppState = newState ?? initialState;
    if (_overallVisibility != initialOverallVisibility) {
      widget.onVisibilityChanged
          .call(_overallVisibility, _notificationsCount == 0);
      _notificationsCount += 1;
    }
  }
}
