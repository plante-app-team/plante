import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page_mode.dart';

abstract class MapPageModeShopsCardBase extends MapPageMode {
  final _displayedShops = <Shop>[];

  MapPageModeShopsCardBase(MapPageModeParams params,
      {required String nameForAnalytics})
      : super(params, nameForAnalytics: nameForAnalytics);

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

  @override
  void onShopsUpdated(Map<String, Shop> shops) {
    if (_displayedShops.isEmpty) {
      return;
    }
    final oldDisplayedShops = _displayedShops.toList();
    for (var index = 0; index < _displayedShops.length; ++index) {
      final shop = _displayedShops[index];
      _displayedShops[index] = shops[shop.osmId] ?? shop;
    }
    if (!listEquals(oldDisplayedShops, _displayedShops)) {
      updateWidget();
      updateMap();
    }
  }

  @protected
  Widget shopsCardsWidget(BuildContext context) {
    return AnimatedSwitcher(
        duration: DURATION_DEFAULT,
        child:
            _displayedShops.isEmpty ? const SizedBox.shrink() : _shopCards());
  }

  Widget _shopCards() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
            height: 230,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.87),
              itemCount: _displayedShops.length,
              itemBuilder: _buildShopCard,
            )));
  }

  Widget _buildShopCard(BuildContext context, int itemIndex) {
    final double leftPadding;
    final double rightPadding;
    if (_displayedShops.length == 1) {
      leftPadding = 0;
      rightPadding = 0;
    } else if (itemIndex == 0) {
      leftPadding = 0;
      rightPadding = 6;
    } else if (itemIndex == _displayedShops.length - 1) {
      leftPadding = 6;
      rightPadding = 0;
    } else {
      leftPadding = 6;
      rightPadding = 6;
    }
    return Material(
        color: Colors.transparent,
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Wrap(children: [
              Padding(
                  padding: EdgeInsets.only(
                      left: leftPadding, right: rightPadding, bottom: 12),
                  child: createCardFor(_displayedShops[itemIndex],
                      (Shop shop) => hideShopsCard()))
            ])));
  }

  @protected
  void hideShopsCard() {
    _displayedShops.clear();
    updateWidget();
    updateMap();
  }

  @mustCallSuper
  @override
  Future<bool> onWillPop() async {
    if (_displayedShops.isNotEmpty) {
      hideShopsCard();
      return false;
    }
    return true;
  }
}
