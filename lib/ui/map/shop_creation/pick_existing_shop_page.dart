import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/base.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/outside/map/address_obtainer.dart';
import 'package:plante/outside/map/ui_list_addresses_obtainer.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/address_widget.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/fab_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/text_styles.dart';

class PickExistingShopResult {
  PickExistingShopResult._();
  factory PickExistingShopResult.newShopWanted() =
      PickExistingShopResultNewShopWanted;
  factory PickExistingShopResult.shopPicked(Shop shop) =
      PickExistingShopResultShopPicked;
}

class PickExistingShopResultNewShopWanted extends PickExistingShopResult {
  PickExistingShopResultNewShopWanted() : super._();
}

class PickExistingShopResultShopPicked extends PickExistingShopResult {
  final Shop shop;
  PickExistingShopResultShopPicked(this.shop) : super._();
}

class PickExistingShopPage extends PagePlante {
  final List<Shop> shops;
  const PickExistingShopPage(this.shops, {Key? key}) : super(key: key);

  @override
  _PickExistingShopPageState createState() => _PickExistingShopPageState();
}

class _PickExistingShopPageState extends PageStatePlante<PickExistingShopPage> {
  final _addressObtainer = GetIt.I.get<AddressObtainer>();
  late final _shopsAddresses = UiListAddressesObtainer<Shop>(_addressObtainer);

  final _visibleShops = <Shop>{};

  _PickExistingShopPageState() : super('PickExistingShopPage');

  @override
  Widget buildPage(BuildContext context) {
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const HeaderPlante(
        rightAction: FabPlante.closeBtnPopOnClick(key: Key('cancel')),
      ),
      _Padding24(Text(context.strings.pick_existing_shop_page_title,
          style: TextStyles.normalBold)),
      const SizedBox(height: 18),
      Flexible(child: ListView(shrinkWrap: true, children: _shopsWidgets())),
      const SizedBox(height: 32),
      _Padding24(Text(
          context.strings.pick_existing_shop_page_is_new_store_not_listed_q,
          style: TextStyles.normalBold)),
      const SizedBox(height: 14),
      SizedBox(
          width: double.infinity,
          child: _Padding24(ButtonFilledPlante.withText(
              context.strings.pick_existing_shop_page_create_shop_button,
              onPressed: () {
            Navigator.of(context).pop(PickExistingShopResult.newShopWanted());
          }))),
      const SizedBox(height: 32),
    ]);
    return Scaffold(
        backgroundColor: Colors.white, body: SafeArea(child: content));
  }

  List<Widget> _shopsWidgets() {
    return widget.shops
        .map((shop) => VisibilityDetectorPlante(
            keyStr: 'shop_${shop.osmUID}',
            onVisibilityChanged: (visible, _) {
              if (visible) {
                _visibleShops.add(shop);
              } else {
                _visibleShops.remove(shop);
              }
              _shopsAddresses.onDisplayedEntitiesChanged(
                  displayedEntities: _visibleShops,
                  allEntitiesOrdered: widget.shops);
            },
            child: _ShopItem(
                shop: shop,
                address: _shopsAddresses.requestAddressOf(shop),
                onTap: (shop) {
                  Navigator.of(context)
                      .pop(PickExistingShopResult.shopPicked(shop));
                })))
        .toList();
  }
}

class _Padding24 extends StatelessWidget {
  final Widget child;
  const _Padding24(this.child, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24), child: child);
  }
}

class _ShopItem extends StatelessWidget {
  final Shop shop;
  final FutureShortAddress address;
  final ArgCallback<Shop> onTap;
  const _ShopItem(
      {Key? key,
      required this.shop,
      required this.address,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _Padding24(Column(children: [
      Container(
          decoration: const BoxDecoration(
            color: ColorsPlante.lightGrey,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  onTap: () {
                    onTap.call(shop);
                  },
                  // splashColor: ColorsPlante.splashColor,
                  child: Padding(
                      padding: const EdgeInsets.only(
                          left: 6, right: 6, top: 12, bottom: 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop.name, style: TextStyles.headline3),
                            AddressWidget.forShop(shop, address),
                          ]))))),
      const SizedBox(height: 6),
    ]));
  }
}
