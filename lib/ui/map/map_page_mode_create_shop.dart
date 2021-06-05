import 'dart:math';

import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/backend/backend_shop.dart';
import 'package:plante/outside/map/osm_shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/create_shop_dialog_content.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/ui/map/map_page_mode_select_shops.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_base.dart';
import 'package:plante/l10n/strings.dart';

class MapPageModeCreateShop extends MapPageMode {
  final Set<Shop> _selectedShop = <Shop>{};
  Shop? _shopBeingCreated;
  MapPageModeCreateShop(MapPageModeParams params) : super(params);

  @override
  void init(MapPageMode? previousMode) {
    if (previousMode == null || previousMode is! MapPageModeSelectShopsBase) {
      Log.e('MapPageModeSelectShopsBase expected, got $previousMode');
    }
    _selectedShop.addAll(previousMode!.selectedShops());
  }

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
        return const DialogPlante(content: CreateShopDialogContent());
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
        ..osmId = 'new shop from MapPageModeCreateShop'
        ..longitude = coords.x
        ..latitude = coords.y
        ..name = name))
      ..backendShop.replace(BackendShop((e) => e
        ..osmId = 'new shop from MapPageModeCreateShop'
        ..productsCount = 0)));
  }

  @override
  Widget buildOverlay(BuildContext context) {
    return Stack(children: [
      Align(
          alignment: Alignment.topCenter,
          child: Text(context.strings.map_page_click_where_new_shop_located)),
      Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 26, right: 26, bottom: 68),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                  width: double.infinity,
                  child: ButtonOutlinedPlante.withText(
                      context.strings.global_cancel,
                      onPressed: _onCancelClick)),
              const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  child: ButtonFilledPlante.withText(
                      context.strings.global_done,
                      onPressed: _shopBeingCreated != null && !model.loading
                          ? _onDoneClick
                          : null)),
            ]),
          )),
    ]);
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
      switchModeTo(MapPageModeSelectShops(params));
    } else {
      if (result.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
    }
  }
}
