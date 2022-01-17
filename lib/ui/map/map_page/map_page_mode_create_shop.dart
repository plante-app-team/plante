import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_type.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm/osm_element_type.dart';
import 'package:plante/outside/map/osm/osm_shop.dart';
import 'package:plante/outside/map/osm/osm_uid.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/create_shop_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';

class MapPageModeCreateShop extends MapPageMode {
  static const _NEW_SHOP_PSEUDO_OSM_ID =
      OsmUID(OsmElementType.NODE, 'NEW_SHOP_PSEUDO_OSM_ID');
  static const _HINT_ID = 'MapPageModeCreateShop hint 1';
  final ResCallback<MapPageMode> nextModeMaker;
  final Set<Shop> _selectedShops = <Shop>{};
  Shop? _shopBeingCreated;
  MapPageModeCreateShop(MapPageModeParams params, this.nextModeMaker)
      : super(params, nameForAnalytics: 'create_shop');

  @override
  void init(MapPageMode? previousMode) {
    super.init(previousMode);
    _selectedShops.addAll(previousMode!.selectedShops());
    hintsController.addHint(
        _HINT_ID, context.strings.map_page_click_where_new_shop_located);
  }

  @override
  void deinit() {
    hintsController.removeHint(_HINT_ID);
    super.deinit();
  }

  // Let's hide markers of all other shops so that
  // they wouldn't mess user's taps
  @override
  Iterable<Shop> filter(Iterable<Shop> shops) =>
      shops.where((shop) => shop.osmUID == _NEW_SHOP_PSEUDO_OSM_ID);

  @override
  Set<Shop> selectedShops() => _selectedShops;

  @override
  Set<Shop> accentedShops() => additionalShops();

  @override
  Set<Shop> additionalShops() =>
      _shopBeingCreated != null ? {_shopBeingCreated!} : {};

  @override
  void onMapClick(Coord coord) async {
    // Temporary marker
    _shopBeingCreated = _createShop('', ShopType.supermarket, coord);
    moveMapTo(coord);
    updateMap();

    final yes = await showDoOrCancelDialog(
        context,
        context.strings.map_page_is_shop_location_correct,
        context.strings.global_yes,
        () {},
        cancelWhat: context.strings.global_oops_no);
    if (yes != true) {
      return;
    }

    final dialogResult = await Navigator.push<Shop>(
      context,
      MaterialPageRoute(builder: (context) => CreateShopPage(shopCoord: coord)),
    );

    if (dialogResult != null) {
      _selectedShops.add(dialogResult);
      switchModeTo(nextModeMaker.call());
      showSnackBar(context.strings.map_page_shop_added_to_map, context,
          SnackBarStyle.MAP_ACTION_DONE);
      return;
    }
    _shopBeingCreated = null;
    updateMap();
  }

  Shop _createShop(String name, ShopType type, Coord coords) {
    return Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmUID = _NEW_SHOP_PSEUDO_OSM_ID
        ..longitude = coords.lon
        ..latitude = coords.lat
        ..name = name
        ..type = type.osmName))
      ..backendShop.replace(BackendShop((e) => e
        ..osmUID = _NEW_SHOP_PSEUDO_OSM_ID
        ..productsCount = 0)));
  }

  @override
  Widget buildHeader() {
    return Align(
        alignment: Alignment.centerRight,
        child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FabPlante(
              key: const Key('close_create_shop_button'),
              heroTag: 'close_create_shop_button',
              svgAsset: 'assets/cancel.svg',
              onPressed: _onCancelClick,
            )));
  }

  void _onCancelClick() async {
    if (_shopBeingCreated == null) {
      switchModeTo(nextModeMaker.call());
      return;
    }
    await showYesNoDialog<void>(
        context, context.strings.map_page_cancel_shop_creation_q, () {
      switchModeTo(nextModeMaker.call());
    });
  }

  @override
  List<Widget> buildBottomActions() {
    // TODO(https://trello.com/c/rb2w42J5/): remove the function after
    // the ticket from the Trello URL will be fixed.
    return const [SizedBox.shrink(key: Key('map_page_done'))];
  }
}
