import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/map/map_page_model.dart';

typedef WidgetSource = MapPage Function();
typedef ContextSource = BuildContext Function();
typedef ModeSwitchCallback = void Function(MapPageMode newMode);

class MapPageModeParams {
  final MapPageModel model;
  final WidgetSource widgetSource;
  final ContextSource contextSource;
  final VoidCallback updateCallback;
  final VoidCallback updateMapCallback;
  final ModeSwitchCallback modeSwitchCallback;
  MapPageModeParams(this.model, this.widgetSource, this.contextSource,
      this.updateCallback, this.updateMapCallback, this.modeSwitchCallback);
}

abstract class MapPageMode {
  final MapPageModeParams params;

  MapPageMode(this.params);

  MapPageModel get model => params.model;
  MapPage get widget => params.widgetSource.call();
  BuildContext get context => params.contextSource.call();

  void init(MapPageMode? previousMode) {}
  Iterable<Shop> filter(Iterable<Shop> shops) => shops;
  Set<Shop> selectedShops() => {};
  Set<Shop> accentedShops() => {};
  bool shopWhereAmIFAB() => true;

  /// Extra shops added to what MapPageModel has
  Set<Shop> additionalShops() => {};
  Widget buildOverlay(BuildContext context);
  Widget buildBottomActions(BuildContext context) => const SizedBox.shrink();
  List<Widget> buildFABs() => const [];
  void onMarkerClick(Iterable<Shop> shops) {}
  void onMapClick(Point<double> coords) {}

  /// True if allowed to pop, false if Pop is handled by the mode
  Future<bool> onWillPop() async => true;

  void updateWidget() => params.updateCallback.call();
  void updateMap() => params.updateMapCallback.call();
  void switchModeTo(MapPageMode mode) {
    params.modeSwitchCallback.call(mode);
    updateWidget();
    updateMap();
  }
}
