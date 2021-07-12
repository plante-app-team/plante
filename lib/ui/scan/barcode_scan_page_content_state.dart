import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:plante/base/permissions_manager.dart';
import 'package:plante/base/result.dart';
import 'package:plante/model/product.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/outside/map/shops_manager_types.dart';
import 'package:plante/ui/base/components/barcode_spinner.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

typedef ProductUpdatedCallback = dynamic Function(Product updatedProduct);
typedef AddProductToShopCallback = Future<Result<None, ShopsManagerError>>
    Function();

abstract class BarcodeScanPageContentState {
  String get id;

  Widget buildWidget(BuildContext context);

  BarcodeScanPageContentState();
  factory BarcodeScanPageContentState.nothingScanned() =
      BarcodeScanPageContentStateNothingScanned;
  factory BarcodeScanPageContentState.searchingProduct(String barcode) =
      BarcodeScanPageContentStateSearchingProduct;
  factory BarcodeScanPageContentState.productFound(
      Product product,
      UserParams beholder,
      ProductUpdatedCallback callback,
      VoidCallback cancelCallback) = BarcodeScanPageContentStateProductFound;
  factory BarcodeScanPageContentState.productNotFound(
      Product product,
      Shop? shopToAddTo,
      ProductUpdatedCallback callback,
      VoidCallback cancelCallback) = BarcodeScanPageContentStateProductNotFound;
  factory BarcodeScanPageContentState.noPermission(VoidCallback callback) =
      BarcodeScanPageContentStateNoPermission;
  factory BarcodeScanPageContentState.cannotAskPermission(
          VoidCallback openAppSettingsCallback,
          PermissionsManager permissionsManager) =
      BarcodeScanPageContentStateCannotAskPermission;
  factory BarcodeScanPageContentState.addProductToShop(
          Product product,
          Shop shop,
          AddProductToShopCallback addProductToShopCallback,
          VoidCallback cancelCallback) =
      BarcodeScanPageContentStateAddProductToShop;
}

class BarcodeScanPageContentStateNothingScanned
    extends BarcodeScanPageContentState {
  @override
  String get id => 'nothing_scanned';

  @override
  Widget buildWidget(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class BarcodeScanPageContentStateSearchingProduct
    extends BarcodeScanPageContentState {
  final String barcode;
  BarcodeScanPageContentStateSearchingProduct(this.barcode);
  @override
  String get id => 'searching_product';

  @override
  Widget buildWidget(BuildContext context) {
    return _CardContainer(
        key: Key(id),
        child:
            const SizedBox(height: 77, child: Center(child: BarcodeSpinner())));
  }
}

abstract class BarcodeScanPageContentAbstractStateWithProduct
    extends BarcodeScanPageContentState {
  final ProductUpdatedCallback productUpdatedCallback;

  BarcodeScanPageContentAbstractStateWithProduct(this.productUpdatedCallback);

  Product get productWithUnknownState;

  void tryOpenProductPage(BuildContext context, [Shop? shopToAddTo]) {
    if (shopToAddTo != null) {
      Navigator.of(context).pop();
    }
    ProductPageWrapper.show(context, productWithUnknownState,
        shopToAddTo: shopToAddTo,
        productUpdatedCallback: productUpdatedCallback);
  }
}

class BarcodeScanPageContentStateProductFound
    extends BarcodeScanPageContentAbstractStateWithProduct {
  final Product product;
  final UserParams beholder;
  final VoidCallback cancelCallback;
  BarcodeScanPageContentStateProductFound(this.product, this.beholder,
      ProductUpdatedCallback callback, this.cancelCallback)
      : super(callback);
  @override
  String get id => 'product_found';
  @override
  Product get productWithUnknownState => product;

  @override
  Widget buildWidget(BuildContext context) {
    return _CardContainer(
        cancelCallback: cancelCallback,
        child: ProductCard(
            product: product,
            beholder: beholder,
            onTap: () {
              tryOpenProductPage(context);
            }));
  }
}

class BarcodeScanPageContentStateProductNotFound
    extends BarcodeScanPageContentAbstractStateWithProduct {
  final Product partialProduct;
  final Shop? shopToAddTo;
  final VoidCallback cancelCallback;
  BarcodeScanPageContentStateProductNotFound(this.partialProduct,
      this.shopToAddTo, ProductUpdatedCallback callback, this.cancelCallback)
      : super(callback);
  @override
  String get id => 'not_found_product';
  @override
  Product get productWithUnknownState => partialProduct;

  @override
  Widget buildWidget(BuildContext context) {
    return _CardContainer(
      key: Key(id),
      cancelCallback: cancelCallback,
      child: Padding(
          padding:
              const EdgeInsets.only(left: 10, right: 10, top: 12, bottom: 16),
          child: Column(children: [
            Text(context.strings.barcode_scan_page_product_not_found,
                textAlign: TextAlign.center, style: TextStyles.headline4),
            const SizedBox(height: 12),
            Text(
                context.strings.barcode_scan_page_product_not_found_descr
                    .replaceAll('<PRODUCT>', partialProduct.barcode),
                textAlign: TextAlign.center,
                style: TextStyles.normal),
            const SizedBox(height: 12),
            ButtonFilledPlante.withText(
                context.strings.barcode_scan_page_add_product, onPressed: () {
              tryOpenProductPage(context, shopToAddTo);
            }),
          ])),
    );
  }
}

class BarcodeScanPageContentStateNoPermission
    extends BarcodeScanPageContentState {
  final VoidCallback requestPermission;

  BarcodeScanPageContentStateNoPermission(this.requestPermission);
  @override
  String get id => 'no_permission';

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
        key: Key(id),
        color: const Color(0xfff5f7fa),
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ButtonFilledPlante.withText(
              context.strings.barcode_scan_page_scan_product,
              onPressed: requestPermission),
        ]));
  }
}

class BarcodeScanPageContentStateCannotAskPermission
    extends BarcodeScanPageContentState {
  final VoidCallback openAppSettingsCallback;
  final PermissionsManager permissionsManager;
  BarcodeScanPageContentStateCannotAskPermission(
      this.openAppSettingsCallback, this.permissionsManager);
  @override
  String get id => 'cannot_ask_permission';

  @override
  Widget buildWidget(BuildContext context) {
    return Container(
        key: Key(id),
        color: const Color(0xfff5f7fa),
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ButtonFilledPlante.withText(
              context.strings.barcode_scan_page_scan_product,
              onPressed: () async {
            await showSystemDialog(
                context,
                context.strings
                    .barcode_scan_page_camera_permission_reasoning_settings,
                context
                    .strings.barcode_scan_page_camera_permission_go_to_settings,
                openAppSettingsCallback,
                title:
                    context.strings.barcode_scan_page_camera_permission_title,
                cancelWhat: context.strings
                    .barcode_scan_page_camera_permission_cancel_settings);
          }),
        ]));
  }
}

class BarcodeScanPageContentStateAddProductToShop
    extends BarcodeScanPageContentState {
  final Product product;
  final Shop shop;
  final AddProductToShopCallback addProductToShopCallback;
  final VoidCallback cancelCallback;

  BarcodeScanPageContentStateAddProductToShop(this.product, this.shop,
      this.addProductToShopCallback, this.cancelCallback);

  @override
  String get id => 'add_product_to_shop';

  @override
  Widget buildWidget(BuildContext context) {
    final title = context.strings.barcode_scan_page_is_product_sold_q
        .replaceAll('<PRODUCT>', product.name ?? '')
        .replaceAll('<SHOP>', shop.name);
    return Container(
        margin: MediaQuery.of(context).viewInsets,
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
            color: Colors.white,
            child: Padding(
                padding: const EdgeInsets.only(
                    left: 24, top: 24, right: 24, bottom: 16),
                child: Wrap(children: [
                  Column(children: [
                    Text(title, style: TextStyles.headline1),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: double.infinity,
                        child: Row(children: [
                          Expanded(
                              child: ButtonOutlinedPlante.withText(
                            context.strings.global_no,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )),
                          const SizedBox(width: 16),
                          Expanded(
                              child: ButtonFilledPlante.withText(
                            context.strings.global_yes,
                            onPressed: () {
                              _tryAddProductToShop(context);
                            },
                          )),
                        ]))
                  ])
                ]))));
  }

  void _tryAddProductToShop(BuildContext context) async {
    final result = await addProductToShopCallback.call();
    if (result.isErr) {
      if (result.unwrapErr() == ShopsManagerError.NETWORK_ERROR) {
        showSnackBar(context.strings.global_network_error, context);
      } else {
        showSnackBar(context.strings.global_something_went_wrong, context);
      }
    } else {
      showSnackBar(context.strings.global_done_thanks, context);
      Navigator.of(context).pop();
    }
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? cancelCallback;
  const _CardContainer({Key? key, required this.child, this.cancelCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(children: [
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Wrap(children: [
                    Stack(children: [
                      AnimatedContainer(
                        duration: DURATION_DEFAULT,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: child,
                      ),
                      if (cancelCallback != null)
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            key: const Key('card_cancel_btn'),
                            borderRadius: BorderRadius.circular(24),
                            onTap: cancelCallback,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: SvgPicture.asset(
                                'assets/cancel_circle.svg',
                              ),
                            ),
                          ),
                        )
                    ])
                  ])))
        ]));
  }
}
