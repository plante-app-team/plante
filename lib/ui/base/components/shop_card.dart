import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/base.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final ArgCallback<Shop> cancelCallback;
  final ArgCallback<Shop> openShopsCallback;
  const ShopCard(
      {Key? key,
      required this.shop,
      required this.cancelCallback,
      required this.openShopsCallback})
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
                      shop.productsCount <= 0
                          ? context.strings.map_page_no_products_in_shop
                          : context.strings.map_page_there_are_products_in_shop,
                      style: TextStyles.normal)),
              const SizedBox(height: 8),
              SizedBox(
                  width: double.infinity,
                  child: ButtonFilledPlante.withText(
                      context.strings.map_page_open_shop_products,
                      onPressed: _onOpenShop))
            ]),
          ),
        ]));
  }

  void _onCancel() {
    cancelCallback.call(shop);
  }

  void _onOpenShop() {
    openShopsCallback.call(shop);
  }
}
