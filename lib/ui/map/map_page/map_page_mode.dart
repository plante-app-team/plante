import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_model.dart';

class MapPageModeParams {
  final MapPageModel model;
  final MapHintsListController hintsListController;
  final ResCallback<MapPage> widgetSource;
  final ResCallback<BuildContext> contextSource;
  final ResCallback<Iterable<Shop>> displayedShopsSource;
  final VoidCallback updateMapCallback;
  final ArgCallback<RichText?> bottomHintCallback;
  final ArgCallback<Coord> moveMapCallback;
  final ArgCallback<MapPageMode> modeSwitchCallback;
  final UIValuesFactory uiValuesFactory;
  final UIValueBase<bool> isLoading;
  final UIValueBase<bool> isLoadingSuggestions;
  final UIValueBase<bool> areShopsForViewPortLoaded;
  final UIValue<bool> shouldLoadNewShops;
  final Analytics analytics;
  MapPageModeParams(
      {required this.model,
      required this.hintsListController,
      required this.widgetSource,
      required this.contextSource,
      required this.displayedShopsSource,
      required this.updateMapCallback,
      required this.bottomHintCallback,
      required this.moveMapCallback,
      required this.modeSwitchCallback,
      required this.uiValuesFactory,
      required this.isLoading,
      required this.isLoadingSuggestions,
      required this.areShopsForViewPortLoaded,
      required this.shouldLoadNewShops,
      required this.analytics});
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
  UIValueBase<bool> get loading => params.isLoading;
  UIValueBase<bool> get loadingSuggestions => params.isLoadingSuggestions;
  UIValueBase<bool> get shopsForViewPortLoaded =>
      params.areShopsForViewPortLoaded;
  UIValue<bool> get shouldLoadNewShops => params.shouldLoadNewShops;

  @mustCallSuper
  void init(MapPageMode? previousMode) {
    shouldLoadNewShops.setValue(true);
  }

  @mustCallSuper
  void deinit() {}
  Iterable<Shop> filter(Iterable<Shop> shops) => shops;
  Set<Shop> selectedShops() => {};
  Set<Shop> accentedShops() => {};

  /// Extra shops added to what MapPageModel has
  Set<Shop> additionalShops() => {};
  double minZoom() => DEFAULT_MIN_ZOOM;
  double maxZoom() => DEFAULT_MAX_ZOOM;

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
  void onCameraMove(Coord coord, double zoom) {}
  void onCameraIdle() {}

  /// True if allowed to pop, false if Pop is handled by the mode
  Future<bool> onWillPop() async => true;

  @protected
  UIValue<T> createUIValue<T>(T initialValue) =>
      params.uiValuesFactory.create(initialValue);

  @protected
  void moveMapTo(Coord coord) => params.moveMapCallback.call(coord);
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
  }
}
