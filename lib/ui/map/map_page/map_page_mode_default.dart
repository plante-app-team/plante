import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/components/map_filter_check_button.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_add_product.dart';
import 'package:plante/ui/map/map_page/map_page_mode_select_shops_where_product_sold.dart';
import 'package:plante/ui/map/map_page/map_page_mode_shops_card_base.dart';
import 'package:plante/ui/map/map_page/map_page_mode_zoomed_out.dart';

class MapPageModeDefault extends MapPageModeShopsCardBase {
  static const MIN_ZOOM = 6.0;
  static const _PREF_SHOW_ALL_SHOPS = 'MapPageModeDefault_SHOW_ALL_SHOPS2';
  static const _PREF_SHOW_NOT_EMPTY_SHOPS =
      'MapPageModeDefault_SHOW_NOT_EMPTY_SHOPS2';

  late final UIValue<bool> _showAllShops;
  late final UIValue<bool> _showNotEmptyShops;
  late final Map<String, MapFilter> _filterOptions;

  ArgCallback<bool>? _onLoadingChange;

  MapPageModeDefault(MapPageModeParams params)
      : super(params, nameForAnalytics: 'default') {
    _showAllShops = createUIValue(true);
    _showNotEmptyShops = createUIValue(false);
  }

  @override
  void init(MapPageMode? previousMode) {
    super.init(previousMode);
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
        _initAsync();
        break;
    }
  }

  void _initAsync() async {
    final prefs = await model.prefs.get();
    final showAllShops =
        prefs.getBool(_PREF_SHOW_ALL_SHOPS) ?? _showAllShops.cachedVal;
    final showNotEmptyShops = prefs.getBool(_PREF_SHOW_NOT_EMPTY_SHOPS) ??
        _showNotEmptyShops.cachedVal;
    _showAllShops.setValue(showAllShops);
    _showNotEmptyShops.setValue(
      showNotEmptyShops,
    );

    _filterOptions = {
      _PREF_SHOW_ALL_SHOPS: MapFilter(
          target: _showAllShops,
          pref: _PREF_SHOW_ALL_SHOPS,
          eventShown: 'all_shops_shown',
          eventHidden: 'all_shops_hidden'),
      _PREF_SHOW_NOT_EMPTY_SHOPS: MapFilter(
          target: _showNotEmptyShops,
          pref: _PREF_SHOW_NOT_EMPTY_SHOPS,
          eventShown: 'shops_with_products_shown',
          eventHidden: 'shops_with_products_hidden'),
    };

    _onLoadingChange = (_) {
      _updateBottomHint();
    };
    loading.callOnChanges(_onLoadingChange!);
  }

  @override
  void deinit() {
    if (_onLoadingChange != null) {
      loading.unregisterCallback(_onLoadingChange!);
    }
    setBottomHint(null);
    super.deinit();
  }

  @override
  Iterable<Shop> filter(Iterable<Shop> shops) {
    final shouldShow = (Shop shop) {
      if (selectedShops().contains(shop) || accentedShops().contains(shop)) {
        return true;
      }

      if (_showAllShops.cachedVal) {
        return true;
      }

      var hasProducts = 0 < shop.productsCount;
      if (!hasProducts) {
        final suggestedBarcodes = model.barcodesSuggestions;
        for (final type in SuggestionType.values) {
          hasProducts =
              0 < suggestedBarcodes.suggestionsCountFor(shop.osmUID, type);
          if (hasProducts) {
            break;
          }
        }
      }

      return hasProducts && _showNotEmptyShops.cachedVal;
    };
    return shops.where(shouldShow);
  }

  @override
  Widget buildTopActions() {
    return consumer((ref) {
      if (model.loading.watch(ref) || !model.viewPortShopsLoaded.watch(ref)) {
        return const SizedBox();
      }
      return SizedBox(
          height: MapFilterCheckButton.TOTAL_HEIGHT,
          child: ListView(
              key: const Key('filter_listview'),
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 24),
                MapFilterCheckButton(
                    key: const Key('button_filter_all_shops'),
                    checked: _showAllShops.watch(ref),
                    text: context.strings.map_page_filter_all_shops,
                    onChanged: _setShowAllShops),
                const SizedBox(width: 8),
                MapFilterCheckButton(
                    key: const Key('button_filter_not_empty_shops'),
                    checked: _showNotEmptyShops.watch(ref),
                    text: context.strings.map_page_filter_not_empty_shops2,
                    onChanged: _setShowNotEmptyShops),
                const SizedBox(width: 24),
              ]));
    });
  }

  void _setShowNotEmptyShops(bool value) {
    _onFilterClick(_PREF_SHOW_NOT_EMPTY_SHOPS);
  }

  void _onFilterClick(String pref) async {
    if (_filterOptions[pref]?.target.cachedVal == true) {
      // Only switching from false to true is supported
      return;
    }

    final prefs = await model.prefs.get();
    for (final filter in _filterOptions.values) {
      if (filter.pref == pref) {
        filter.target.setValue(true);
        await prefs.setBool(filter.pref, true);
      } else {
        filter.target.setValue(false);
        await prefs.setBool(filter.pref, false);
      }
    }

    analytics.sendEvent(_filterOptions[pref]!.eventShown);
    updateMap();
    onDisplayedShopsChange(displayedShops);
  }

  void _setShowAllShops(bool value) {
    _onFilterClick(_PREF_SHOW_ALL_SHOPS);
  }

  @override
  Widget buildOverlay() {
    return shopsCardsWidget();
  }

  @override
  ShopCard createCardFor(Shop shop, FutureShortAddress address,
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
  void onDisplayedShopsChange(Iterable<Shop> shops) {
    _updateBottomHint();
  }

  @override
  void onCameraIdle() {
    _updateBottomHint();
  }

  void _updateBottomHint() {
    if (displayedShops.isNotEmpty ||
        loading.cachedVal ||
        loadingSuggestions.cachedVal ||
        !shopsForViewPortLoaded.cachedVal) {
      setBottomHint(null);
      return;
    }

    setBottomHintSimple(context.strings.map_page_no_shops_hint3);
  }

  @override
  double minZoom() => MIN_ZOOM;

  @override
  void onCameraMove(Coord coord, double zoom) {
    if (zoom < super.minZoom()) {
      switchModeTo(MapPageModeZoomedOut(params));
    }
  }
}

class MapFilter {
  final UIValue<bool> target;
  final String pref;
  final String eventShown;
  final String eventHidden;

  MapFilter(
      {required this.target,
      required this.pref,
      required this.eventShown,
      required this.eventHidden});
}
