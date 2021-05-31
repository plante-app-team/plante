import 'package:flutter/material.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/map/shop_card.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/map/shop_product_range_page.dart';

class ShopsListPage extends StatefulWidget {
  final List<Shop> shops;
  const ShopsListPage({Key? key, required this.shops}) : super(key: key);

  @override
  _ShopsListPageState createState() => _ShopsListPageState();
}

class _ShopsListPageState extends State<ShopsListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(children: [
        const HeaderPlante(),
        Padding(
            padding: const EdgeInsets.only(left: 26),
            child: SizedBox(
                width: double.infinity,
                child: Text(context.strings.shops_list_page_title,
                    style: TextStyles.headline1))),
        Expanded(
            child: ListView(
                children: widget.shops
                    .map((shop) => Padding(
                        key: Key('shop_${shop.osmId}'),
                        padding: const EdgeInsets.only(
                            bottom: 8, left: 16, right: 16),
                        child: ShopCard(
                            shop: shop,
                            onTap: () {
                              _openShopPage(context, shop);
                            })))
                    .toList()))
      ])),
    );
  }

  void _openShopPage(BuildContext context, Shop shop) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ShopProductRangePage(shop: shop)));
  }
}
