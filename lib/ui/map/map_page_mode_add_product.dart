import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/l10n/strings.dart';

class MapPageModeAddProduct extends MapPageMode {
  final _selectedShops = <Shop>{};
  MapPageModeAddProduct(MapPageModeParams params) : super(params);

  Product get product => widget.productToAdd!;

  @override
  Set<Shop> selectedShops() => _selectedShops;

  @override
  void onMarkerClick(Iterable<Shop> shops) {
    if (shops.length == 1) {
      final shop = shops.first;
      if (_selectedShops.contains(shop)) {
        _selectedShops.remove(shop);
        updateMap();
        return;
      }

      if (_selectedShops.length >= 10) {
        // TODO(https://trello.com/c/dCDHecZS/): test
        Log.w('Not allowing to select more than 10 shops');
        return;
      }

      final title = context.strings.map_page_is_product_sold_q
          .replaceAll('<PRODUCT>', product.name ?? '???')
          .replaceAll('<SHOP>', shop.name);
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return DialogPlante(
              content: Text(title, style: TextStyles.headline1),
              actions: Row(children: [
                Expanded(
                    child: ButtonOutlinedPlante.withText(
                  context.strings.global_oops_no,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: ButtonFilledPlante.withText(
                  context.strings.global_yes,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _selectedShops.add(shop);
                    updateMap();
                  },
                )),
              ]));
        },
      );
    } else {
      // TODO(https://trello.com/c/dCDHecZS/): implement with proper design
      showSnackBar('Markers cluster click is not supported yet', context);
    }
  }

  @override
  Widget buildOverlay(BuildContext context) {
    return Align(
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
                child: ButtonFilledPlante.withText(context.strings.global_done,
                    onPressed: _selectedShops.isNotEmpty && !model.loading
                        ? _onDoneClick
                        : null)),
          ]),
        ));
  }

  void _onCancelClick() async {
    if (_selectedShops.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return DialogPlante(
            content: Text(context.strings.map_page_cancel_putting_product_q,
                style: TextStyles.headline1),
            actions: Row(children: [
              Expanded(
                  child: ButtonOutlinedPlante.withText(
                context.strings.global_no,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: ButtonFilledPlante.withText(
                context.strings.global_yes,
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              )),
            ]));
      },
    );
  }

  void _onDoneClick() async {
    final result =
        await model.putProductToShops(product, _selectedShops.toList());
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
  Future<bool> onWillPop() async {
    if (_selectedShops.isNotEmpty) {
      _onCancelClick();
      return false;
    }
    return true;
  }
}
