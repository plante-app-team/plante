import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_shops_card_base.dart';

class MapPageModeDemonstrateShops extends MapPageModeShopsCardBase {
  MapPageModeDemonstrateShops(MapPageModeParams params)
      : super(params, nameForAnalytics: 'demonstrate_shops');

  @override
  void init(MapPageMode? previousMode) {
    super.init(previousMode);
    shouldShowSearchBar.setValue(false);

    final shops = widget.initialSelectedShops;
    onMarkerClick(shops);
    double? zoom;
    if (shops.length == 1) {
      zoom = 17;
    }
    showOnMap(shops.map((e) => e.coord), zoom: zoom);
  }

  @override
  Iterable<Shop> filter(Iterable<Shop> shops) {
    return widget.initialSelectedShops;
  }

  @override
  Widget buildOverlay() {
    return Stack(children: [
      const HeaderPlante(
        leftAction: FabPlante.backBtnPopOnClick(key: Key('back_button')),
        color: Colors.transparent,
        title: SizedBox(),
      ),
      shopsCardsWidget(),
    ]);
  }

  @override
  Widget createCardFor(Shop shop, FutureShortAddress address,
      ArgCallback<Shop>? cancelCallback) {
    final showDirections = (Shop shop) {
      model.showDirectionsTo(shop);
    };
    return ShopCard.forProductRange(
        shop: shop,
        suggestedProductsCount:
            model.barcodesSuggestions.suggestionsCountFor(shop.osmUID),
        address: address,
        cancelCallback: cancelCallback,
        showDirections: model.areDirectionsAvailable() ? showDirections : null);
  }

  @override
  @protected
  void hideShopsCard() {
    super.hideShopsCard();
    model.finishWith(context, null);
  }
}
