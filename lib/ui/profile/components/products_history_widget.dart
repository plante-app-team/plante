import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

class ProductsHistoryWidget extends ConsumerStatefulWidget {
  final double topSpacing;
  final ViewedProductsStorage viewedProductsStorage;
  final ProductsObtainer productsObtainer;
  final UserParamsController userParamsController;
  const ProductsHistoryWidget(this.viewedProductsStorage, this.productsObtainer,
      this.userParamsController,
      {Key? key, this.topSpacing = 0})
      : super(key: key);

  @override
  _ProductsHistoryWidgetState createState() => _ProductsHistoryWidgetState();
}

class _ProductsHistoryWidgetState extends ConsumerState<ProductsHistoryWidget>
    with AutomaticKeepAliveClientMixin<ProductsHistoryWidget> {
  late final ViewedProductsStorage viewedProductsStorage =
      widget.viewedProductsStorage;
  late final ProductsObtainer productsObtainer = widget.productsObtainer;
  late final StreamSubscription viewedProductsSubscription;
  late final UserParams user = widget.userParamsController.cachedUserParams!;

  late final _loading = UIValue(false, ref);
  late final _shownAtLeastOnce = UIValue(false, ref);

  late final _products = UIValue<List<Product>>(const [], ref);

  _ProductsHistoryWidgetState();

  // Let's not die when our view pager switches a page to another
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      viewedProductsSubscription = viewedProductsStorage.updates().listen((_) {
        _products.setValue(viewedProductsStorage.getProducts().toList());
      });
      _products.setValue(viewedProductsStorage.getProducts().toList());
    });
  }

  @override
  void dispose() {
    viewedProductsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetectorPlante(
        keyStr: 'ProductsHistoryWidget_visibilityDetector',
        onVisibilityChanged: (visible, _) {
          if (visible) {
            _shownAtLeastOnce.setValue(true);
          }
        },
        child: Stack(children: [
          consumer((ref) {
            if (!_shownAtLeastOnce.watch(ref)) {
              return const _NoWidget();
            }
            final products = _products.watch(ref);
            if (products.isEmpty) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          context
                              .strings.products_history_widget_no_history_hint,
                          style: TextStyles.hint)));
            }
            return ListView(children: _listChildren(products));
          }),
          Positioned.fill(child: consumer((ref) {
            if (!_loading.watch(ref) && _shownAtLeastOnce.watch(ref)) {
              return const SizedBox();
            }
            return Container(
                color: Colors.white.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicatorPlante()));
          })),
        ]));
  }

  List<Widget> _listChildren(List<Product> products) {
    final result = <Widget>[];
    result.add(SizedBox(height: widget.topSpacing));
    result.addAll(products.reversed.map((e) => Padding(
        key: Key('product_${e.barcode}'),
        padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        child: ProductCard(
            product: e,
            beholder: user,
            onTap: () {
              _onProductTap(e);
            }))));
    return result;
  }

  void _onProductTap(Product product) async {
    if (_loading.cachedVal) {
      return;
    }
    _loading.setValue(true);
    try {
      final productUpdatedResult =
          await productsObtainer.getProduct(product.barcode);
      if (productUpdatedResult.isOk) {
        final productUpdated = productUpdatedResult.unwrap();
        if (productUpdated != null) {
          _openProductPage(productUpdated);
        } else {
          Log.w(
              'Product exist in viewed history but not on backends: $product');
          showSnackBar(context.strings.global_something_went_wrong, context);
        }
      } else {
        if (productUpdatedResult.unwrapErr() == ProductsObtainerError.NETWORK) {
          showSnackBar(context.strings.global_network_error, context);
        } else {
          showSnackBar(context.strings.global_something_went_wrong, context);
        }
      }
    } finally {
      _loading.setValue(false);
    }
  }

  void _openProductPage(Product productUpdated) {
    ProductPageWrapper.show(context, productUpdated,
        productUpdatedCallback: viewedProductsStorage.addProduct);
  }
}

// ProductsHistoryWidget uses [VisibilityDetectorPlante], which
// hates `const SizedBox()` because it's always invisible as of itself.
// So we replace SizedBox here with a Container which is sort of visible -
// it will be drawn, but, at the same time, it's transparent.
class _NoWidget extends StatelessWidget {
  const _NoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 11, color: Colors.transparent);
  }
}
