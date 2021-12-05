import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/logging/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/model/viewed_products_storage.dart';
import 'package:plante/outside/products/products_obtainer.dart';
import 'package:plante/ui/base/colors_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/linear_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/page_state_plante.dart';
import 'package:plante/ui/base/snack_bar_utils.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

class ViewedProductsHistoryPage extends PagePlante {
  const ViewedProductsHistoryPage({Key? key}) : super(key: key);

  @override
  _ViewedProductsHistoryPageState createState() =>
      _ViewedProductsHistoryPageState();
}

class _ViewedProductsHistoryPageState
    extends PageStatePlante<ViewedProductsHistoryPage> {
  final ViewedProductsStorage viewedProductsStorage;
  late final StreamSubscription viewedProductsSubscription;
  final UserParams user;
  final ProductsObtainer productsObtainer;

  bool loading = false;

  List<Product> products = [];

  _ViewedProductsHistoryPageState()
      : viewedProductsStorage = GetIt.I.get<ViewedProductsStorage>(),
        user = GetIt.I.get<UserParamsController>().cachedUserParams!,
        productsObtainer = GetIt.I.get<ProductsObtainer>(),
        super('ViewedProductsHistoryPage');

  @override
  void initState() {
    super.initState();
    viewedProductsSubscription = viewedProductsStorage.updates().listen((_) {
      setState(() {
        products = viewedProductsStorage.getProducts();
      });
    });
    products = viewedProductsStorage.getProducts();
  }

  @override
  void dispose() {
    viewedProductsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorsPlante.lightGrey,
        body: SafeArea(
            child: Column(children: [
          Stack(children: [
            const HeaderPlante(),
            AnimatedSwitcher(
                duration: DURATION_DEFAULT,
                child: loading
                    ? const LinearProgressIndicatorPlante()
                    : const SizedBox.shrink()),
          ]),
          const SizedBox(height: 24),
          Expanded(
              child: Column(children: [
            Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: SizedBox(
                    width: double.infinity,
                    child: Text(
                        context.strings.viewed_products_history_page_title,
                        style: TextStyles.headline1))),
            const SizedBox(height: 16),
            Expanded(
                child: ListView(
                    children: products.reversed
                        .map((e) => Padding(
                            key: Key('product_${e.barcode}'),
                            padding: const EdgeInsets.only(
                                bottom: 8, left: 16, right: 16),
                            child: ProductCard(
                                product: e,
                                beholder: user,
                                onTap: () {
                                  onProductTap(e);
                                })))
                        .toList()))
          ]))
        ])));
  }

  void onProductTap(Product product) async {
    if (loading) {
      return;
    }
    setState(() {
      loading = true;
    });
    try {
      final productUpdatedResult =
          await productsObtainer.getProduct(product.barcode);
      if (productUpdatedResult.isOk) {
        final productUpdated = productUpdatedResult.unwrap();
        if (productUpdated != null) {
          openProductPage(productUpdated);
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
      setState(() {
        loading = false;
      });
    }
  }

  void openProductPage(Product productUpdated) {
    ProductPageWrapper.show(context, productUpdated,
        productUpdatedCallback: viewedProductsStorage.addProduct);
  }
}
