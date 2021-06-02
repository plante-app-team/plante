import 'package:flutter/cupertino.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/map_page.dart';

typedef WidgetSource = MapPage Function();
typedef ContextSource = BuildContext Function();
typedef ModeSwitchCallback = void Function(MapPageMode newMode);

class MapPageModeParams {
  final WidgetSource widgetSource;
  final ContextSource contextSource;
  final VoidCallback updateCallback;
  final VoidCallback updateMapCallback;
  final ModeSwitchCallback modeSwitchCallback;
  MapPageModeParams(this.widgetSource, this.contextSource, this.updateCallback,
      this.updateMapCallback, this.modeSwitchCallback);
}

abstract class MapPageMode {
  final MapPageModeParams params;

  MapPageMode(this.params);

  MapPage get widget => params.widgetSource.call();
  BuildContext get context => params.contextSource.call();

  void init() {}
  Iterable<Shop> filter(Iterable<Shop> shops) => shops;
  Set<Shop> selectedShops() => {};
  Widget buildOverlay(BuildContext context);
  void onMarkerClick(Iterable<Shop> shops);

  void updateWidget() => params.updateCallback.call();
  void updateMap() => params.updateMapCallback.call();
  void switchModeTo(MapPageMode mode) {
    params.modeSwitchCallback.call(mode);
    updateWidget();
    updateMap();
  }
}
