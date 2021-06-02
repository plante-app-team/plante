import 'package:flutter/material.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
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
      showSnackBar(
          'Ой, добавление продуктов в скопление магазинов пока не работает, '
          'попробуйте приблизить карту',
          context);
    }
  }

  @override
  Widget buildOverlay(BuildContext context) {
    return const SizedBox.shrink();
  }
}
