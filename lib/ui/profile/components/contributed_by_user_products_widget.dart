import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plante/base/general_error.dart';
import 'package:plante/base/result.dart';
import 'package:plante/contributions/user_contribution_type.dart';
import 'package:plante/contributions/user_contributions_manager.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/products/products_obtainer.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/circular_progress_indicator_plante.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/components/visibility_detector_plante.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/base/ui_value.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';

class ContributedByUserProductsWidget extends ConsumerStatefulWidget {
  final double topSpacing;
  final UserContributionsManager contributionsManager;
  final ProductsObtainer productsObtainer;
  final UserParamsController userParamsController;
  const ContributedByUserProductsWidget(this.contributionsManager,
      this.productsObtainer, this.userParamsController,
      {Key? key, this.topSpacing = 0})
      : super(key: key);

  @override
  _ContributedByUserProductsWidgetState createState() =>
      _ContributedByUserProductsWidgetState();
}

class _ContributedByUserProductsWidgetState
    extends ConsumerState<ContributedByUserProductsWidget>
    with AutomaticKeepAliveClientMixin<ContributedByUserProductsWidget> {
  late final UserContributionsManager contributionsManager =
      widget.contributionsManager;
  late final ProductsObtainer productsObtainer = widget.productsObtainer;
  late final UserParams user = widget.userParamsController.cachedUserParams!;

  late final _products =
      UIValue<Result<List<Product>, GeneralError>?>(null, ref);

  // Let's not die when our view pager switches a page to another
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetectorPlante(
      keyStr: 'UserProductsWidget_visibilityDetector',
      onVisibilityChanged: (visible, _) {
        if (visible) {
          _loadProducts();
        }
      },
      child: consumer((ref) {
        final productsRes = _products.watch(ref);
        if (productsRes != null) {
          if (productsRes.isOk) {
            final products = productsRes.unwrap();
            if (products.isNotEmpty) {
              return ListView(children: _listChildren(products));
            } else {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          context.strings
                              .contributed_by_user_products_widget_no_products_hint,
                          style: TextStyles.hint)));
            }
          } else {
            final String errorText;
            if (productsRes.unwrapErr() == GeneralError.NETWORK) {
              errorText = context.strings.global_network_error;
            } else {
              errorText = context.strings.global_something_went_wrong;
            }
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(errorText, style: TextStyles.normal),
                          const SizedBox(height: 8),
                          ButtonFilledPlante.withText(
                              context.strings.global_try_again,
                              onPressed: _reloadProducts)
                        ])));
          }
        } else {
          return const Center(child: CircularProgressIndicatorPlante());
        }
      }),
    );
  }

  void _loadProducts() async {
    final contributionsRes = await contributionsManager.getContributions();
    if (contributionsRes.isErr) {
      _products.setValue(Err(contributionsRes.unwrapErr().toGeneral()));
      return;
    }
    const contributionsTypes = {
      UserContributionType.PRODUCT_EDITED,
      UserContributionType.PRODUCT_ADDED_TO_SHOP,
      UserContributionType.LEGACY_PRODUCT_EDITED,
    };
    final contributions = contributionsRes
        .unwrap()
        .where((e) => contributionsTypes.contains(e.type))
        .toList()
      ..sort((lhs, rhs) => rhs.timeSecsUtc - lhs.timeSecsUtc);
    final barcodes = contributions
        .map((e) => e.barcode)
        .where((e) => e != null)
        .cast<String>()
        .toList()
      ..removeDuplicates();

    final productsRes = await productsObtainer.getProducts(barcodes);
    if (productsRes.isOk) {
      _products.setValue(Ok(productsRes.unwrap()));
    } else {
      _products.setValue(Err(productsRes.unwrapErr().toGeneral()));
    }
  }

  void _reloadProducts() {
    _products.setValue(null);
    _loadProducts();
  }

  List<Widget> _listChildren(List<Product> products) {
    final result = <Widget>[];
    result.add(SizedBox(height: widget.topSpacing));
    result.addAll(products.map((e) => Padding(
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
    ProductPageWrapper.show(context, product);
  }
}

extension<T> on List<T> {
  void removeDuplicates() {
    final set = <T>{};
    retainWhere(set.add);
  }
}
