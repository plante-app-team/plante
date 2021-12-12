import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/ui/base/text_styles.dart';
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
  final ArgCallback<RichText?> bottomHintCallback;
  final ArgCallback<Coord> moveMapCallback;
  final ArgCallback<MapPageMode> modeSwitchCallback;
  final ResCallback<bool> isLoadingCallback;
  final ResCallback<bool> areShopsForViewPortLoadedCallback;
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
      this.areShopsForViewPortLoadedCallback,
      this.analytics);
}

abstract class MapPageMode {
  static const DEFAULT_MIN_ZOOM = 11.0;
  static const DEFAULT_MAX_ZOOM = 19.0;

  final String nameForAnalytics;
  final MapPageModeParams params;

  MapPageMode(this.params, {required this.nameForAnalytics});

  MapPageModel get model => params.model;
  MapPage get widget => params.widgetSource.call();
  BuildContext get context => params.contextSource.call();
  WidgetRef get ref => context as WidgetRef;
  MapHintsListController get hintsController => params.hintsListController;
  Analytics get analytics => params.analytics;
  Iterable<Shop> get displayedShops => params.displayedShopsSource.call();
  bool get loading => params.isLoadingCallback.call();
  bool get shopsForViewPortLoaded =>
      params.areShopsForViewPortLoadedCallback.call();

  @mustCallSuper
  void init(MapPageMode? previousMode) {}
  @mustCallSuper
  void deinit() {}
  Iterable<Shop> filter(
          Iterable<Shop> shops, Iterable<OsmUID> withSuggestedProducts) =>
      shops;
  Set<Shop> selectedShops() => {};
  Set<Shop> accentedShops() => {};

  /// Extra shops added to what MapPageModel has
  Set<Shop> additionalShops() => {};
  bool showWhereAmIFAB() => true;
  double minZoom() => DEFAULT_MIN_ZOOM;
  double maxZoom() => DEFAULT_MAX_ZOOM;
  bool loadNewShops() => true;

  Widget buildOverlay() => const SizedBox.shrink();
  Widget buildHeader() => const SizedBox.shrink();
  Widget buildTopActions() => const SizedBox.shrink();
  List<Widget> buildBottomActions() => const [SizedBox.shrink()];
  List<Widget> buildFABs() => const [];
  void deselectShops() {}
  void onMarkerClick(Iterable<Shop> shops) {}
  void onShopsUpdated(Map<OsmUID, Shop> shops) {}
  void onMapClick(Coord coord) {}
  void onDisplayedShopsChange(Iterable<Shop> shops) {}
  void onLoadingChange() {}
  void onCameraMove(Coord coord, double zoom) {}
  void onCameraIdle() {}

  /// True if allowed to pop, false if Pop is handled by the mode
  Future<bool> onWillPop() async => true;

  @protected
  void moveMapTo(Coord coord) => params.moveMapCallback.call(coord);
  @protected
  void updateWidget() => params.updateCallback.call();
  @protected
  void updateMap() => params.updateMapCallback.call();
  @protected
  void setBottomHintSimple(String? hint) =>
      params.bottomHintCallback.call(hint != null
          ? RichText(text: TextSpan(text: hint, style: TextStyles.normal))
          : null);
  @protected
  void setBottomHint(RichText? hint) => params.bottomHintCallback.call(hint);
  @protected
  void switchModeTo(MapPageMode mode) {
    params.modeSwitchCallback.call(mode);
    updateWidget();
    updateMap();
  }
}
