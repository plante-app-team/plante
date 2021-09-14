import 'package:flutter/cupertino.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_model.dart';

class MapPageModeParams {
  final MapPageModel model;
  final MapHintsListController hintsListController;
  final ResCallback<MapPage> widgetSource;
  final ResCallback<BuildContext> contextSource;
  final ResCallback<Iterable<Shop>> displayedShopsSource;
  final VoidCallback updateCallback;
  final VoidCallback updateMapCallback;
  final ArgCallback<String?> bottomHintCallback;
  final ArgCallback<Coord> moveMapCallback;
  final ArgCallback<MapPageMode> modeSwitchCallback;
  final ResCallback<bool> isLoadingCallback;
  final Analytics analytics;
  MapPageModeParams(
      this.model,
      this.hintsListController,
      this.widgetSource,
      this.contextSource,
      this.displayedShopsSource,
      this.updateCallback,
      this.updateMapCallback,
      this.bottomHintCallback,
      this.moveMapCallback,
      this.modeSwitchCallback,
      this.isLoadingCallback,
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
  Iterable<Shop> get displayedShops => params.displayedShopsSource.call();
  bool get loading => params.isLoadingCallback.call();

  void init(MapPageMode? previousMode) {}
  void deinit() {}
  Iterable<Shop> filter(Iterable<Shop> shops) => shops;
  Set<Shop> selectedShops() => {};
  Set<Shop> accentedShops() => {};

  /// Extra shops added to what MapPageModel has
  Set<Shop> additionalShops() => {};
  bool showWhereAmIFAB() => true;

  Widget buildOverlay(BuildContext context) => const SizedBox.shrink();
  Widget buildHeader(BuildContext context) => const SizedBox.shrink();
  Widget buildTopActions(BuildContext context) => const SizedBox.shrink();
  List<Widget> buildBottomActions(BuildContext context) =>
      const [SizedBox.shrink()];
  List<Widget> buildFABs() => const [];
  void deselectShops() {}
  void onMarkerClick(Iterable<Shop> shops) {}
  void onShopsUpdated(Map<String, Shop> shops) {}
  void onMapClick(Coord coord) {}
  void onDisplayedShopsChange(Iterable<Shop> shops) {}
  void onLoadingChange() {}

  /// True if allowed to pop, false if Pop is handled by the mode
  Future<bool> onWillPop() async => true;

  @protected
  void moveMapTo(Coord coord) => params.moveMapCallback.call(coord);
  @protected
  void updateWidget() => params.updateCallback.call();
  @protected
  void updateMap() => params.updateMapCallback.call();
  @protected
  void setBottomHint(String? hint) => params.bottomHintCallback.call(hint);
  @protected
  void switchModeTo(MapPageMode mode) {
    params.modeSwitchCallback.call(mode);
    updateWidget();
    updateMap();
  }
}