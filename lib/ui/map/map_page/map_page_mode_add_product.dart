import 'package:flutter/material.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page/map_page_mode_create_shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode_select_shops_where_product_sold_base.dart';

class MapPageModeAddProduct extends MapPageModeSelectShopsWhereProductSoldBase {
  MapPageModeAddProduct(MapPageModeParams params)
      : super(params, nameForAnalytics: 'add_product');

  @override
  void onDoneClick() async {
    final result = await model.putProductToShops(
        widget.product!, selectedShops().toList());
    if (result.isErr) {
      if (result.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
      return;
    }
    showSnackBar(context.strings.global_done_thanks, context);
    Navigator.of(context).pop();
  }

  @override
  void onAddShopClicked() {
    final nextModeMaker = () {
      return MapPageModeAddProduct(params);
    };
    switchModeTo(MapPageModeCreateShop(params, nextModeMaker));
  }
}
