import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/checkbox_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_mode_add_product.dart';
import 'package:plante/ui/map/map_page_mode_base.dart';
import 'package:plante/ui/map/map_page_mode_select_shops.dart';
import 'package:plante/ui/map/map_page_model.dart';

class MapPageModeDefault extends MapPageModeShopsCardBase {
  bool _showEmptyShops = false;

  MapPageModeDefault(
      MapPageModel model,
      WidgetSource widgetSource,
      ContextSource contextSource,
      VoidCallback updateCallback,
      VoidCallback updateMapCallback,
      ModeSwitchCallback modeSwitchCallback)
      : super(MapPageModeParams(model, widgetSource, contextSource,
            updateCallback, updateMapCallback, modeSwitchCallback));

  @override
  void init(MapPageMode? previousMode) {
    switch (widget.requestedMode) {
      case MapPageRequestedMode.ADD_PRODUCT:
        if (widget.product == null) {
          Log.e('Requested mode ADD_PRODUCT but the product is null');
        }
        switchModeTo(MapPageModeAddProduct(params));
        break;
      case MapPageRequestedMode.SELECT_SHOPS:
        switchModeTo(MapPageModeSelectShopsWhereProductSold(params));
        break;
      case MapPageRequestedMode.DEFAULT:
        if (widget.product != null) {
          Log.e('Requested mode DEFAULT but "productToAdd" != null');
        }
        break;
    }
  }

  @override
  Iterable<Shop> filter(Iterable<Shop> shops) {
    return shops
        .where((shop) => _showEmptyShops ? true : shop.productsCount > 0);
  }

  @override
  Widget buildOverlay(BuildContext context) {
    return Stack(children: [
      Align(
          alignment: Alignment.topRight,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showEmptyShops = !_showEmptyShops;
                updateWidget();
                updateMap();
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(context.strings.map_page_empty_shops,
                    style: TextStyles.normalSmall),
                CheckboxPlante(
                    value: _showEmptyShops,
                    onChanged: (value) {
                      _showEmptyShops = value ?? false;
                      updateWidget();
                      updateMap();
                    })
              ]),
            ),
          )),
      shopsCardsWidget(context),
    ]);
  }

  @override
  ShopCard createCardFor(Shop shop, cancelCallback) {
    return ShopCard.forProductRange(shop: shop, cancelCallback: cancelCallback);
  }
}
