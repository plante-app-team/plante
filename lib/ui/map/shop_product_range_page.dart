import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/product.dart';
import 'package:plante/model/shop.dart';
import 'package:plante/model/shop_product_range.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/outside/backend/backend.dart';
import 'package:plante/outside/backend/backend_error.dart';
import 'package:plante/outside/map/shops_manager.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/ui/base/components/animated_cross_fade_plante.dart';
import 'package:plante/ui/base/components/button_filled_plante.dart';
import 'package:plante/ui/base/components/button_outlined_plante.dart';
import 'package:plante/ui/base/components/dialog_plante.dart';
import 'package:plante/ui/base/components/header_plante.dart';
import 'package:plante/ui/base/components/product_card.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/base/ui_utils.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ShopProductRangePage extends StatefulWidget {
  final Shop shop;
  const ShopProductRangePage({Key? key, required this.shop}) : super(key: key);

  @override
  _ShopProductRangePageState createState() => _ShopProductRangePageState();
}

class _ShopProductRangePageState extends State<ShopProductRangePage> {
  final ShopsManager _shopsManager;
  final UserParamsController _userParamsController;
  final Backend _backend;
  bool _loading = false;
  bool _performingBackendAction = false;
  ShopProductRange? _shopProductRange;
  ShopsManagerError? _shopProductRangeLoadingError;

  _ShopProductRangePageState()
      : _shopsManager = GetIt.I.get<ShopsManager>(),
        _userParamsController = GetIt.I.get<UserParamsController>(),
        _backend = GetIt.I.get<Backend>();

  @override
  void initState() {
    super.initState();
    _load();
    initializeDateFormatting();
  }

  @override
  void didUpdateWidget(ShopProductRangePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  void _load() async {
    setState(() {
      _loading = true;
      _shopProductRangeLoadingError = null;
    });
    try {
      final loadResult = await _shopsManager.fetchShopProductRange(widget.shop);
      if (loadResult.isOk) {
        _shopProductRange = loadResult.unwrap();
      } else {
        _shopProductRangeLoadingError = loadResult.unwrapErr();
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_shopProductRangeLoadingError != null) {
      if (_shopProductRangeLoadingError == ShopsManagerError.NETWORK_ERROR) {
        content = Center(
            child: Column(children: [
          Text(context.strings.global_network_error, style: TextStyles.normal),
          ButtonFilledPlante.withText(context.strings.global_try_again,
              onPressed: _load)
        ]));
      } else {
        content = Center(
            child: Text(context.strings.global_something_went_wrong,
                style: TextStyles.normal));
      }
    } else if (_shopProductRange!.products.isEmpty) {
      content = Center(
          child: Text(
              context.strings.shop_product_range_page_this_shop_has_no_product,
              style: TextStyles.normal));
    } else {
      final products = _shopProductRange!.products;
      final user = _userParamsController.cachedUserParams!;
      content = ListView(
          children: products.map((e) {
        final date = DateTime.fromMillisecondsSinceEpoch(
            _shopProductRange!.lastSeenSecs(e) * 1000);
        final dateStr = DateFormat.yMMMMd(context.langCode).format(date);

        return Padding(
            key: Key('product_${e.barcode}'),
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ProductCard(
                  product: e,
                  beholder: user,
                  onTap: () {
                    _openProductPage(e);
                  }),
              Text(
                  '${context.strings.shop_product_range_page_product_last_seen_here}$dateStr'),
              Text(context
                  .strings.shop_product_range_page_have_you_seen_product_here),
              Row(children: [
                Expanded(
                    child: ButtonOutlinedPlante.withText(
                        context.strings.global_no, onPressed: () {
                  _onProductPresenceVote(e, false);
                })),
                Expanded(
                    child: ButtonOutlinedPlante.withText(
                        context.strings.global_yes, onPressed: () {
                  _onProductPresenceVote(e, true);
                }))
              ])
            ]));
      }).toList());
    }
    return Scaffold(
      body: SafeArea(
          child: Stack(children: [
        Column(children: [
          const HeaderPlante(),
          Padding(
              padding: const EdgeInsets.only(left: 26),
              child: SizedBox(
                  width: double.infinity,
                  child: Text(widget.shop.name, style: TextStyles.headline1))),
          Expanded(child: content)
        ]),
        Positioned.fill(
            child: AnimatedCrossFadePlante(
          crossFadeState: _performingBackendAction
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: const Color(0x70FFFFFF),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ))
      ])),
    );
  }

  void _openProductPage(Product product) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProductPageWrapper(product,
                productUpdatedCallback: _onProductUpdate)));
  }

  void _onProductUpdate(Product updatedProduct) {
    if (_shopProductRange == null) {
      return;
    }
    final products = _shopProductRange!.products.toList();
    final productToUpdate = products
        .indexWhere((product) => product.barcode == updatedProduct.barcode);
    if (productToUpdate == -1) {
      Log.e(
          'Updated product is not found. Product: $updatedProduct, all products: $products');
      return;
    }
    products[productToUpdate] = updatedProduct;
    _shopProductRange =
        _shopProductRange!.rebuild((e) => e.products.replace(products));
  }

  void _onProductPresenceVote(Product product, bool positive) async {
    final title = positive
        ? context.strings.shop_product_range_page_you_sure_positive_vote
        : context.strings.shop_product_range_page_you_sure_negative_vote;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return DialogPlante(
            content: Text(title, style: TextStyles.headline1),
            actions: Row(children: [
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
                  _performProductPresenceVote(product, positive);
                  Navigator.of(context).pop();
                },
              )),
            ]));
      },
    );
  }

  void _performProductPresenceVote(Product product, bool positive) async {
    setState(() {
      _performingBackendAction = true;
    });
    try {
      final result = await _backend.productPresenceVote(
          product.barcode, widget.shop.osmId, positive);
      if (result.isOk) {
        showSnackBar(context.strings.global_done_thanks, context);
        setState(() {
          // TODO(https://trello.com/c/dCDHecZS/): test
          _shopProductRange = _shopProductRange!.rebuild((e) =>
              e.productsLastSeenSecsUtc[product.barcode] =
                  DateTime.now().secondsSinceEpoch);
        });
      } else {
        if (result.unwrapErr().errorKind == BackendErrorKind.NETWORK_ERROR) {
          showSnackBar(context.strings.global_network_error, context);
        } else {
          showSnackBar(context.strings.global_something_went_wrong, context);
        }
      }
    } finally {
      setState(() {
        _performingBackendAction = false;
      });
    }
  }
}

extension _DateTimeExt on DateTime {
  int get secondsSinceEpoch => (millisecondsSinceEpoch / 1000).round();
}
