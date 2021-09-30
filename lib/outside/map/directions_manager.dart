import 'dart:async';

import 'package:map_launcher/map_launcher.dart';
import 'package:plante/model/coord.dart';

enum DirectionsProvider {
  GOOGLE,
  APPLE,
}

class DirectionsManager {
  final _availableMaps = Completer<List<MapType>>();

  DirectionsManager() {
    _initAsync();
  }

  void _initAsync() async {
    final result = <MapType>[];
    if (await MapLauncher.isMapAvailable(MapType.google) == true) {
      result.add(MapType.google);
    }
    if (await MapLauncher.isMapAvailable(MapType.apple) == true) {
      result.add(MapType.apple);
    }
    _availableMaps.complete(result);
  }

  Future<bool> areDirectionsAvailable() async {
    final directions = await _availableMaps.future;
    return directions.isNotEmpty;
  }

  void direct(Coord destination, String destinationTitle) async {
    final directions = await _availableMaps.future;
    if (directions.isEmpty) {
      return;
    }
    await MapLauncher.showDirections(
      mapType: directions.first,
      destination: Coords(destination.lat, destination.lon),
      destinationTitle: destinationTitle,
    );
  }
}
