import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/checkbox_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_mode_add_product.dart';
import 'package:plante/ui/map/map_page_mode_shops_card_base.dart';
import 'package:plante/ui/map/map_page_mode_select_shops_where_product_sold.dart';
import 'package:plante/ui/map/map_page_model.dart';

class MapPageModeDefault extends MapPageModeShopsCardBase {
  bool _showEmptyShops = false;

  MapPageModeDefault(
      Analytics analytics,
      MapPageModel model,
      MapHintsListController hintsController,
      WidgetSource widgetSource,
      ContextSource contextSource,
      DisplayedShopsSource displayedShopsSource,
      VoidCallback updateCallback,
      VoidCallback updateMapCallback,
      ArgCallback<String?> bottomHintCallback,
      ModeSwitchCallback modeSwitchCallback)
      : super(
            MapPageModeParams(
                model,
                hintsController,
                widgetSource,
                contextSource,
                displayedShopsSource,
                updateCallback,
                updateMapCallback,
                bottomHintCallback,
                modeSwitchCallback,
                analytics),
            nameForAnalytics: 'default');

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
  void deinit() {
    setBottomHint(null);
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
                  _setShopEmptyShops(!_showEmptyShops);
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 16),
                  Text(context.strings.map_page_empty_shops,
                      style: TextStyles.smallBoldGreen),
                  CheckboxPlante(
                      value: _showEmptyShops,
                      onChanged: (value) {
                        _setShopEmptyShops(value ?? false);
                      })
                ]),
              ),
            )));
  }

  void _setShopEmptyShops(bool value) {
    _showEmptyShops = value;
    updateWidget();
    updateMap();
    if (_showEmptyShops) {
      analytics.sendEvent('empty_shops_shown');
    } else {
      analytics.sendEvent('empty_shops_hidden');
    }
    onDisplayedShopsChange(displayedShops);
  }

  @override
  Widget buildOverlay(BuildContext context) {
    return shopsCardsWidget(context);
  }

  @override
  ShopCard createCardFor(Shop shop, cancelCallback) {
    return ShopCard.forProductRange(shop: shop, cancelCallback: cancelCallback);
  }

  @override
  void onDisplayedShopsChange(Iterable<Shop> shops) {
    if (shops.isEmpty) {
      if (!_showEmptyShops) {
        setBottomHint(context.strings.map_page_no_shops_hint_default_mode_1);
      } else {
        setBottomHint(context.strings.map_page_no_shops_hint_default_mode_2);
      }
    } else {
      setBottomHint(null);
    }
  }
}
