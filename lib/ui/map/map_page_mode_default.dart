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
import 'package:plante/ui/map/map_page_mode_select_shops.dart';
import 'package:plante/ui/map/map_page_model.dart';

class MapPageModeDefault extends MapPageMode {
  bool _showEmptyShops = false;
  final _displayedShops = <Shop>[];

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
  bool shopWhereAmIFAB() => _displayedShops.isEmpty;

  @override
  Iterable<Shop> filter(Iterable<Shop> shops) {
    return shops
        .where((shop) => _showEmptyShops ? true : shop.productsCount > 0);
  }

  @override
  Set<Shop> accentedShops() => _displayedShops.toSet();

  @override
  void onMarkerClick(Iterable<Shop> shops) {
    _setDisplayedShops(shops);
  }

  void _setDisplayedShops(Iterable<Shop> shops) {
    if (listEquals(shops.toList(), _displayedShops)) {
      return;
    }
    _displayedShops.clear();
    _displayedShops.addAll(shops.toList());
    _displayedShops.sort((a, b) => b.productsCount - a.productsCount);
    updateWidget();
    updateMap();
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
      AnimatedSwitcher(
          duration: DURATION_DEFAULT,
          child:
              _displayedShops.isEmpty ? const SizedBox.shrink() : _shopCards())
    ]);
  }

  Widget _shopCards() {
    return PageView.builder(
      controller: PageController(viewportFraction: 0.90),
      itemCount: _displayedShops.length,
      itemBuilder: _buildShopCard,
    );
  }

  Widget _buildShopCard(BuildContext context, int itemIndex) {
    const horizontalPadding = 6.0;
    final double leftPadding;
    if (itemIndex == 0) {
      leftPadding = 0;
    } else {
      leftPadding = horizontalPadding;
    }
    return Material(
        color: Colors.transparent,
        child: Stack(children: [
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: _hideShopsCard,
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Wrap(children: [
                Padding(
                    padding: EdgeInsets.only(
                        left: leftPadding,
                        right: horizontalPadding,
                        bottom: 12),
                    child: ShopCard(
                        shop: _displayedShops[itemIndex],
                        cancelCallback: (Shop shop) => _hideShopsCard()))
              ]))
        ]));
  }

  void _hideShopsCard() {
    _displayedShops.clear();
    updateWidget();
    updateMap();
  }
}
