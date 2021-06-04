import 'package:flutter/material.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_base.dart';

class MapPageModeAddProduct extends MapPageModeSelectShopsBase {
  MapPageModeAddProduct(MapPageModeParams params) : super(params);

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
}
