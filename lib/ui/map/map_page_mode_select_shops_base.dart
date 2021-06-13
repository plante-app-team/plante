import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_mode_create_shop.dart';

const MAP_PAGE_MODE_SELECTED_SHOPS_MAX = 10;

abstract class MapPageModeSelectShopsBase extends MapPageMode {
  final _selectedShops = <Shop>{};

  MapPageModeSelectShopsBase(MapPageModeParams params) : super(params) {
    _selectedShops.addAll(widget.initialSelectedShops);
  }

  void onDoneClick();

  @override
  Set<Shop> selectedShops() => _selectedShops;

  @mustCallSuper
  @override
  void init(MapPageMode? previousMode) {
    if (previousMode != null) {
      _selectedShops.addAll(previousMode.selectedShops());
    }
  }

  @override
  void onMarkerClick(Iterable<Shop> shops) {
    if (shops.length == 1) {
      final shop = shops.first;
      if (_selectedShops.contains(shop)) {
        _selectedShops.remove(shop);
        updateMap();
        return;
      }

      if (_selectedShops.length >= MAP_PAGE_MODE_SELECTED_SHOPS_MAX) {
        Log.w('Not allowing to select more than 10 shops');
        return;
      }

      final String title;
      if (widget.product != null) {
        title = context.strings.map_page_is_product_sold_q
            .replaceAll('<PRODUCT>', widget.product!.name ?? '')
            .replaceAll('<SHOP>', shop.name);
      } else {
        title = context.strings.map_page_is_new_product_sold_q
            .replaceAll('<SHOP>', shop.name);
      }
      showYesNoDialog<void>(context, title, () {
        _selectedShops.add(shop);
        updateMap();
      });
    } else {
      // TODO(https://trello.com/c/dCDHecZS/): implement with proper design
      showSnackBar('Markers cluster click is not supported yet', context);
    }
  }

  @override
  Widget buildOverlay(BuildContext context) {
    return Stack(children: [
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
                      onPressed: selectedShops().isNotEmpty && !model.loading
                          ? onDoneClick
                          : null)),
            ]),
          )),
      Align(
        alignment: Alignment.topCenter,
        child: ButtonFilledPlante.withText(context.strings.map_page_plus_shop,
            onPressed: !model.loading ? _addShopClick : null),
      )
    ]);
  }

  void _addShopClick() {
    switchModeTo(MapPageModeCreateShop(params));
  }

  void _onCancelClick() async {
    if (selectedShops().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await showYesNoDialog(
        context, context.strings.map_page_cancel_putting_product_q, () {
      Navigator.of(context).pop();
    });
  }

  @override
  Future<bool> onWillPop() async {
    if (selectedShops().isNotEmpty) {
      _onCancelClick();
      return false;
    }
    return true;
  }
}
