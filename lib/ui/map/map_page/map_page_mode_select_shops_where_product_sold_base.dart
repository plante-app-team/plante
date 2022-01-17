import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_text_plante.dart';
import 'package:plante/ui/base/components/shop_card.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/map/components/fab_add_shop.dart';
import 'package:plante/ui/map/map_page/map_page_mode.dart';
import 'package:plante/ui/map/map_page/map_page_mode_shops_card_base.dart';

const MAP_PAGE_MODE_SELECTED_SHOPS_MAX = 10;

abstract class MapPageModeSelectShopsWhereProductSoldBase
    extends MapPageModeShopsCardBase {
  static const _HINT_ID = 'MapPageModeSelectShopsWhereProductSoldBase hint 1';
  late final UIValue<Set<Shop>> _selectedShops;
  late final UIValue<Set<Shop>> _unselectedShops;

  MapPageModeSelectShopsWhereProductSoldBase(MapPageModeParams params,
      {required String nameForAnalytics})
      : super(params, nameForAnalytics: nameForAnalytics) {
    _selectedShops = createUIValue({...widget.initialSelectedShops});
    _unselectedShops = createUIValue({});
  }

  @protected
  void onDoneClick();
  @protected
  void onAddShopClicked();

  @override
  Set<Shop> selectedShops() => _selectedShops.cachedVal;

  @mustCallSuper
  @override
  void init(MapPageMode? previousMode) {
    super.init(previousMode);

    if (previousMode != null) {
      final selectedShops = _selectedShops.cachedVal.toSet();
      selectedShops.addAll(
          previousMode.selectedShops().take(MAP_PAGE_MODE_SELECTED_SHOPS_MAX));
      _selectedShops.setValue(selectedShops);
    }

    hintsController.addHint(
        _HINT_ID, context.strings.map_page_click_on_shop_where_product_sold);
    onDisplayedShopsChange(displayedShops);
  }

  @mustCallSuper
  @override
  void deinit() {
    hintsController.removeHint(_HINT_ID);
    setBottomHintSimple(null);
    super.deinit();
  }

  @override
  Widget createCardFor(Shop shop, FutureShortAddress address,
      ArgCallback<Shop>? cancelCallback) {
    return consumer((ref) {
      final Product product;
      if (widget.product != null) {
        product = widget.product!;
      } else {
        product = Product((e) => e.barcode = 'fake_product');
      }

      bool? isSold;
      final selectedShops = _selectedShops.watch(ref);
      final unselectedShops = _unselectedShops.watch(ref);
      if (selectedShops.contains(shop)) {
        isSold = true;
      } else if (unselectedShops.contains(shop)) {
        isSold = false;
      }

      return ShopCard.askIfProductIsSold(
          product: product,
          shop: shop,
          address: address,
          isProductSold: isSold,
          onIsProductSoldChanged: _onProductSoldChange,
          cancelCallback: cancelCallback);
    });
  }

  void _onProductSoldChange(Shop shop, bool? isSold) {
    final selectedShops = _selectedShops.cachedVal.toSet();
    final unselectedShops = _unselectedShops.cachedVal.toSet();

    selectedShops.remove(shop);
    unselectedShops.remove(shop);
    if (isSold == true) {
      if (selectedShops.length < MAP_PAGE_MODE_SELECTED_SHOPS_MAX) {
        selectedShops.add(shop);
      } else {
        Log.w('Not allowing to select more than 10 shops');
      }
    } else if (isSold == false) {
      unselectedShops.add(shop);
    }
    hideShopsCard();

    _selectedShops.setValue(selectedShops);
    _unselectedShops.setValue(unselectedShops);
  }

  @override
  Widget buildOverlay() {
    return Stack(children: [shopsCardsWidget()]);
  }

  @override
  List<Widget> buildFABs() {
    return [
      consumer((ref) {
        final loading = super.loading.watch(ref);
        return FabAddShop(
            key: const Key('add_shop_fab'),
            onPressed: !loading ? onAddShopClicked : null);
      }),
    ];
  }

  @override
  List<Widget> buildBottomActions() {
    return [
      SizedBox(
          key: const Key('map_page_cancel'),
          width: double.infinity,
          child: Padding(
              padding: const EdgeInsets.only(left: 26, right: 26, bottom: 8),
              child: ButtonTextPlante(context.strings.global_cancel,
                  onPressed: _onCancelClick))),
      SizedBox(
          key: const Key('map_page_done'),
          width: double.infinity,
          child: Padding(
              padding: const EdgeInsets.only(left: 26, right: 26, bottom: 24),
              child: consumer((ref) {
                final loading = super.loading.watch(ref);
                final selectedShops = _selectedShops.watch(ref);
                return ButtonFilledPlante.withText(context.strings.global_done,
                    onPressed: selectedShops.isNotEmpty && !loading
                        ? onDoneClick
                        : null);
              }))),
    ];
  }

  void _onCancelClick() async {
    if (selectedShops().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await showYesNoDialog(
        context, context.strings.map_page_cancel_putting_product_q, () {
      Navigator.of(context).pop();
    });
  }

  @override
  Future<bool> onWillPop() async {
    final superAllowedPop = await super.onWillPop();
    if (!superAllowedPop) {
      return superAllowedPop;
    }
    if (selectedShops().isNotEmpty) {
      _onCancelClick();
      return false;
    }
    return true;
  }

  @override
  void onDisplayedShopsChange(Iterable<Shop> shops) {
    if (shops.isEmpty) {
      setBottomHintSimple(
          context.strings.map_page_no_shops_hint_in_select_shops_mode);
    } else {
      setBottomHintSimple(null);
    }
  }
}
