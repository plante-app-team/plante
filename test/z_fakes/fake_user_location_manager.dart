import 'package:plante/base/base.dart';
import 'package:plante/location/user_location_manager.dart';
import 'package:plante/model/coord.dart';

class FakeUserLocationManager implements UserLocationManager {
  Coord? _lastKnownPosition;
  Coord? _currentPosition;
  final _lastPositionCallbacks = <ArgCallback<Coord>>[];

  void setCurrentPosition(Coord? pos) {
    _currentPosition = pos;
    if (pos != null) {
      _lastPositionCallbacks.forEach((e) {
        e.call(pos);
      });
      _lastPositionCallbacks.clear();
    }
  }

  void setLastKnownPosition(Coord? pos) {
    if (pos != null && _currentPosition != null) {
      throw ArgumentError('Setting last known position does not make sense '
          'when current position available');
    }
    _lastKnownPosition = pos;
    if (pos != null) {
      _lastPositionCallbacks.forEach((e) {
        e.call(pos);
      });
      _lastPositionCallbacks.clear();
    }
  }

  @override
  void callWhenLastPositionKnown(ArgCallback<Coord> callback) {
    if (lastKnownPositionInstant() != null) {
      callback.call(lastKnownPositionInstant()!);
    } else {
      _lastPositionCallbacks.add(callback);
    }
  }

  @override
  Future<Coord?> currentPosition({required bool explicitUserRequest}) async {
    return _currentPosition;
  }

  @override
  Future<Coord?> lastKnownPosition() async {
    return lastKnownPositionInstant();
  }

  @override
  Coord? lastKnownPositionInstant() {
    if (_currentPosition != null) {
      return _currentPosition;
    }
    return _lastKnownPosition;
  }
}
