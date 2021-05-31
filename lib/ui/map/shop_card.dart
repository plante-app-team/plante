import 'package:flutter/material.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/l10n/strings.dart';

class ShopCard extends StatelessWidget {
  final Shop shop;
  final VoidCallback onTap;
  const ShopCard({Key? key, required this.shop, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
            overlayColor: MaterialStateProperty.all(ColorsPlante.splashColor),
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name,
                          style: TextStyles.normalBold, maxLines: null),
                      if (shop.type != null)
                        Column(children: [
                          const SizedBox(height: 4),
                          Text(shop.type!.localize(context),
                              style: TextStyles.normal, maxLines: null),
                        ]),
                      const SizedBox(height: 4),
                      Text(
                          '${context.strings.shop_card_products_number}'
                          '${shop.productsCount}',
                          style: TextStyles.hint),
                    ]))));
  }
}
