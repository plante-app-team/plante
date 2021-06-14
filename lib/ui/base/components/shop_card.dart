import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/shop_product_range_page.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final ArgCallback<Shop>? cancelCallback;
  const ShopCard({Key? key, required this.shop, this.cancelCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(children: [
          Align(
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                    key: const Key('card_cancel_btn'),
                    onPressed: _onCancel,
                    icon: SvgPicture.asset('assets/cancel_circle.svg')),
              )),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(textDirection: TextDirection.rtl, children: [
                const SizedBox(
                    width:
                        35), // So that the name wouldn't be behind the cancel button
                Expanded(child: Text(shop.name, style: TextStyles.headline1))
              ]),
              const SizedBox(height: 35),
              SizedBox(
                  width: double.infinity,
                  child: Text(
                      _haveProducts()
                          ? context.strings.shop_card_there_are_products_in_shop
                          : context.strings.shop_card_no_products_in_shop,
                      style: TextStyles.normal)),
              const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  child: ButtonFilledPlante.withText(
                      _haveProducts()
                          ? context.strings.shop_card_open_shop_products
                          : context.strings.shop_card_add_product,
                      onPressed: () {
                    _onMainButtonClick(context);
                  }))
            ]),
          ),
        ]));
  }

  bool _haveProducts() {
    return 0 < shop.productsCount;
  }

  void _onCancel() {
    cancelCallback?.call(shop);
  }

  void _onMainButtonClick(BuildContext context) {
    if (_haveProducts()) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShopProductRangePage(shop: shop)));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BarcodeScanPage(addProductToShop: shop)));
    }
  }
}
