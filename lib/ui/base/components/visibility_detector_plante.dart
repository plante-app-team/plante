import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/ui/base/app_lifecycle_watcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

typedef OnVisibilityChanged = Function(bool visible, bool firstNotification);

/// Wrapper around [VisibilityDetector].
/// Observes VisibilityDetector, app's background-foreground state and
/// supports tests.
/// Also notifies about gone visibility when is disposed.
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/// !!! IMPORTANT WARNINGS BELOW !!!
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
///
/// !!!!!!!!!!!!!!!!!
/// !!! WARNING 1 !!!
/// !!!!!!!!!!!!!!!!!
/// PLEASE NOTE that unfortunately the events emitted by this widget (and by
/// [VisibilityDetector]) are PROBABILISTIC, and DO NOT GUARANTY that the
/// wrapped widget is actually hidden or shown.
///
/// For example, on Android when the soft keyboard is shown,
/// [VisibilityDetector] then fires a pair of 'hidden'-'shown' events if the
/// device is slow enough, even though the wrapped widget actually was
/// never hidden.
///
/// How to fix the problem is a baffling question.
/// As of 24th july of 2021 I was not able to find any good solutions to the
/// problem and left the things as they are.
///
/// https://trello.com/c/pQ4q3ets/
///
/// !!!!!!!!!!!!!!!!!
/// !!! WARNING 2 !!!
/// !!!!!!!!!!!!!!!!!
/// If the given [child] does not have any visibility by design (for example,
/// it's `SizedBox.shrink()`), then the detector will not report
/// visibility == true, ever.
///
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
  /// [VisibilityDetector] requires its key to be unique and its
  /// implementation contains a map which has the keys as.. keys.
  /// But we don't want to be constraint by this requirement, so that ids
  /// among [VisibilityDetectorPlante] can be reused.
  /// We achieve that by generating a unique ID piece for each widget.
  static var _latestUniqueIdPiece = 0;
  final _uniqueIdPiece = ++_latestUniqueIdPiece;

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
    _onVisibilityPieceChange(newFraction: 0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
        key: Key('${widget.keyStr}_wrapped_impl_$_uniqueIdPiece'),
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
