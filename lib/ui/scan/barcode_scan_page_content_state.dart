import 'package:flutter/material.dart';
import 'package:plante/model/product.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

typedef ProductUpdatedCallback = dynamic Function(Product updatedProduct);

abstract class BarcodeScanPageContentState {
  String get id;

  Widget buildWidget(BuildContext context);

  BarcodeScanPageContentState();
  factory BarcodeScanPageContentState.nothingScanned() =
      BarcodeScanPageContentStateNothingScanned;
  factory BarcodeScanPageContentState.searchingProduct(String barcode) =
      BarcodeScanPageContentStateSearchingProduct;
  factory BarcodeScanPageContentState.productFound(Product product,
          UserParams beholder, ProductUpdatedCallback callback) =
      BarcodeScanPageContentStateProductFound;
  factory BarcodeScanPageContentState.productNotFound(
          Product product, ProductUpdatedCallback callback) =
      BarcodeScanPageContentStateProductNotFound;
  factory BarcodeScanPageContentState.noPermission(VoidCallback callback) =
      BarcodeScanPageContentStateNoPermission;
  factory BarcodeScanPageContentState.cannotAskPermission(
          VoidCallback openAppSettingsCallback) =
      BarcodeScanPageContentStateCannotAskPermission;
}

class BarcodeScanPageContentStateNothingScanned
    extends BarcodeScanPageContentState {
  @override
  String get id => 'nothing_scanned';

  @override
  Widget buildWidget(BuildContext context) {
    return SizedBox.shrink();
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
    return Padding(
        key: Key(id),
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Column(children: [
          Text(
              '${context.strings.barcode_scan_page_searching_product} $barcode',
              textAlign: TextAlign.center,
              style: TextStyles.normal)
        ]));
  }
}

abstract class BarcodeScanPageContentAbstractStateWithProduct
    extends BarcodeScanPageContentState {
  final ProductUpdatedCallback productUpdatedCallback;

  BarcodeScanPageContentAbstractStateWithProduct(this.productUpdatedCallback);

  Product get productWithUnknownState;

  void tryOpenProductPage(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPageWrapper(productWithUnknownState,
                productUpdatedCallback: productUpdatedCallback)));
  }
}

class BarcodeScanPageContentStateProductFound
    extends BarcodeScanPageContentAbstractStateWithProduct {
  final Product product;
  final UserParams beholder;
  BarcodeScanPageContentStateProductFound(
      this.product, this.beholder, ProductUpdatedCallback callback)
      : super(callback);
  @override
  String get id => 'product_found';
  @override
  Product get productWithUnknownState => product;

  @override
  Widget buildWidget(BuildContext context) {
    return Padding(
        key: Key(id),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(children: [
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Wrap(children: [
                    ProductCard(
                        product: product,
                        beholder: beholder,
                        onTap: () {
                          tryOpenProductPage(context);
                        })
                  ]))),
        ]));
  }
}

class BarcodeScanPageContentStateProductNotFound
    extends BarcodeScanPageContentAbstractStateWithProduct {
  final Product partialProduct;
  BarcodeScanPageContentStateProductNotFound(
      this.partialProduct, ProductUpdatedCallback callback)
      : super(callback);
  @override
  String get id => 'not_found_product';
  @override
  Product get productWithUnknownState => partialProduct;

  @override
  Widget buildWidget(BuildContext context) {
    return Padding(
        key: Key(id),
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Column(children: [
          Text(context.strings.barcode_scan_page_product_not_found,
              textAlign: TextAlign.center, style: TextStyles.headline1),
          const SizedBox(height: 16),
          Text(
              context.strings.barcode_scan_page_product_not_found_descr
                  .replaceAll('<PRODUCT>', partialProduct.barcode),
              textAlign: TextAlign.center,
              style: TextStyles.normal),
          const SizedBox(height: 18),
          ButtonFilledPlante.withText(
              context.strings.barcode_scan_page_add_product, onPressed: () {
            tryOpenProductPage(context);
          }),
        ]));
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
    return Padding(
        key: Key(id),
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Column(children: [
          Text(context.strings.barcode_scan_page_camera_permission_reasoning,
              textAlign: TextAlign.center, style: TextStyles.headline3),
          const SizedBox(height: 18),
          ButtonFilledPlante.withText(context.strings.global_give_permission,
              onPressed: requestPermission),
        ]));
  }
}

class BarcodeScanPageContentStateCannotAskPermission
    extends BarcodeScanPageContentState {
  final VoidCallback openAppSettingsCallback;
  BarcodeScanPageContentStateCannotAskPermission(this.openAppSettingsCallback);
  @override
  String get id => 'cannot_ask_permission';

  @override
  Widget buildWidget(BuildContext context) {
    return Padding(
        key: Key(id),
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Column(children: [
          Text(
              context.strings
                  .barcode_scan_page_camera_permission_reasoning_settings,
              textAlign: TextAlign.center,
              style: TextStyles.headline3),
          const SizedBox(height: 18),
          ButtonFilledPlante.withText(context.strings.global_open_app_settings,
              onPressed: () async {
            openAppSettingsCallback.call();
          }),
        ]));
  }
}
