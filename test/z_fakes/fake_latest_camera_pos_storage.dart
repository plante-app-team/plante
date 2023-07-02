import 'package:plante/model/coord.dart';
import 'package:plante/ui/map/latest_camera_pos_storage.dart';

class FakeLatestCameraPosStorage implements LatestCameraPosStorage {
  Coord? _pos = Coord(lat: 10, lon: 20);

  @override
  Future<Coord?> get() async => _pos;

  @override
  Coord? getCached() => _pos;

  @override
  Future<void> set(Coord? pos) async {
    _pos = pos;
  }
}
