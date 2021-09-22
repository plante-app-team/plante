import 'package:flutter/material.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_icon_plante.dart';
import 'package:plante/ui/base/components/check_button_plante.dart';
import 'package:plante/ui/base/components/shop_address_widget.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';
import 'package:plante/ui/shop/shop_product_range_page.dart';

typedef ShopCardProductSoldChangeCallback = dynamic Function(
    Shop shop, bool? isSold);

class ShopCard extends StatelessWidget {
  final Shop shop;
  final FutureShortAddress address;
  final ArgCallback<Shop>? cancelCallback;

  final Product? checkedProduct;
  final bool? isProductSold;
  final ShopCardProductSoldChangeCallback? onIsProductSoldChanged;

  const ShopCard._(
      {Key? key,
      required this.shop,
      required this.address,
      required this.checkedProduct,
      this.isProductSold,
      this.onIsProductSoldChanged,
      this.cancelCallback})
      : super(key: key);

  factory ShopCard.forProductRange(
      {Key? key,
      required Shop shop,
      required FutureShortAddress address,
      ArgCallback<Shop>? cancelCallback}) {
    return ShopCard._(
        key: key,
        shop: shop,
        address: address,
        checkedProduct: null,
        cancelCallback: cancelCallback);
  }

  factory ShopCard.askIfProductIsSold(
      {Key? key,
      required Product product,
      required Shop shop,
      required FutureShortAddress address,
      required bool? isProductSold,
      required ShopCardProductSoldChangeCallback onIsProductSoldChanged,
      ArgCallback<Shop>? cancelCallback}) {
    return ShopCard._(
        key: key,
        shop: shop,
        address: address,
        checkedProduct: product,
        isProductSold: isProductSold,
        onIsProductSoldChanged: onIsProductSoldChanged,
        cancelCallback: cancelCallback);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 16),
                  child: Material(
                    color: _haveProducts()
                        ? ColorsPlante.amber
                        : ColorsPlante.lightGrey,
                    borderRadius: BorderRadius.circular(5),
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                            _haveProducts()
                                ? 'Products listed'
                                : 'Nothing listed',
                            style: TextStyles.tag)),
                  ),
                ),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 16, top: 16),
                        child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
                              child: Text(shop.name,
                                  textAlign: TextAlign.start,
                                  style: TextStyles.headline2,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            )))),
              ]),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ShopAddressWidget(shop, address),
          ),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                if (checkedProduct == null) _productRangeContent(context),
                if (checkedProduct != null) _checkIfProductSoldContent(context),
              ]))
        ]));
  }

  Widget _productRangeContent(BuildContext context) {
    return _getButton(context);
  }

  Widget _getButton(BuildContext context) {
    if (_haveProducts()) {
      return SizedBox(
          width: 115,
          child: ButtonFilledPlante.withText(
            context.strings.shop_card_open_shop_products,
            onPressed: () {
              _onMainButtonClick(context);
            },
            height: 35,
            textStyle: TextStyles.buttonFilledSmall,
          ));
    }
    return SizedBox(
        width: 160,
        child: ButtonIconPlante(context.strings.shop_card_add_product,
            onPressed: () {
          _onMainButtonClick(context);
        },
            icon: const Icon(
              Icons.add_sharp,
              color: Colors.white,
            ),
            height: 35));
  }

  Widget _checkIfProductSoldContent(BuildContext context) {
    final product = checkedProduct!;
    final onChanged = onIsProductSoldChanged!;

    final String title;
    if (product.name != null) {
      title = context.strings.map_page_is_product_sold_q
          .replaceAll('<PRODUCT>', product.name!);
    } else {
      title = context.strings.map_page_is_new_product_sold_q;
    }

    return Column(children: [
      SizedBox(
          width: double.infinity, child: Text(title, style: TextStyles.normal)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: SizedBox(
                height: 35,
                child: CheckButtonPlante(
                  key: Key('${product.barcode}_sold_false'),
                  checked: isProductSold == false,
                  text: context.strings.global_no,
                  onChanged: (value) {
                    if (value == false) {
                      onChanged.call(shop, null);
                    } else {
                      onChanged.call(shop, false);
                    }
                  },
                ))),
        const SizedBox(width: 15),
        Expanded(
            child: SizedBox(
                height: 35,
                child: CheckButtonPlante(
                  key: Key('${product.barcode}_sold_true'),
                  checked: isProductSold == true,
                  text: context.strings.global_yes,
                  onChanged: (value) {
                    if (value == false) {
                      onChanged.call(shop, null);
                    } else {
                      onChanged.call(shop, true);
                    }
                  },
                )))
      ])
    ]);
  }

  bool _haveProducts() {
    return 0 < shop.productsCount;
  }

  void _onMainButtonClick(BuildContext context) {
    if (_haveProducts()) {
      ShopProductRangePage.show(context: context, shop: shop);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BarcodeScanPage(addProductToShop: shop)));
    }
  }
}
