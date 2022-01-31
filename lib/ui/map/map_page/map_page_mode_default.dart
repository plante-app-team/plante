import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/base/components/check_button_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/popup/popup_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_add_product.dart';
import 'package:plante/ui/map/map_page/map_page_mode_select_shops_where_product_sold.dart';
import 'package:plante/ui/map/map_page/map_page_mode_shops_card_base.dart';
import 'package:plante/ui/map/map_page/map_page_mode_zoomed_out.dart';

class MapPageModeDefault extends MapPageModeShopsCardBase {
  static const MIN_ZOOM = 6.0;
  static const _PREF_SHOW_ALL_SHOPS = 'MapPageModeDefault_SHOW_ALL_SHOPS';
  static const _PREF_SHOW_NOT_EMPTY_SHOPS =
      'MapPageModeDefault_SHOW_NOT_EMPTY_SHOPS';
  static const _PREF_SHOW_EMPTY_SHOPS = 'MapPageModeDefault_SHOW_EMPTY_SHOPS';
  static const _PREF_SHOW_SUGGESTIONS = 'MapPageModeDefault_SHOW_SUGGESTIONS_';

  late final UIValue<bool> _showAllShops;
  late final UIValue<bool> _showNotEmptyShops;
  final _showSuggestionsAtShop = <SuggestionType, UIValue<bool>>{};
  late final UIValue<bool> _showEmptyShops;
  late final Map<String, MapFilter> _filterOptions;

  ArgCallback<bool>? _onLoadingChange;

  MapPageModeDefault(MapPageModeParams params)
      : super(params, nameForAnalytics: 'default') {
    _showAllShops = createUIValue(false);
    _showNotEmptyShops = createUIValue(true);
    _showEmptyShops = createUIValue(false);
    for (final type in SuggestionType.values) {
      _showSuggestionsAtShop[type] = createUIValue(true);
    }
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
    final showEmptyShops =
        prefs.getBool(_PREF_SHOW_EMPTY_SHOPS) ?? _showEmptyShops.cachedVal;
    _showAllShops.setValue(showAllShops);
    _showNotEmptyShops.setValue(
      showNotEmptyShops,
    );
    _showEmptyShops.setValue(showEmptyShops);

    for (final type in SuggestionType.values) {
      final prefVal = prefs.getBool(type.prefName);
      if (prefVal != null) {
        _showSuggestionsAtShop[type]?.setValue(prefVal);
      }
    }

    _filterOptions = {
      _PREF_SHOW_NOT_EMPTY_SHOPS: MapFilter(
          target: _showNotEmptyShops,
          pref: _PREF_SHOW_NOT_EMPTY_SHOPS,
          eventShown: 'shops_with_products_shown',
          eventHidden: 'shops_with_products_hidden'),
      _PREF_SHOW_ALL_SHOPS: MapFilter(
          target: _showAllShops,
          pref: _PREF_SHOW_ALL_SHOPS,
          eventShown: 'all_shops_shown',
          eventHidden: 'all_shops_hidden'),
      SuggestionType.RADIUS.prefName: MapFilter(
          target: _showSuggestionsAtShop[SuggestionType.RADIUS]!,
          pref: SuggestionType.RADIUS.prefName,
          eventShown: 'shops_with_rad_suggestions_shown',
          eventHidden: 'shops_with_rad_suggestions_hidden'),
      SuggestionType.OFF.prefName: MapFilter(
          target: _showSuggestionsAtShop[SuggestionType.OFF]!,
          pref: SuggestionType.OFF.prefName,
          eventShown: 'shops_with_off_suggestions_shown',
          eventHidden: 'shops_with_off_suggestions_hidden'),
      _PREF_SHOW_EMPTY_SHOPS: MapFilter(
          target: _showEmptyShops,
          pref: _PREF_SHOW_EMPTY_SHOPS,
          eventShown: 'empty_shops_shown',
          eventHidden: 'empty_shops_hidden'),
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

      final enabledByNotEmptyShopsFilter =
          _showNotEmptyShops.cachedVal && 0 < shop.productsCount;
      final enabledByEmptyShopsFilter =
          _showEmptyShops.cachedVal && shop.productsCount <= 0;

      final suggestedBarcodes = model.barcodesSuggestions;
      bool enabledBySuggestions = false;
      for (final type in SuggestionType.values) {
        final enabled = _showSuggestionsAtShop[type]?.cachedVal ?? false;
        final exists =
            suggestedBarcodes.suggestionsCountFor(shop.osmUID, type) > 0;
        enabledBySuggestions = enabled && exists;
        if (enabledBySuggestions) {
          break;
        }
      }

      return enabledByNotEmptyShopsFilter ||
          enabledBySuggestions ||
          enabledByEmptyShopsFilter;
    };
    return shops.where(shouldShow);
  }

  @override
  Widget buildTopActions() {
    return SizedBox(
        height: 30,
        child: ListView(
            key: const Key('filter_listview'),
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CheckButtonPlante(
                      key: const Key('button_filter_all_shops'),
                      checked: _showAllShops.watch(ref),
                      text: context.strings.map_page_filter_all_shops,
                      onChanged: _setShowAllShops,
                      showBorder: true)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CheckButtonPlante(
                      key: const Key('button_filter_not_empty_shops'),
                      checked: _checkButton(_showNotEmptyShops.watch(ref)),
                      text: context.strings.map_page_filter_not_empty_shops,
                      onChanged: _setShowNotEmptyShops,
                      showBorder: true)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CheckButtonPlante(
                      key:
                          const Key('filter_shops_with_rad_suggested_products'),
                      checked: _checkButton(
                          _showSuggestionsAtShop[SuggestionType.RADIUS]!
                              .watch(ref)),
                      text: context.strings
                          .map_page_filter_shops_with_radius_suggested_products,
                      onChanged: _setShowRadSuggestedShops,
                      showBorder: true)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CheckButtonPlante(
                    key: const Key('filter_shops_with_off_suggested_products'),
                    checked: _checkButton(
                        _showSuggestionsAtShop[SuggestionType.OFF]!.watch(ref)),
                    text: context.strings
                        .map_page_filter_shops_with_off_suggested_products,
                    onChanged: _setShowOffSuggestedShops,
                    showBorder: true,
                  )),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CheckButtonPlante(
                      key: const Key('filter_empty_shops'),
                      checked: _checkButton(_showEmptyShops.watch(ref)),
                      text: context.strings.map_page_filter_empty_shops,
                      onChanged: _setShowEmptyShops,
                      showBorder: true)),
            ]));
  }

  void _setShowNotEmptyShops(bool value) {
    _setFilterValue(value, pref: _PREF_SHOW_NOT_EMPTY_SHOPS);
    _resetFilters(_PREF_SHOW_NOT_EMPTY_SHOPS);
  }

  void _setFilterValue(bool value, {required String pref}) async {
    final MapFilter _mapFilter = _filterOptions[pref]!;
    final UIValue<bool> _target = _mapFilter.target;
    _target.setValue(value);
    updateMap();
    if (_target.cachedVal) {
      analytics.sendEvent(_mapFilter.eventShown);
    } else {
      analytics.sendEvent(_mapFilter.eventHidden);
    }
    onDisplayedShopsChange(displayedShops);

    final prefs = await model.prefs.get();
    await prefs.setBool(pref, value);
  }

  bool _checkButton(bool value) {
    if (_showAllShops.cachedVal) {
      return false;
    }
    return value;
  }

  void _resetFilters(String selectedPref) {
    //when all shops is selected and we click another filter, reset all filters to false except the selected
    if (_showAllShops.cachedVal) {
      _filterOptions.keys.forEach((filterOption) {
        if (filterOption != selectedPref) {
          _setFilterValue(
            false,
            pref: filterOption,
          );
        }
      });
    }
  }

  void _setShowAllShops(bool value) {
    _filterOptions.keys.forEach((filterOption) {
      _setFilterValue(
        value,
        pref: filterOption,
      );
    });
  }

  void _setShowRadSuggestedShops(bool value) {
    _setFilterValue(
      value,
      pref: SuggestionType.RADIUS.prefName,
    );
    _resetFilters(SuggestionType.RADIUS.prefName);
  }

  void _setShowOffSuggestedShops(bool value) {
    _setFilterValue(
      value,
      pref: SuggestionType.OFF.prefName,
    );
    _resetFilters(SuggestionType.OFF.prefName);
  }

  void _setShowEmptyShops(bool value) {
    _setFilterValue(
      value,
      pref: _PREF_SHOW_EMPTY_SHOPS,
    );
    _resetFilters(_PREF_SHOW_EMPTY_SHOPS);
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

    setBottomHint(RichText(
        text: TextSpan(
      style: TextStyles.normal,
      children: [
        TextSpan(text: context.strings.map_page_no_shops_hint2),
      ],
    )));
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

extension on SuggestionType {
  String get prefName =>
      MapPageModeDefault._PREF_SHOW_SUGGESTIONS + prefPostfix;

  String get prefPostfix {
    // Must be persistent
    switch (this) {
      case SuggestionType.OFF:
        return 'OFF';
      case SuggestionType.RADIUS:
        return 'RADIUS';
    }
  }
}
