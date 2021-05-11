import 'package:flutter/material.dart';
import 'package:plante/model/product.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
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
  factory BarcodeScanPageContentState.productFound(
          Product product, ProductUpdatedCallback callback) =
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
  String get id => "nothing_scanned";

  @override
  Widget buildWidget(BuildContext context) {
    return Column(children: [
      Text(context.strings.barcode_scan_page_point_camera_at_barcode,
          textAlign: TextAlign.center, style: TextStyles.normal)
    ]);
  }
}

class BarcodeScanPageContentStateSearchingProduct
    extends BarcodeScanPageContentState {
  final String barcode;
  BarcodeScanPageContentStateSearchingProduct(this.barcode);
  @override
  String get id => "searching_product";

  @override
  Widget buildWidget(BuildContext context) {
    return Column(children: [
      Text("${context.strings.barcode_scan_page_searching_product} $barcode",
          textAlign: TextAlign.center, style: TextStyles.normal)
    ]);
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
  BarcodeScanPageContentStateProductFound(
      this.product, ProductUpdatedCallback callback)
      : super(callback);
  @override
  String get id => "product_found";
  @override
  Product get productWithUnknownState => product;

  @override
  Widget buildWidget(BuildContext context) {
    return Column(children: [
      Text(product.name!,
          textAlign: TextAlign.center, style: TextStyles.headline2),
      SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ButtonFilledPlante.withText(
            context.strings.barcode_scan_page_show_product, onPressed: () {
          tryOpenProductPage(context);
        }),
      )
    ]);
  }
}

class BarcodeScanPageContentStateProductNotFound
    extends BarcodeScanPageContentAbstractStateWithProduct {
  final Product partialProduct;
  BarcodeScanPageContentStateProductNotFound(
      this.partialProduct, ProductUpdatedCallback callback)
      : super(callback);
  @override
  String get id => "not_found_product";
  @override
  Product get productWithUnknownState => partialProduct;

  @override
  Widget buildWidget(BuildContext context) {
    return Column(children: [
      Text(context.strings.barcode_scan_page_product_not_found,
          textAlign: TextAlign.center, style: TextStyles.headline2),
      SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ButtonFilledPlante.withText(
            context.strings.barcode_scan_page_add_product, onPressed: () {
          tryOpenProductPage(context);
        }),
      ),
    ]);
  }
}

class BarcodeScanPageContentStateNoPermission
    extends BarcodeScanPageContentState {
  final VoidCallback requestPermission;

  BarcodeScanPageContentStateNoPermission(this.requestPermission);
  @override
  String get id => "no_permission";

  @override
  Widget buildWidget(BuildContext context) {
    return Column(children: [
      Text(context.strings.barcode_scan_page_camera_permission_reasoning,
          textAlign: TextAlign.center, style: TextStyles.headline2),
      SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ButtonFilledPlante.withText(
            context.strings.global_give_permission,
            onPressed: requestPermission),
      ),
    ]);
  }
}

class BarcodeScanPageContentStateCannotAskPermission
    extends BarcodeScanPageContentState {
  final VoidCallback openAppSettingsCallback;
  BarcodeScanPageContentStateCannotAskPermission(this.openAppSettingsCallback);
  @override
  String get id => "cannot_ask_permission";

  @override
  Widget buildWidget(BuildContext context) {
    return Column(children: [
      Text(
          context
              .strings.barcode_scan_page_camera_permission_reasoning_settings,
          textAlign: TextAlign.center,
          style: TextStyles.headline2),
      SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ButtonFilledPlante.withText(
            context.strings.global_open_app_settings, onPressed: () async {
          openAppSettingsCallback.call();
        }),
      ),
    ]);
  }
}
