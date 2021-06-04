import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/checkbox_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/map/map_page.dart';
import 'package:plante/ui/map/map_page_mode.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/map_page_mode_add_product.dart';
import 'package:plante/ui/map/map_page_mode_select_shops.dart';
import 'package:plante/ui/map/map_page_model.dart';
import 'package:plante/ui/map/shop_product_range_page.dart';
import 'package:plante/ui/map/shops_list_page.dart';

class MapPageModeDefault extends MapPageMode {
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
  void init() {
    switch (widget.requestedMode) {
      case MapPageRequestedMode.ADD_PRODUCT:
        if (widget.product == null) {
          Log.e('Requested mode ADD_PRODUCT but the product is null');
        }
        switchModeTo(MapPageModeAddProduct(params));
        break;
      case MapPageRequestedMode.SELECT_SHOPS:
        switchModeTo(MapPageModeSelectShops(params));
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
  void onMarkerClick(Iterable<Shop> shops) {
    if (shops.length > 1) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShopsListPage(shops: shops.toList())));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShopProductRangePage(shop: shops.first)));
    }
  }

  @override
  Widget buildOverlay(BuildContext context) {
    return Align(
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
        ));
  }
}
