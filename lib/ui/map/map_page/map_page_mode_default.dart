import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/analytics.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/coord.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/products/suggestions/suggestion_type.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/button_filled_small_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value_wrapper.dart';
import 'package:plante/ui/map/components/map_hints_list.dart';
import 'package:plante/ui/map/components/map_shops_filter_checkbox.dart';
import 'package:plante/ui/map/map_page/map_page.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_add_product.dart';
import 'package:plante/ui/map/map_page/map_page_mode_select_shops_where_product_sold.dart';
import 'package:plante/ui/map/map_page/map_page_mode_shops_card_base.dart';
import 'package:plante/ui/map/map_page/map_page_mode_zoomed_out.dart';
import 'package:plante/ui/map/map_page/map_page_model.dart';

class MapPageModeDefault extends MapPageModeShopsCardBase {
  static const MIN_ZOOM = 6.0;
  static const _PREF_SHOW_NOT_EMPTY_SHOPS =
      'MapPageModeDefault_SHOW_NOT_EMPTY_SHOPS';
  static const _PREF_SHOW_EMPTY_SHOPS = 'MapPageModeDefault_SHOW_EMPTY_SHOPS';
  static const _PREF_SHOW_SUGGESTIONS = 'MapPageModeDefault_SHOW_SUGGESTIONS_';

  final _filtersButtonKey = GlobalKey();

  final _showNotEmptyShops = UIValueWrapper<bool>(true);
  final _showSuggestionsAtShop = <SuggestionType, UIValueWrapper<bool>>{};
  final _showEmptyShops = UIValueWrapper<bool>(false);

  MapPageModeDefault(Analytics analytics, MapPageModel model,
      MapHintsListController hintsController,
      {required ResCallback<MapPage> widgetSource,
      required ResCallback<BuildContext> contextSource,
      required ResCallback<Iterable<Shop>> displayedShopsSource,
      required VoidCallback updateCallback,
      required VoidCallback updateMapCallback,
      required ArgCallback<RichText?> bottomHintCallback,
      required ArgCallback<Coord> moveMapCallback,
      required ArgCallback<MapPageMode> modeSwitchCallback,
      required ResCallback<bool> isLoadingCallback,
      required ResCallback<bool> areShopsForViewPortLoadedCallback,
      required UIValueWrapper<bool> shouldLoadNewShops})
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
                moveMapCallback,
                modeSwitchCallback,
                isLoadingCallback,
                areShopsForViewPortLoadedCallback,
                shouldLoadNewShops,
                analytics),
            nameForAnalytics: 'default');

  MapPageModeDefault.withParams(MapPageModeParams params)
      : super(params, nameForAnalytics: 'default');

  @override
  void init(MapPageMode? previousMode) {
    super.init(previousMode);

    for (final type in SuggestionType.values) {
      _showSuggestionsAtShop[type] = UIValueWrapper<bool>(true);
    }

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
    final showNotEmptyShops = prefs.getBool(_PREF_SHOW_NOT_EMPTY_SHOPS) ??
        _showNotEmptyShops.cachedVal;
    final showEmptyShops =
        prefs.getBool(_PREF_SHOW_EMPTY_SHOPS) ?? _showEmptyShops.cachedVal;
    _showNotEmptyShops.setValue(showNotEmptyShops, ref);
    _showEmptyShops.setValue(showEmptyShops, ref);

    for (final type in SuggestionType.values) {
      final prefVal = prefs.getBool(type.prefName);
      if (prefVal != null) {
        _showSuggestionsAtShop[type]?.setValue(prefVal, ref);
      }
    }
  }

  @override
  void deinit() {
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
    if (!shopsForViewPortLoaded) {
      return super.buildTopActions();
    }

    return Align(
        alignment: Alignment.centerRight,
        child: ButtonFilledSmallPlante.lightGreen(
          key: _filtersButtonKey,
          elevation: 5,
          onPressed: () {
            _onFiltersClick(context);
          },
          paddings: EdgeInsets.zero,
          height: 32,
          width: 32,
          icon: SvgPicture.asset('assets/map_filters.svg',
              key: const Key('filter_shops_icon')),
        ));
  }

  void _onFiltersClick(BuildContext context) async {
    await showCustomPopUp(
      target: _filtersButtonKey,
      context: context,
      child: Consumer(builder: (context, ref, _) {
        return Column(children: [
          MapShopsFilterCheckbox(
            key: const Key('checkbox_filter_not_empty_shops'),
            text: context.strings.map_page_filter_not_empty_shops,
            markerColor: ColorsPlante.primary,
            value: _showNotEmptyShops.watch(ref),
            onChanged: _setShowNotEmptyShops,
          ),
          MapShopsFilterCheckbox(
            key: const Key('filter_shops_with_rad_suggested_products'),
            text: context
                .strings.map_page_filter_shops_with_radius_suggested_products,
            markerColor: const Color(0xFF3D948D),
            value: _showSuggestionsAtShop[SuggestionType.RADIUS]!.watch(ref),
            onChanged: _setShowRadSuggestedShops,
          ),
          MapShopsFilterCheckbox(
            key: const Key('filter_shops_with_off_suggested_products'),
            text: context
                .strings.map_page_filter_shops_with_off_suggested_products,
            markerColor: const Color(0xFF3D948D),
            value: _showSuggestionsAtShop[SuggestionType.OFF]!.watch(ref),
            onChanged: _setShowOffSuggestedShops,
          ),
          MapShopsFilterCheckbox(
            key: const Key('filter_empty_shops'),
            text: context.strings.map_page_filter_empty_shops,
            markerColor: ColorsPlante.grey,
            value: _showEmptyShops.watch(ref),
            onChanged: _setShowEmptyShops,
          ),
        ]);
      }),
    );
  }

  void _setShowNotEmptyShops(bool value) {
    _setFilterValue(
      value,
      pref: _PREF_SHOW_NOT_EMPTY_SHOPS,
      target: _showNotEmptyShops,
      eventShown: 'shops_with_products_shown',
      eventHidden: 'shops_with_products_hidden',
    );
  }

  void _setFilterValue(bool value,
      {required UIValueWrapper<bool> target,
      required String pref,
      required String eventShown,
      required String eventHidden}) async {
    target.setValue(value, ref);
    updateWidget();
    updateMap();
    if (target.cachedVal) {
      analytics.sendEvent(eventShown);
    } else {
      analytics.sendEvent(eventHidden);
    }
    onDisplayedShopsChange(displayedShops);

    final prefs = await model.prefs.get();
    await prefs.setBool(pref, value);
  }

  void _setShowRadSuggestedShops(bool value) {
    _setFilterValue(
      value,
      pref: SuggestionType.RADIUS.prefName,
      target: _showSuggestionsAtShop[SuggestionType.RADIUS]!,
      eventShown: 'shops_with_rad_suggestions_shown',
      eventHidden: 'shops_with_rad_suggestions_hidden',
    );
  }

  void _setShowOffSuggestedShops(bool value) {
    _setFilterValue(
      value,
      pref: SuggestionType.OFF.prefName,
      target: _showSuggestionsAtShop[SuggestionType.OFF]!,
      eventShown: 'shops_with_off_suggestions_shown',
      eventHidden: 'shops_with_off_suggestions_hidden',
    );
  }

  void _setShowEmptyShops(bool value) {
    _setFilterValue(
      value,
      pref: _PREF_SHOW_EMPTY_SHOPS,
      target: _showEmptyShops,
      eventShown: 'empty_shops_shown',
      eventHidden: 'empty_shops_hidden',
    );
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
  void onLoadingChange() {
    _updateBottomHint();
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
    if (displayedShops.isNotEmpty || loading || !shopsForViewPortLoaded) {
      setBottomHint(null);
      return;
    }

    setBottomHint(RichText(
        text: TextSpan(
      style: TextStyles.normal,
      children: [
        TextSpan(text: context.strings.map_page_no_shops_hint2),
        WidgetSpan(
            child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SvgPicture.asset('assets/map_filters.svg'))),
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
