import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/checkbox_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_mode_add_product.dart';
import 'package:plante/ui/map/map_page_mode_base.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_where_product_sold.dart';
import 'package:plante/ui/map/map_page_model.dart';

class MapPageModeDefault extends MapPageModeShopsCardBase {
  bool _showEmptyShops = false;

  MapPageModeDefault(
      MapPageModel model,
      MapHintsListController hintsController,
      WidgetSource widgetSource,
      ContextSource contextSource,
      VoidCallback updateCallback,
      VoidCallback updateMapCallback,
      ModeSwitchCallback modeSwitchCallback)
      : super(MapPageModeParams(
            model,
            hintsController,
            widgetSource,
            contextSource,
            updateCallback,
            updateMapCallback,
            modeSwitchCallback));

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
  Widget buildTopActions(BuildContext context) {
    return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
            height: 40,
            child: Material(
              color: const Color(0xFFEBF0ED),
              elevation: 1,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showEmptyShops = !_showEmptyShops;
                  updateWidget();
                  updateMap();
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 16),
                  Text(context.strings.map_page_empty_shops,
                      style: TextStyles.smallBoldGreen),
                  CheckboxPlante(
                      value: _showEmptyShops,
                      onChanged: (value) {
                        _showEmptyShops = value ?? false;
                        updateWidget();
                        updateMap();
                      })
                ]),
              ),
            )));
  }

  @override
  Widget buildOverlay(BuildContext context) {
    return shopsCardsWidget(context);
  }

  @override
  ShopCard createCardFor(Shop shop, cancelCallback) {
    return ShopCard.forProductRange(shop: shop, cancelCallback: cancelCallback);
  }
}
