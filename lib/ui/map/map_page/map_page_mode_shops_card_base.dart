import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';

abstract class MapPageModeShopsCardBase extends MapPageMode {
  final _displayedShops = <Shop>[];

  MapPageModeShopsCardBase(MapPageModeParams params,
      {required String nameForAnalytics})
      : super(params, nameForAnalytics: nameForAnalytics);

  @protected
  ShopCard createCardFor(
      Shop shop, FutureShortAddress address, ArgCallback<Shop>? cancelCallback);

  @mustCallSuper
  @override
  bool showWhereAmIFAB() => _displayedShops.isEmpty;

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
        child: _displayedShops.isEmpty
            ? const SizedBox.shrink()
            : _displayedShops.length > 1
                ? _draggableScrollableSheet()
                : _onlyOneShopSheet());
  }

  Widget _onlyOneShopSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              elevation: 3,
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 10, right: 10, bottom: 5),
                        child: InkWell(
                          key: const Key('card_cancel_btn'),
                          onTap: hideShopsCard,
                          child: SvgPicture.asset(
                            'assets/cancel_circle.svg',
                          ),
                        ),
                      ),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(child: _buildShopCard(context, 0)),
                          ]),
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DraggableScrollableSheet _draggableScrollableSheet() {
    return DraggableScrollableSheet(
        key: const Key('shop_card_scroll'),
        initialChildSize: 0.30,
        minChildSize: 0.30,
        maxChildSize: 0.75,
        builder: (context, shopScrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: CustomScrollView(
              controller: shopScrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 1,
                  backgroundColor: Colors.white,
                  shape: const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30))),
                  flexibleSpace: Padding(
                    padding:
                        const EdgeInsets.only(top: 8, left: 160, right: 160),
                    child: Container(
                        height: 2,
                        width: 5,
                        decoration: BoxDecoration(
                            color: ColorsPlante.divider,
                            borderRadius: BorderRadius.circular(30))),
                  ),
                  actions: [
                    InkWell(
                      key: const Key('card_cancel_btn'),
                      onTap: hideShopsCard,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10, top: 5),
                        child: SvgPicture.asset(
                          'assets/cancel_circle.svg',
                        ),
                      ),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(-30),
                    child: Container(), //hack to make appbar smaller
                  ),
                ),
                _shopCards()
              ],
            ),
          );
        });
  }

  Widget _shopCards() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        _buildShopCard,
        childCount: math.max(0, _displayedShops.length * 2 - 1),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, int index) {
    final int itemIndex = index ~/ 2;
    if (index.isEven) {
      return Column(children: [
        createCardFor(
            _displayedShops[itemIndex],
            model.addressOf(_displayedShops[itemIndex]),
            (Shop shop) => hideShopsCard())
      ]);
    }
    return const Divider(
      height: 2,
      color: ColorsPlante.divider,
      indent: 16,
      endIndent: 16,
      thickness: 1,
    );
  }

  @protected
  void hideShopsCard() {
    _displayedShops.clear();
    updateWidget();
    updateMap();
  }

  @override
  void deselectShops() {
    hideShopsCard();
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
