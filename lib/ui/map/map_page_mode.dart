import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/map/map_page_model.dart';

typedef WidgetSource = MapPage Function();
typedef ContextSource = BuildContext Function();
typedef ModeSwitchCallback = void Function(MapPageMode newMode);

class MapPageModeParams {
  final MapPageModel model;
  final MapHintsListController hintsListController;
  final WidgetSource widgetSource;
  final ContextSource contextSource;
  final VoidCallback updateCallback;
  final VoidCallback updateMapCallback;
  final ModeSwitchCallback modeSwitchCallback;
  final Analytics analytics;
  MapPageModeParams(
      this.model,
      this.hintsListController,
      this.widgetSource,
      this.contextSource,
      this.updateCallback,
      this.updateMapCallback,
      this.modeSwitchCallback,
      this.analytics);
}

abstract class MapPageMode {
  final String nameForAnalytics;
  final MapPageModeParams params;

  MapPageMode(this.params, {required this.nameForAnalytics});

  MapPageModel get model => params.model;
  MapPage get widget => params.widgetSource.call();
  BuildContext get context => params.contextSource.call();
  MapHintsListController get hintsController => params.hintsListController;
  Analytics get analytics => params.analytics;

  void init(MapPageMode? previousMode) {}
  void deinit() {}
  Iterable<Shop> filter(Iterable<Shop> shops) => shops;
  Set<Shop> selectedShops() => {};
  Set<Shop> accentedShops() => {};
  bool shopWhereAmIFAB() => true;

  /// Extra shops added to what MapPageModel has
  Set<Shop> additionalShops() => {};
  Widget buildOverlay(BuildContext context) => const SizedBox.shrink();
  Widget buildHeader(BuildContext context) => const SizedBox.shrink();
  Widget buildTopActions(BuildContext context) => const SizedBox.shrink();
  List<Widget> buildBottomActions(BuildContext context) => const [];
  List<Widget> buildFABs() => const [];
  void onMarkerClick(Iterable<Shop> shops) {}
  void onShopsUpdated(Map<String, Shop> shops) {}
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
