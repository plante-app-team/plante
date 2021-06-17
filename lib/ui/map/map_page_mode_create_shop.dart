import 'dart:math';

import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_text_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/components/create_shop_dialog.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_where_product_sold.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_where_product_sold_base.dart';
import 'package:plante/l10n/strings.dart';

class MapPageModeCreateShop extends MapPageMode {
  static const _NEW_SHOP_PSEUDO_OSM_ID = 'NEW_SHOP_PSEUDO_OSM_ID';
  static const _HINT_ID = 'MapPageModeCreateShop hint 1';
  final Set<Shop> _selectedShop = <Shop>{};
  Shop? _shopBeingCreated;
  MapPageModeCreateShop(MapPageModeParams params) : super(params);

  @override
  void init(MapPageMode? previousMode) {
    if (previousMode == null ||
        previousMode is! MapPageModeSelectShopsWhereProductSoldBase) {
      Log.e('MapPageModeSelectShopsBase expected, got $previousMode');
    }
    _selectedShop.addAll(previousMode!.selectedShops());

    hintsController.addHint(
        _HINT_ID, context.strings.map_page_click_where_new_shop_located);
  }

  @override
  void deinit() {
    hintsController.removeHint(_HINT_ID);
  }

  // Let's hide markers of all other shops so that
  // they wouldn't mess user's taps
  @override
  Iterable<Shop> filter(Iterable<Shop> shops) =>
      shops.where((shop) => shop.osmId == _NEW_SHOP_PSEUDO_OSM_ID);

  @override
  Set<Shop> selectedShops() => _selectedShop;

  @override
  Set<Shop> accentedShops() => additionalShops();

  @override
  Set<Shop> additionalShops() =>
      _shopBeingCreated != null ? {_shopBeingCreated!} : {};

  @override
  void onMapClick(Point<double> coords) async {
    // Temporary marker
    _shopBeingCreated = _createShop('', coords);
    updateMap();

    final result = await showDialog<CreateShopDialogResult>(
      context: context,
      builder: (BuildContext context) {
        return const CreateShopDialog();
      },
    );

    if (result != null) {
      _shopBeingCreated = _createShop(result.name, coords);
    } else {
      _shopBeingCreated = null;
    }
    updateMap();
  }

  Shop _createShop(String name, Point<double> coords) {
    return Shop((e) => e
      ..osmShop.replace(OsmShop((e) => e
        ..osmId = _NEW_SHOP_PSEUDO_OSM_ID
        ..longitude = coords.x
        ..latitude = coords.y
        ..name = name))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = _NEW_SHOP_PSEUDO_OSM_ID
        ..productsCount = 0)));
  }

  @override
  Widget buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 26, right: 26, bottom: 38),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            width: double.infinity,
            child: ButtonTextPlante(context.strings.global_cancel,
                onPressed: _onCancelClick)),
        const SizedBox(height: 8),
        SizedBox(
            width: double.infinity,
            child: ButtonFilledPlante.withText(context.strings.global_done,
                onPressed: _shopBeingCreated != null && !model.loading
                    ? _onDoneClick
                    : null)),
      ]),
    );
  }

  void _onCancelClick() async {
    if (_shopBeingCreated == null) {
      Navigator.of(context).pop();
      return;
    }
    await showYesNoDialog<void>(
        context, context.strings.map_page_cancel_shop_creation_q, () {
      Navigator.of(context).pop();
    });
  }

  void _onDoneClick() async {
    final shop = _shopBeingCreated!;
    final result = await model.createShop(
      shop.name,
      Point<double>(shop.longitude, shop.latitude),
    );
    if (result.isOk) {
      switchModeTo(MapPageModeSelectShopsWhereProductSold(params));
    } else {
      if (result.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
    }
  }
}
