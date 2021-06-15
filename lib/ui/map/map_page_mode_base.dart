import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
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

abstract class MapPageModeShopsCardBase extends MapPageMode {
  final _displayedShops = <Shop>[];

  MapPageModeShopsCardBase(MapPageModeParams params) : super(params);

  @protected
  ShopCard createCardFor(Shop shop, ArgCallback<Shop>? cancelCallback);

  @mustCallSuper
  @override
  bool shopWhereAmIFAB() => _displayedShops.isEmpty;

  @mustCallSuper
  @override
  Set<Shop> accentedShops() => _displayedShops.toSet();

  @mustCallSuper
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

  @protected
  Widget shopsCardsWidget(BuildContext context) {
    return AnimatedSwitcher(
        duration: DURATION_DEFAULT,
        child:
            _displayedShops.isEmpty ? const SizedBox.shrink() : _shopCards());
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
                    child: createCardFor(_displayedShops[itemIndex],
                        (Shop shop) => _hideShopsCard()))
              ]))
        ]));
  }

  void _hideShopsCard() {
    _displayedShops.clear();
    updateWidget();
    updateMap();
  }
}
